// lib/screens/admin_notification_screen.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:vocachat/services/admin_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

class AdminNotificationScreen extends StatefulWidget {
  const AdminNotificationScreen({super.key});

  @override
  State<AdminNotificationScreen> createState() => _AdminNotificationScreenState();
}

class _AdminNotificationScreenState extends State<AdminNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _targetUidCtrl = TextEditingController(); // Cloud Function için UID gönderimi devam ediyor
  // Yeni: Kullanıcı arama kontrolleri
  final TextEditingController _userSearchCtrl = TextEditingController();
  Timer? _userSearchDebounce;
  List<Map<String, dynamic>> _userSearchResults = [];
  bool _userSearchLoading = false;
  Map<String, dynamic>? _selectedUser; // {uid, name}
  final AdminService _adminService = AdminService();
  String _segment = 'all';
  bool _sending = false;
  String? _role;
  String? _resultMsg;
  int? _audienceCount;
  bool _audienceLoading = false;
  Timer? _audienceDebounce;
  String? _currentUid;
  String? _targetRoute; // selected in-app route

  @override
  void initState() {
    super.initState();
    _loadRole();
    _scheduleAudienceRecalc();
    _titleCtrl.addListener(_triggerPreviewUpdate);
    _bodyCtrl.addListener(_triggerPreviewUpdate);
    _targetUidCtrl.addListener(() { if (_segment=='user') _scheduleAudienceRecalc(); });
    _userSearchCtrl.addListener(() { if (_segment=='user') _scheduleUserSearch(); });
  }

  void _triggerPreviewUpdate() {
    // sadece setState tetiklemek yeterli
    if (mounted) setState(() {});
  }

  void _scheduleAudienceRecalc() {
    _audienceDebounce?.cancel();
    _audienceDebounce = Timer(const Duration(milliseconds: 450), _calcAudienceCount);
  }

  Future<void> _calcAudienceCount() async {
    if (_role != 'admin') return;
    setState(() { _audienceLoading = true; });
    try {
      final fs = FirebaseFirestore.instance;
      AggregateQuery q;
      if (_segment == 'premium') {
        q = fs.collection('users')
              .where('status', isEqualTo: 'active')
              .where('isPremium', isEqualTo: true)
              .count();
      } else if (_segment == 'non_premium') {
        q = fs.collection('users')
              .where('status', isEqualTo: 'active')
              .where('isPremium', isEqualTo: false)
              .count();
      } else if (_segment == 'user') {
        // Tek kullanıcı seçimi kullanıcı adı araması üzerinden yapılıyor
        setState(()=> _audienceCount = (_selectedUser != null ? 1 : 0));
        return;
      } else {
        q = fs.collection('users')
              .where('status', isEqualTo: 'active')
              .count();
      }
      final snap = await q.get();
      setState(()=> _audienceCount = snap.count);
    } catch (_) {
      if (mounted) setState(()=> _audienceCount = null);
    } finally {
      if (mounted) setState(()=> _audienceLoading = false);
    }
  }

  Future<void> _loadRole() async {
    final r = await _adminService.getCurrentUserRole();
    final authUid = FirebaseAuth.instance.currentUser?.uid;
    if (!mounted) return;
    setState(() { _role = r; _currentUid = authUid; });
  }

  void _openAudienceSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        String tempSegment = _segment;
        return StatefulBuilder(builder: (ctx,setSt){
          void apply(){
            setState(() {
              _segment = tempSegment;
              if (_segment != 'user') {
                _selectedUser = null;
                _targetUidCtrl.clear();
              }
            });
            Navigator.pop(ctx);
            _scheduleAudienceRecalc();
          }
          Widget segTile(String key, String label, IconData icon){
            final selected = tempSegment == key;
            return ListTile(
              leading: Icon(icon, color: selected ? Theme.of(context).colorScheme.primary : null),
              title: Text(label),
              trailing: selected ? const Icon(Icons.check_circle, color: Colors.green) : null,
              onTap: () { setSt(()=> tempSegment = key); },
            );
          }
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(height:4,width:40,decoration: BoxDecoration(color: Colors.grey.shade400,borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 12),
                Text('Select Audience', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        segTile('all','All Active Users', Icons.group),
                        segTile('premium','Premium Users', Icons.star_rate_rounded),
                        segTile('non_premium','Standard Users', Icons.person_outline),
                        segTile('user','Single User (search)', Icons.person_pin_circle_outlined),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16,4,16,16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: apply,
                            icon: const Icon(Icons.done),
                            label: const Text('Apply'),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          );
        });
      }
    );
  }

  // Kullanıcı arama planı: girilen terim >= 2 karakter -> birden fazla field dene
  void _scheduleUserSearch() {
    _userSearchDebounce?.cancel();
    _userSearchDebounce = Timer(const Duration(milliseconds: 450), _performUserSearch);
  }

  Future<void> _performUserSearch() async {
    final term = _userSearchCtrl.text.trim();
    if (_segment != 'user') return;
    if (term.length < 2) {
      if (mounted) setState(() { _userSearchResults = []; });
      return;
    }
    setState(() { _userSearchLoading = true; });
    final fs = FirebaseFirestore.instance;
    final lower = term.toLowerCase();
    final attempts = ['usernameLower','displayNameLower','username','displayName'];
    List<QueryDocumentSnapshot<Map<String,dynamic>>> docs = [];
    for (final field in attempts) {
      try {
        final q = fs.collection('users')
          .orderBy(field)
          .startAt([lower])
          .endAt([lower + '\uf8ff'])
          .limit(10);
        final snap = await q.get();
        docs = snap.docs;
        if (docs.isNotEmpty) break; // sonuç bulduysak dur
      } catch (_) {
        continue; // bu field yoksa diğerine geç
      }
    }
    final results = docs.map((d){
      final data = d.data();
      final name = data['username'] ?? data['displayName'] ?? data['displayNameLower'] ?? data['usernameLower'] ?? d.id;
      final status = data['status'];
      if (status != null && status != 'active') return null; // pasifleri çıkar
      return {'uid': d.id, 'name': name};
    }).whereType<Map<String,dynamic>>().toList();
    if (mounted) setState(() { _userSearchResults = results; _userSearchLoading = false; });
  }

  void _selectUser(Map<String,dynamic> user) {
    setState(() {
      _selectedUser = user;
      _targetUidCtrl.text = user['uid'];
      _userSearchResults = [];
      _userSearchCtrl.text = user['name'];
    });
    _scheduleAudienceRecalc();
  }

  void _clearSelectedUser() {
    setState(() {
      _selectedUser = null;
      _targetUidCtrl.clear();
    });
    _scheduleAudienceRecalc();
  }

  Widget _buildUserSearchArea() {
    if (_segment != 'user') return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        TextField(
          controller: _userSearchCtrl,
            decoration: InputDecoration(
            labelText: 'Search username',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _userSearchCtrl.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _userSearchCtrl.clear(); _scheduleUserSearch(); }) : null,
            border: const OutlineInputBorder(),
          ),
        ),
        if (_userSearchLoading) const LinearProgressIndicator(minHeight: 2),
        if (_selectedUser != null) Padding(
          padding: const EdgeInsets.only(top:8),
          child: Wrap(
            children: [
              Chip(
                avatar: const CircleAvatar(child: Icon(Icons.person,size:16)),
                label: Text(_selectedUser!['name']),
                deleteIcon: const Icon(Icons.close),
                onDeleted: _clearSelectedUser,
              ),
            ],
          ),
        ),
        if (_userSearchResults.isNotEmpty && _selectedUser == null)
          Card(
            margin: const EdgeInsets.only(top:8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              itemCount: _userSearchResults.length,
              itemBuilder: (c,i){
                final u = _userSearchResults[i];
                return ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(u['name'], maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(u['uid'], style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                  onTap: () => _selectUser(u),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildAudienceInfo() {
    if (_segment == 'user') {
      if (_selectedUser == null) return const SizedBox();
      return Padding(
        padding: const EdgeInsets.only(top:4),
        child: Text('Target user: ${_selectedUser!['name']}', style: const TextStyle(fontSize: 12, color: Colors.green)),
      );
    }
    if (_audienceLoading) return const Padding(padding: EdgeInsets.only(top:4), child: LinearProgressIndicator(minHeight: 3));
    if (_audienceCount == null) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(top:4),
      child: Text('Estimated audience: $_audienceCount users', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
    );
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    if (_segment == 'user' && _selectedUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a user first')));
      return;
    }
    if (_segment == 'user' && _selectedUser != null) {
      _targetUidCtrl.text = _selectedUser!['uid'];
    }
    setState(() { _sending = true; _resultMsg = null; });
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('sendAdminNotification');
      final res = await callable.call({
        'title': _titleCtrl.text.trim(),
        'body': _bodyCtrl.text.trim(),
        'segment': _segment,
        'targetUid': _segment == 'user' ? _targetUidCtrl.text.trim() : '',
        'targetRoute': _targetRoute ?? ''
      });
      final data = res.data;
      setState(() { _resultMsg = 'Sent: ${data['sent']}  Failed: ${data['failed']}  AudienceTokens: ${data['totalTokens']}'; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_resultMsg ?? 'Sent')),
        );
      }
    } catch (e) {
      setState(() { _resultMsg = 'Error: $e'; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Send failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() { _sending = false; });
    }
  }

  void _openConfirmSheet() async {
    // Validate first
    if (!_formKey.currentState!.validate()) return;
    if (_segment == 'user' && _selectedUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a user first')));
      return;
    }
    // Ensure audience count (except single user already handled)
    if (_segment != 'user' && _audienceCount == null && !_audienceLoading) {
      _scheduleAudienceRecalc();
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSt) {
            final title = _titleCtrl.text.trim();
            final body = _bodyCtrl.text.trim();
            String audienceLabel;
            if (_segment == 'user') {
              audienceLabel = _selectedUser != null ? 'Single user: ${_selectedUser!['name']}' : 'Single user (not selected)';
            } else if (_segment == 'all') {
              audienceLabel = 'All active users';
            } else if (_segment == 'premium') {
              audienceLabel = 'Premium users';
            } else if (_segment == 'non_premium') {
              audienceLabel = 'Standard (non-premium) users';
            } else {
              audienceLabel = _segment;
            }
            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    Container(height:4,width:52,decoration: BoxDecoration(color: Colors.grey.shade400,borderRadius: BorderRadius.circular(4))),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Icon(Icons.verified_user, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text('Confirm Send', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.4)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16,14,16,16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title.isEmpty ? '(No Title)' : title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              Text(body.isEmpty ? '(No Body)' : body, style: Theme.of(context).textTheme.bodyMedium, maxLines: 8, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _confirmMetaChip(Icons.filter_list, audienceLabel),
                                  if (_segment != 'user') _confirmMetaChip(
                                    Icons.people_alt_outlined,
                                    _audienceLoading ? 'Estimating...' : (_audienceCount == null ? 'Audience ?' : '${_audienceCount!} users'),
                                  ) else if (_selectedUser != null) _confirmMetaChip(Icons.person, _selectedUser!['name']),
                                  if (_targetRoute != null && _targetRoute!.isNotEmpty) _confirmMetaChip(Icons.route, _targetRoute!),
                                  _confirmMetaChip(Icons.title, '${title.length}/100'),
                                  _confirmMetaChip(Icons.notes, '${body.length}/500'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, size: 18, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 6),
                              Text('Review before sending', style: Theme.of(context).textTheme.labelLarge),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('This action will dispatch a push notification to the selected audience. This cannot be undone.', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20,0,20,20),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _sending ? null : () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _sending ? null : () async {
                                await _send();
                                if (mounted && !_sending) Navigator.pop(ctx);
                              },
                              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                              icon: _sending ? const SizedBox(width:20,height:20,child: CircularProgressIndicator(strokeWidth:2,color: Colors.white)) : const Icon(Icons.send_rounded),
                              label: Text(_sending ? 'Sending...' : 'Send Now'),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      }
    );
  }

  void _openRouteSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        String? temp = _targetRoute;
        final options = <Map<String,String?>>[
          {'label':'No navigation','value':null},
          {'label':'Help & Support','value':'/help'},
          {'label':'Support Request','value':'/support'},
          {'label':'Store','value':'/store'},
          {'label':'My Profile','value':'/profile'},
          {'label':'Practice Listening','value':'/practice-listening'},
          {'label':'Practice Reading','value':'/practice-reading'},
          {'label':'Practice Speaking','value':'/practice-speaking'},
          {'label':'Practice Writing','value':'/practice-writing'},
        ];
        return StatefulBuilder(builder: (ctx,setSt){
          Widget tile(Map<String,String?> o){
            final sel = temp == o['value'];
            return ListTile(
              leading: Icon(sel? Icons.radio_button_checked: Icons.radio_button_off, color: sel? Theme.of(context).colorScheme.primary:null),
              title: Text(o['label'] ?? ''),
              subtitle: o['value']!=null? Text(o['value']!, style: const TextStyle(fontSize:11,color: Colors.blueGrey)):null,
              onTap: ()=> setSt(()=> temp = o['value']),
            );
          }
          return SafeArea(
            top:false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height:12),
                Container(height:4,width:44,decoration: BoxDecoration(color: Colors.grey.shade400,borderRadius: BorderRadius.circular(4))),
                const SizedBox(height:12),
                Text('Select Target Route', style: Theme.of(context).textTheme.titleMedium),
                Flexible(child: SingleChildScrollView(child: Column(children: options.map(tile).toList()))),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16,8,16,16),
                  child: Row(children:[
                    Expanded(child: OutlinedButton(onPressed: ()=> Navigator.pop(ctx), child: const Text('Cancel'))),
                    const SizedBox(width:12),
                    Expanded(child: ElevatedButton.icon(onPressed: (){ setState(()=> _targetRoute = temp); Navigator.pop(ctx); }, icon: const Icon(Icons.done), label: const Text('Apply'))),
                  ]),
                )
              ],
            ),
          );
        });
      }
    );
  }

  Widget _confirmMetaChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    );
  }

  // Reintroduce preview card (was missing causing compile error)
  Widget _buildPreviewCard() {
    final theme = Theme.of(context);
    final title = _titleCtrl.text.trim().isEmpty ? 'Notification Title' : _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim().isEmpty ? 'Your notification message preview appears here.' : _bodyCtrl.text.trim();
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16,14,16,14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(body, style: theme.textTheme.bodyMedium, maxLines: 5, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.phone_android, size: 14, color: theme.colorScheme.primary),
                const SizedBox(width:4),
                Text('Live Preview', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary)),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_role == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_role != 'admin') {
      return const Scaffold(body: Center(child: Text('No access')));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Notification'),
        actions: [
          IconButton(onPressed: _sending? null : () { _titleCtrl.clear(); _bodyCtrl.clear(); }, icon: const Icon(Icons.refresh))
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Compose', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleCtrl,
              maxLength: 100,
              decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder(), counterText: ''),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bodyCtrl,
              maxLength: 500,
              minLines: 4,
              maxLines: 10,
              decoration: const InputDecoration(labelText: 'Message Body', border: OutlineInputBorder(), alignLabelWithHint: true, counterText: ''),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.filter_list),
              title: const Text('Audience'),
              subtitle: Text(
                _segment == 'user' && _selectedUser != null
                  ? 'Single user: ${_selectedUser!['name']}'
                  : _segment
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _openAudienceSheet,
            ),
            // Route selection tile
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.route),
              title: const Text('Target Route'),
              subtitle: Text(_targetRoute==null || _targetRoute!.isEmpty? 'None' : _targetRoute!),
              trailing: const Icon(Icons.chevron_right),
              onTap: _openRouteSheet,
            ),
            _buildUserSearchArea(),
            _buildAudienceInfo(),
            const SizedBox(height: 24),
            Text('Live Preview', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _buildPreviewCard(),
            const SizedBox(height: 28),
            Row(children:[
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  icon: _sending ? const SizedBox(height:22,width:22,child: CircularProgressIndicator(strokeWidth:2,color: Colors.white)) : const Icon(Icons.send_rounded),
                  label: Text(_sending ? 'Sending...' : 'Send'),
                  onPressed: _sending ? null : _openConfirmSheet,
                ),
              ),
              const SizedBox(width: 12),
              if (_currentUid != null)
                ElevatedButton(
                  onPressed: _sending ? null : () {
                    setState(()=> _segment = 'user');
                    _selectUser({'uid': _currentUid!, 'name': 'Me'});
                    _openConfirmSheet();
                  },
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                  child: const Text('Test To Me'),
                )
            ]),
            if (_resultMsg != null) ...[
              const SizedBox(height: 12),
              Text(_resultMsg!, style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
            ],
            const SizedBox(height: 36),
            Text('History', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _buildHistoryList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    return StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
      stream: FirebaseFirestore.instance.collection('admin_notifications_log').orderBy('createdAt', descending: true).limit(30).snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()));
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const Text('No notifications sent yet.', style: TextStyle(fontSize: 12, color: Colors.grey));
        }
        return Column(
          children: [
            for (final d in snap.data!.docs) _historyTile(d.data())
          ],
        );
      },
    );
  }
  Widget _historyTile(Map<String,dynamic> data) {
    final title = data['title'] ?? '';
    final body = data['body'] ?? '';
    final segment = data['segment'] ?? '';
    final sent = data['sent'];
    final failed = data['failed'];
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final targetRoute = data['targetRoute'];
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: const Icon(Icons.notifications_active_outlined),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(segment, style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16,0,16,12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(body, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(spacing: 12, runSpacing: 4, children: [
                  _metaChip('sent', '$sent'),
                  _metaChip('failed', '$failed'),
                  if (createdAt != null) _metaChip('time', createdAt.toLocal().toIso8601String()),
                  if (targetRoute != null && (targetRoute as String).isNotEmpty) _metaChip('route', targetRoute),
                ]),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      _titleCtrl.text = title;
                      _bodyCtrl.text = body;
                      if (targetRoute is String?) _targetRoute = targetRoute;
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Loaded into compose')));
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Reuse'),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
  Widget _metaChip(String label, String value) {
    return Chip(label: Text('$label: $value', style: const TextStyle(fontSize: 11)));
  }
}
