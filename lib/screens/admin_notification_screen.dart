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

class _AdminNotificationScreenState extends State<AdminNotificationScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _targetUidCtrl = TextEditingController();
  final TextEditingController _userSearchCtrl = TextEditingController();

  Timer? _userSearchDebounce;
  List<Map<String, dynamic>> _userSearchResults = [];
  bool _userSearchLoading = false;
  Map<String, dynamic>? _selectedUser;

  final AdminService _adminService = AdminService();
  String _segment = 'all';
  bool _sending = false;
  String? _role;
  String? _resultMsg;
  int? _audienceCount;
  bool _audienceLoading = false;
  Timer? _audienceDebounce;
  String? _currentUid;
  String? _targetRoute;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadRole();
    _scheduleAudienceRecalc();
    _titleCtrl.addListener(_triggerPreviewUpdate);
    _bodyCtrl.addListener(_triggerPreviewUpdate);
    _targetUidCtrl.addListener(() {
      if (_segment == 'user') _scheduleAudienceRecalc();
    });
    _userSearchCtrl.addListener(() {
      if (_segment == 'user') _scheduleUserSearch();
    });
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _userSearchDebounce?.cancel();
    _audienceDebounce?.cancel();
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _targetUidCtrl.dispose();
    _userSearchCtrl.dispose();
    super.dispose();
  }

  void _triggerPreviewUpdate() {
    if (mounted) setState(() {});
  }

  void _scheduleAudienceRecalc() {
    _audienceDebounce?.cancel();
    _audienceDebounce =
        Timer(const Duration(milliseconds: 450), _calcAudienceCount);
  }

  Future<void> _calcAudienceCount() async {
    if (_role != 'admin') return;
    setState(() {
      _audienceLoading = true;
    });
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
        setState(() => _audienceCount = (_selectedUser != null ? 1 : 0));
        return;
      } else {
        q = fs.collection('users')
            .where('status', isEqualTo: 'active')
            .count();
      }
      final snap = await q.get();
      setState(() => _audienceCount = snap.count);
    } catch (_) {
      if (mounted) setState(() => _audienceCount = null);
    } finally {
      if (mounted) setState(() => _audienceLoading = false);
    }
  }

  Future<void> _loadRole() async {
    final r = await _adminService.getCurrentUserRole();
    final authUid = FirebaseAuth.instance.currentUser?.uid;
    if (!mounted) return;
    setState(() {
      _role = r;
      _currentUid = authUid;
    });
  }

  void _openAudienceSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        String temp = _segment;
        return StatefulBuilder(
          builder: (ctx, setSt) {
            Widget option(String key, String label, IconData icon, Color color) {
              final selected = temp == key;
              return InkWell(
                onTap: () => setSt(() => temp = key),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected ? color : Colors.grey.withOpacity(0.35),
                      width: selected ? 2 : 1,
                    ),
                    color: selected
                        ? color.withOpacity(0.10)
                        : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: selected ? color : Colors.grey.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, size: 20, color: selected ? Colors.white : Colors.grey[700]),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                            color: selected ? color : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (selected) Icon(Icons.check_circle, color: color, size: 22),
                    ],
                  ),
                ),
              );
            }

            return FractionallySizedBox(
              heightFactor: 0.70,
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      height: 4,
                      width: 52,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Icon(Icons.tune, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 10),
                          Text(
                            'Select Audience',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.only(top: 4, bottom: 4),
                        children: [
                          option('all','All Active Users', Icons.groups, Colors.blue),
                          option('premium','Premium Users', Icons.star_rate_rounded, Colors.amber),
                          option('non_premium','Standard Users', Icons.person_outline, Colors.teal),
                          option('user','Single User', Icons.person_pin_circle, Colors.purple),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _segment = temp;
                                  if (_segment != 'user') {
                                    _selectedUser = null;
                                    _targetUidCtrl.clear();
                                  }
                                });
                                Navigator.pop(ctx);
                                _scheduleAudienceRecalc();
                              },
                              icon: const Icon(Icons.done),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              label: const Text('Apply'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _scheduleUserSearch() {
    _userSearchDebounce?.cancel();
    _userSearchDebounce =
        Timer(const Duration(milliseconds: 450), _performUserSearch);
  }

  Future<void> _performUserSearch() async {
    final term = _userSearchCtrl.text.trim();
    if (_segment != 'user') return;
    if (term.length < 2) {
      if (mounted) setState(() {
        _userSearchResults = [];
      });
      return;
    }
    setState(() {
      _userSearchLoading = true;
    });
    final fs = FirebaseFirestore.instance;
    final lower = term.toLowerCase();
    final attempts = [
      'usernameLower',
      'displayNameLower',
      'username',
      'displayName'
    ];
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = [];
    for (final field in attempts) {
      try {
        final q = fs.collection('users')
            .orderBy(field)
            .startAt([lower])
            .endAt([lower + '\uf8ff'])
            .limit(10);
        final snap = await q.get();
        docs = snap.docs;
        if (docs.isNotEmpty) break;
      } catch (_) {
        continue;
      }
    }
    final results = docs.map((d) {
      final data = d.data();
      final name = data['username'] ?? data['displayName'] ??
          data['displayNameLower'] ?? data['usernameLower'] ?? d.id;
      final status = data['status'];
      if (status != null && status != 'active') return null;
      return {'uid': d.id, 'name': name};
    }).whereType<Map<String, dynamic>>().toList();
    if (mounted) setState(() {
      _userSearchResults = results;
      _userSearchLoading = false;
    });
  }

  void _selectUser(Map<String, dynamic> user) {
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _userSearchCtrl,
              decoration: InputDecoration(
                labelText: 'Search username',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _userSearchCtrl.text.isNotEmpty
                    ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _userSearchCtrl.clear();
                      _scheduleUserSearch();
                    }
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme
                    .of(context)
                    .colorScheme
                    .surfaceVariant
                    .withOpacity(0.3),
              ),
            ),
          ),
          if (_userSearchLoading)
            Container(
              margin: const EdgeInsets.only(top: 8),
              child: const LinearProgressIndicator(minHeight: 3),
            ),
          if (_selectedUser != null)
            Container(
              margin: const EdgeInsets.only(top: 12),
              child: Wrap(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme
                          .of(context)
                          .colorScheme
                          .primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: Theme
                              .of(context)
                              .colorScheme
                              .primary,
                          child: const Icon(
                              Icons.person, size: 16, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _selectedUser!['name'],
                          style: TextStyle(
                            color: Theme
                                .of(context)
                                .colorScheme
                                .onPrimaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _clearSelectedUser,
                          child: Icon(
                            Icons.close,
                            size: 18,
                            color: Theme
                                .of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (_userSearchResults.isNotEmpty && _selectedUser == null)
            Container(
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  itemCount: _userSearchResults.length,
                  itemBuilder: (c, i) {
                    final u = _userSearchResults[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme
                            .of(context)
                            .colorScheme
                            .primaryContainer,
                        child: Icon(
                          Icons.person_outline,
                          color: Theme
                              .of(context)
                              .colorScheme
                              .onPrimaryContainer,
                        ),
                      ),
                      title: Text(u['name'], maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        u['uid'],
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme
                              .of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                      onTap: () => _selectUser(u),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAudienceInfo() {
    if (_segment == 'user') {
      if (_selectedUser == null) return const SizedBox();
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Target: ${_selectedUser!['name']}',
          style: const TextStyle(
              fontSize: 12, color: Colors.green, fontWeight: FontWeight.w500),
        ),
      );
    }

    if (_audienceLoading) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        child: const LinearProgressIndicator(minHeight: 3),
      );
    }

    if (_audienceCount == null) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme
            .of(context)
            .colorScheme
            .surfaceVariant
            .withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Estimated audience: $_audienceCount users',
        style: TextStyle(
          fontSize: 12,
          color: Theme
              .of(context)
              .colorScheme
              .onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    if (_segment == 'user' && _selectedUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a user first')));
      return;
    }
    if (_segment == 'user' && _selectedUser != null) {
      _targetUidCtrl.text = _selectedUser!['uid'];
    }
    setState(() {
      _sending = true;
      _resultMsg = null;
    });
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
          'sendAdminNotification');
      final res = await callable.call({
        'title': _titleCtrl.text.trim(),
        'body': _bodyCtrl.text.trim(),
        'segment': _segment,
        'targetUid': _segment == 'user' ? _targetUidCtrl.text.trim() : '',
        'targetRoute': _targetRoute ?? ''
      });
      final data = res.data;
      setState(() {
        _resultMsg =
        'Sent: ${data['sent']}  Failed: ${data['failed']}  AudienceTokens: ${data['totalTokens']}';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_resultMsg ?? 'Sent')),
        );
      }
    } catch (e) {
      setState(() {
        _resultMsg = 'Error: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Send failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() {
        _sending = false;
      });
    }
  }

  void _openConfirmSheet() async {
    // Validate first
    if (!_formKey.currentState!.validate()) return;
    if (_segment == 'user' && _selectedUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a user first')));
      return;
    }
    // Ensure audience count (except single user already handled)
    if (_segment != 'user' && _audienceCount == null && !_audienceLoading) {
      _scheduleAudienceRecalc();
    }
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Theme
            .of(context)
            .colorScheme
            .surface,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setSt) {
              final title = _titleCtrl.text.trim();
              final body = _bodyCtrl.text.trim();
              String audienceLabel;
              if (_segment == 'user') {
                audienceLabel = _selectedUser != null
                    ? 'Single user: ${_selectedUser!['name']}'
                    : 'Single user (not selected)';
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
                    bottom: MediaQuery
                        .of(ctx)
                        .viewInsets
                        .bottom,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 12),
                      Container(height: 4,
                          width: 52,
                          decoration: BoxDecoration(color: Colors.grey.shade400,
                              borderRadius: BorderRadius.circular(4))),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Icon(Icons.verified_user, color: Theme
                                .of(context)
                                .colorScheme
                                .primary),
                            const SizedBox(width: 8),
                            Text('Confirm Send', style: Theme
                                .of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Theme
                                .of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withOpacity(0.5),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Theme
                                .of(context)
                                .dividerColor
                                .withOpacity(0.4)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title.isEmpty ? '(No Title)' : title,
                                    style: Theme
                                        .of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
                                Text(body.isEmpty ? '(No Body)' : body,
                                    style: Theme
                                        .of(context)
                                        .textTheme
                                        .bodyMedium,
                                    maxLines: 8,
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _confirmMetaChip(
                                        Icons.filter_list, audienceLabel),
                                    if (_segment != 'user') _confirmMetaChip(
                                      Icons.people_alt_outlined,
                                      _audienceLoading
                                          ? 'Estimating...'
                                          : (_audienceCount == null
                                          ? 'Audience ?'
                                          : '${_audienceCount!} users'),
                                    ) else
                                      if (_selectedUser !=
                                          null) _confirmMetaChip(
                                          Icons.person, _selectedUser!['name']),
                                    if (_targetRoute != null && _targetRoute!
                                        .isNotEmpty) _confirmMetaChip(
                                        Icons.route, _targetRoute!),
                                    _confirmMetaChip(
                                        Icons.title, '${title.length}/100'),
                                    _confirmMetaChip(
                                        Icons.notes, '${body.length}/500'),
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
                                Icon(Icons.info_outline, size: 18, color: Theme
                                    .of(context)
                                    .colorScheme
                                    .primary),
                                const SizedBox(width: 6),
                                Text('Review before sending', style: Theme
                                    .of(context)
                                    .textTheme
                                    .labelLarge),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                                'This action will dispatch a push notification to the selected audience. This cannot be undone.',
                                style: Theme
                                    .of(context)
                                    .textTheme
                                    .bodySmall),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _sending ? null : () =>
                                    Navigator.pop(ctx),
                                style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            14))),
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
                                style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            14))),
                                icon: _sending
                                    ? const SizedBox(width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.send_rounded),
                                label: Text(
                                    _sending ? 'Sending...' : 'Send Now'),
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
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (ctx) {
          String? temp = _targetRoute;
          final options = <Map<String, String?>>[
            {'label': 'No navigation', 'value': null},
            {'label': 'Help & Support', 'value': '/help'},
            {'label': 'Support Request', 'value': '/support'},
            {'label': 'Store', 'value': '/store'},
            {'label': 'My Profile', 'value': '/profile'},
            {'label': 'Practice Listening', 'value': '/practice-listening'},
            {'label': 'Practice Reading', 'value': '/practice-reading'},
            {'label': 'Practice Speaking', 'value': '/practice-speaking'},
            {'label': 'Practice Writing', 'value': '/practice-writing'},
          ];
          return StatefulBuilder(builder: (ctx, setSt) {
            Widget tile(Map<String, String?> o) {
              final sel = temp == o['value'];
              return ListTile(
                leading: Icon(
                    sel ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: sel ? Theme
                        .of(context)
                        .colorScheme
                        .primary : null),
                title: Text(o['label'] ?? ''),
                subtitle: o['value'] != null ? Text(o['value']!,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.blueGrey)) : null,
                onTap: () => setSt(() => temp = o['value']),
              );
            }
            return SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(height: 4,
                      width: 44,
                      decoration: BoxDecoration(color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 12),
                  Text('Select Target Route', style: Theme
                      .of(context)
                      .textTheme
                      .titleMedium),
                  Flexible(child: SingleChildScrollView(
                      child: Column(children: options.map(tile).toList()))),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Row(children: [
                      Expanded(child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'))),
                      const SizedBox(width: 12),
                      Expanded(child: ElevatedButton.icon(onPressed: () {
                        setState(() => _targetRoute = temp);
                        Navigator.pop(ctx);
                      },
                          icon: const Icon(Icons.done),
                          label: const Text('Apply'))),
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

  Widget _buildPreviewCard() {
    final theme = Theme.of(context);
    final title = _titleCtrl.text
        .trim()
        .isEmpty
        ? 'Notification Title'
        : _titleCtrl.text.trim();
    final body = _bodyCtrl.text
        .trim()
        .isEmpty
        ? 'Your notification message preview appears here.'
        : _bodyCtrl.text.trim();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withOpacity(0.3),
            theme.colorScheme.secondaryContainer.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.notifications_active,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              body,
              style: theme.textTheme.bodyMedium,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.smartphone,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Live Preview',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  'Just now',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_role == null) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme
                    .of(context)
                    .colorScheme
                    .primary
                    .withOpacity(0.1),
                Theme
                    .of(context)
                    .colorScheme
                    .secondary
                    .withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_role != 'admin') {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme
                    .of(context)
                    .colorScheme
                    .errorContainer
                    .withOpacity(0.3),
                Theme
                    .of(context)
                    .colorScheme
                    .surface,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Access Denied', style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w600)),
                SizedBox(height: 8),
                Text('You need admin privileges to access this feature.'),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme
                    .of(context)
                    .colorScheme
                    .primary,
                Theme
                    .of(context)
                    .colorScheme
                    .secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'Admin Notifications',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _sending ? null : () {
              _titleCtrl.clear();
              _bodyCtrl.clear();
              _userSearchCtrl.clear();
              _selectedUser = null;
              _targetRoute = null;
              setState(() {});
            },
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme
                  .of(context)
                  .colorScheme
                  .primary
                  .withOpacity(0.05),
              Theme
                  .of(context)
                  .colorScheme
                  .surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.3],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 120, 20, 20),
                children: [
                  // Compose Section
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme
                          .of(context)
                          .colorScheme
                          .surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Theme
                                    .of(context)
                                    .colorScheme
                                    .primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.edit,
                                color: Theme
                                    .of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Compose Message',
                              style: Theme
                                  .of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _titleCtrl,
                          maxLength: 100,
                          decoration: InputDecoration(
                            labelText: 'Notification Title',
                            prefixIcon: const Icon(Icons.title),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            counterText: '${_titleCtrl.text.length}/100',
                          ),
                          validator: (v) =>
                          (v == null || v
                              .trim()
                              .isEmpty) ? 'Title is required' : null,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _bodyCtrl,
                          maxLength: 500,
                          minLines: 4,
                          maxLines: 8,
                          decoration: InputDecoration(
                            labelText: 'Message Content',
                            prefixIcon: const Icon(Icons.message),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            counterText: '${_bodyCtrl.text.length}/500',
                            alignLabelWithHint: true,
                          ),
                          validator: (v) =>
                          (v == null || v
                              .trim()
                              .isEmpty) ? 'Message is required' : null,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Audience Section
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme
                          .of(context)
                          .colorScheme
                          .surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Theme
                                    .of(context)
                                    .colorScheme
                                    .secondaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.people,
                                color: Theme
                                    .of(context)
                                    .colorScheme
                                    .onSecondaryContainer,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Select Audience',
                              style: Theme
                                  .of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: _openAudienceSheet,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                Icon(_getSegmentIcon(_segment)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _getSegmentLabel(_segment),
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down),
                              ],
                            ),
                          ),
                        ),
                        _buildAudienceInfo(),
                        _buildUserSearchArea(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Preview Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme
                                  .of(context)
                                  .colorScheme
                                  .tertiaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.preview,
                              color: Theme
                                  .of(context)
                                  .colorScheme
                                  .onTertiaryContainer,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Notification Preview',
                            style: Theme
                                .of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildPreviewCard(),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Send Button
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme
                              .of(context)
                              .colorScheme
                              .primary,
                          Theme
                              .of(context)
                              .colorScheme
                              .secondary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Theme
                              .of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _sending ? null : _openConfirmSheet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: _sending
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Icon(Icons.send_rounded, color: Colors.white),
                      label: Text(
                        _sending ? 'Sending...' : 'Send Notification',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  if (_resultMsg != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _resultMsg!.contains('Error')
                            ? Theme
                            .of(context)
                            .colorScheme
                            .errorContainer
                            : Theme
                            .of(context)
                            .colorScheme
                            .primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _resultMsg!,
                        style: TextStyle(
                          color: _resultMsg!.contains('Error')
                              ? Theme
                              .of(context)
                              .colorScheme
                              .onErrorContainer
                              : Theme
                              .of(context)
                              .colorScheme
                              .onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getSegmentIcon(String segment) {
    switch (segment) {
      case 'all':
        return Icons.groups;
      case 'premium':
        return Icons.star_rate_rounded; // diamond yerine uyumlu ikon
      case 'non_premium':
        return Icons.person_outline;
      case 'user':
        return Icons.person_pin_circle;
      default:
        return Icons.group;
    }
  }

  String _getSegmentLabel(String segment) {
    switch (segment) {
      case 'all':
        return 'All Active Users';
      case 'premium':
        return 'Premium Users';
      case 'non_premium':
        return 'Standard Users';
      case 'user':
        return 'Single User';
      default:
        return 'Unknown';
    }
  }
}
