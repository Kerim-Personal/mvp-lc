// lib/screens/admin_panel_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Clipboard için
import 'package:lingua_chat/services/admin_service.dart';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final AdminService _adminService = AdminService();
  String _bannedSearch = '';

  // Pagination (dinamik)
  // static const int _pageSize = 10; // (kaldırıldı)
  int _supportPageSize = 10;
  int _reportPageSize = 10;
  int _bannedPageSize = 10;
  int _supportPageIndex = 0;
  int _reportPageIndex = 0;
  int _bannedPageIndex = 0;
  int _supportTotal = 0;
  int _reportTotal = 0;
  int _bannedTotal = 0;

  // Support state
  final List<DocumentSnapshot<Map<String, dynamic>>> _supportDocs = [];
  bool _supportLoading = false;
  bool _supportHasMore = true;
  String _supportStatusFilter = 'all';

  // Reports state
  final List<DocumentSnapshot<Map<String, dynamic>>> _reportDocs = [];
  bool _reportLoading = false;
  bool _reportHasMore = true;
  String _reportStatusFilter = 'all';

  // Banned users state
  final List<DocumentSnapshot<Map<String, dynamic>>> _bannedDocs = [];
  bool _bannedLoading = false;
  bool _bannedHasMore = true;

  // User name cache
  final Map<String, String> _userNameCache = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // İlk veri yüklemeleri
    unawaited(_loadInitialSupport());
    unawaited(_loadInitialReports());
    unawaited(_loadInitialBanned());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<bool> _hasAccess() async {
    final role = await _adminService.getCurrentUserRole();
    return role == 'admin' || role == 'moderator';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasAccess(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snap.data != true) {
          return const Scaffold(body: Center(child: Text('Erişim yok.')));
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('Yönetim Paneli'),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.support_agent), text: 'Destek'),
                Tab(icon: Icon(Icons.block), text: 'Banlı'),
                Tab(icon: Icon(Icons.report), text: 'Raporlar'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildSupportTab(),
              _buildBannedUsersTab(),
              _buildReportsTab(),
            ],
          ),
        );
      },
    );
  }

  // --------------- Data Fetch Helpers ---------------
  Future<void> _loadInitialSupport() async {
    setState(() { _supportLoading = true; _supportDocs.clear(); _supportHasMore = true; _supportPageIndex = 0; });
    try {
      Query<Map<String,dynamic>> base = FirebaseFirestore.instance.collection('support');
      if (_supportStatusFilter != 'all') base = base.where('status', isEqualTo: _supportStatusFilter);
      try { final c = await base.count().get(); _supportTotal = c.count ?? 0; } catch(_){ _supportTotal = 0; }
      final snap = await base.orderBy('createdAt', descending: true).limit(_supportPageSize).get();
      setState(() { _supportDocs.addAll(snap.docs); _supportHasMore = snap.docs.length == _supportPageSize; });
      // Güvenli page clamp
      final totalPages = _supportTotal == 0 ? 1 : ((_supportTotal + _supportPageSize - 1) ~/ _supportPageSize);
      if (_supportPageIndex >= totalPages) _supportPageIndex = totalPages - 1;
    } catch(e){ _showSnack('Destek yüklenemedi: $e'); }
    finally { if (mounted) setState(() { _supportLoading = false; }); }
  }

  Future<void> _loadMoreSupport() async {
    if (_supportLoading || !_supportHasMore || _supportDocs.isEmpty) return;
    setState(() { _supportLoading = true; });
    try {
      Query<Map<String,dynamic>> base = FirebaseFirestore.instance.collection('support');
      if (_supportStatusFilter != 'all') base = base.where('status', isEqualTo: _supportStatusFilter);
      final snap = await base.orderBy('createdAt', descending: true).startAfterDocument(_supportDocs.last).limit(_supportPageSize).get();
      setState(() { _supportDocs.addAll(snap.docs); _supportHasMore = snap.docs.length == _supportPageSize; });
    } catch(e){ _showSnack('Devamı alınamadı: $e'); }
    finally { if (mounted) setState(() { _supportLoading = false; }); }
  }

  Future<void> _loadInitialReports() async {
    setState(() { _reportLoading = true; _reportDocs.clear(); _reportHasMore = true; _reportPageIndex = 0; });
    try {
      Query<Map<String,dynamic>> base = FirebaseFirestore.instance.collection('reports');
      if (_reportStatusFilter != 'all') base = base.where('status', isEqualTo: _reportStatusFilter);
      try { final c = await base.count().get(); _reportTotal = c.count ?? 0; } catch(_){ _reportTotal = 0; }
      final snap = await base.orderBy('timestamp', descending: true).limit(_reportPageSize).get();
      setState(() { _reportDocs.addAll(snap.docs); _reportHasMore = snap.docs.length == _reportPageSize; });
      final totalPages = _reportTotal == 0 ? 1 : ((_reportTotal + _reportPageSize - 1) ~/ _reportPageSize);
      if (_reportPageIndex >= totalPages) _reportPageIndex = totalPages - 1;
    } catch(e){ _showSnack('Raporlar yüklenemedi: $e'); }
    finally { if (mounted) setState(() { _reportLoading = false; }); }
  }

  Future<void> _loadMoreReports() async {
    if (_reportLoading || !_reportHasMore || _reportDocs.isEmpty) return;
    setState(() { _reportLoading = true; });
    try {
      Query<Map<String,dynamic>> base = FirebaseFirestore.instance.collection('reports');
      if (_reportStatusFilter != 'all') base = base.where('status', isEqualTo: _reportStatusFilter);
      final snap = await base.orderBy('timestamp', descending: true).startAfterDocument(_reportDocs.last).limit(_reportPageSize).get();
      setState(() { _reportDocs.addAll(snap.docs); _reportHasMore = snap.docs.length == _reportPageSize; });
    } catch(e){ _showSnack('Rapor devamı alınamadı: $e'); }
    finally { if (mounted) setState(() { _reportLoading = false; }); }
  }

  Future<void> _loadInitialBanned() async {
    setState(() { _bannedLoading = true; _bannedDocs.clear(); _bannedHasMore = true; _bannedPageIndex = 0; });
    try {
      final base = FirebaseFirestore.instance.collection('users').where('status', isEqualTo: 'banned');
      try { final c = await base.count().get(); _bannedTotal = c.count ?? 0; } catch(_){ _bannedTotal = 0; }
      final snap = await base.orderBy('displayName').limit(_bannedPageSize).get();
      setState(() { _bannedDocs.addAll(snap.docs); _bannedHasMore = snap.docs.length == _bannedPageSize; });
      final totalItems = _bannedTotal; // filtre yok initial
      final totalPages = totalItems == 0 ? 1 : ((totalItems + _bannedPageSize - 1) ~/ _bannedPageSize);
      if (_bannedPageIndex >= totalPages) _bannedPageIndex = totalPages - 1;
    } catch(e){ _showSnack('Banlı kullanıcılar yüklenemedi: $e'); }
    finally { if (mounted) setState(() { _bannedLoading = false; }); }
  }

  Future<void> _loadMoreBanned() async {
    if (_bannedLoading || !_bannedHasMore || _bannedDocs.isEmpty) return;
    setState(() { _bannedLoading = true; });
    try {
      final base = FirebaseFirestore.instance.collection('users').where('status', isEqualTo: 'banned');
      final snap = await base.orderBy('displayName').startAfterDocument(_bannedDocs.last).limit(_bannedPageSize).get();
      setState(() { _bannedDocs.addAll(snap.docs); _bannedHasMore = snap.docs.length == _bannedPageSize; });
    } catch(e){ _showSnack('Devamı alınamadı: $e'); }
    finally { if (mounted) setState(() { _bannedLoading = false; }); }
  }

  // Sayfa atlamada yeterli veri yoksa gerekli batch'leri ardışık yükler.
  Future<void> _ensureSupportPage(int target) async {
    if (target < 0) return;
    final need = (target + 1) * _supportPageSize;
    while (_supportDocs.length < need && _supportHasMore) {
      await _loadMoreSupport();
    }
  }
  Future<void> _ensureReportPage(int target) async {
    if (target < 0) return;
    final need = (target + 1) * _reportPageSize;
    while (_reportDocs.length < need && _reportHasMore) {
      await _loadMoreReports();
    }
  }
  Future<void> _ensureBannedPage(int target) async {
    if (target < 0) return;
    final need = (target + 1) * _bannedPageSize;
    while (_bannedDocs.length < need && _bannedHasMore) {
      await _loadMoreBanned();
    }
  }

  Future<String> _getUserName(String uid) async {
    if (uid.isEmpty) return '';
    if (_userNameCache.containsKey(uid)) return _userNameCache[uid]!;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final name = (doc.data()?['displayName'] as String?) ?? uid;
      _userNameCache[uid] = name;
      return name;
    } catch (_) {
      return uid;
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
  // --------------- End Data Fetch Helpers ---------------

  Widget _buildSupportTab() {
    final totalPages = _supportTotal==0?1:((_supportTotal + _supportPageSize -1) ~/ _supportPageSize);
    return RefreshIndicator(
      onRefresh: _loadInitialSupport,
      child: Column(
        children: [
          _buildSupportFilterBar(),
          Expanded(
            child: _supportLoading && _supportDocs.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _supportDocs.isEmpty
                    ? const Center(child: Text('Destek talebi yok.'))
                    : ListView.separated(
                        itemCount: (() { final slice = _supportDocs.skip(_supportPageIndex * _supportPageSize).take(_supportPageSize).length; return slice; })(),
                        separatorBuilder: (_, __) => const Divider(height: 0),
                        itemBuilder: (context, i) {
                          final visible = _supportDocs.skip(_supportPageIndex * _supportPageSize).take(_supportPageSize).toList();
                          final d = visible[i];
                          final data = d.data() ?? {};
                          final status = (data['status'] as String?) ?? 'open';
                          final attachments = (data['attachments'] is List) ? (data['attachments'] as List).cast<dynamic>() : const [];
                          final attachInfo = attachments.isNotEmpty ? '\n📎 ${attachments.length} fotoğraf' : '';
                          return ListTile(
                            key: ValueKey(d.id),
                            leading: const Icon(Icons.support_agent),
                            title: Text(data['subject'] ?? '—'),
                            subtitle: Text('${data['displayName'] ?? ''}\n${data['message'] ?? ''}$attachInfo', maxLines: 3, overflow: TextOverflow.ellipsis),
                            isThreeLine: true,
                            trailing: _buildStatusChip(status),
                            onTap: () => _showSupportDetail(d.id, data),
                          );
                        },
                      ),
          ),
          _buildPaginationBar(
            current: _supportPageIndex,
            totalPages: totalPages,
            totalItems: _supportTotal,
            pageSize: _supportPageSize,
            onPageSizeChange: (v){ setState(()=> _supportPageSize = v); _loadInitialSupport(); },
            canPrev: _supportPageIndex>0 && !_supportLoading,
            canNext: _supportPageIndex + 1 < totalPages,
            loading: _supportLoading,
            onPrev: ()=> setState(()=> _supportPageIndex = (_supportPageIndex -1).clamp(0,_supportPageIndex)),
            onNext: () async { final t = _supportPageIndex+1; await _ensureSupportPage(t); if (mounted) setState(()=> _supportPageIndex = t.clamp(0,totalPages-1)); },
            onJump: (t) async { await _ensureSupportPage(t); if (mounted) setState(()=> _supportPageIndex = t.clamp(0,totalPages-1)); },
          ),
        ],
      ),
    );
  }

  Widget _buildSupportFilterBar() {
    const statuses = ['all','open','in_progress','closed'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          for (final s in statuses)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(s),
                selected: _supportStatusFilter == s,
                onSelected: (v) {
                  if (!v) return; setState(() => _supportStatusFilter = s); _loadInitialSupport();
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'closed':
        color = Colors.green; break;
      case 'in_progress':
        color = Colors.orange; break;
      default:
        color = Colors.blueGrey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  void _showSupportDetail(String docId, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        String status = (data['status'] as String?) ?? 'open';
        final TextEditingController msgCtrl = TextEditingController();
        final List<String> pendingUploads = [];
        bool sending = false;
        final picker = ImagePicker();

        Future<void> pickImage(StateSetter setSt) async {
          final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 1600);
            if (x == null) return;
            try {
              setSt(() => pendingUploads.add('uploading'));
              final bytes = await x.readAsBytes();
              final ref = FirebaseStorage.instance.ref().child('support').child('staff_uploads').child(docId).child('staff_${DateTime.now().millisecondsSinceEpoch}_${x.name}');
              await ref.putData(bytes);
              final url = await ref.getDownloadURL();
              setSt(() {
                pendingUploads.remove('uploading');
                pendingUploads.add(url);
              });
            } catch (e) {
              setSt(() => pendingUploads.remove('uploading'));
              _showSnack('Yükleme hatası: $e');
            }
        }

        Future<void> send(StateSetter setSt) async {
          if (status == 'closed') return;
          final text = msgCtrl.text.trim();
          final atts = pendingUploads.where((e) => e != 'uploading').toList();
          if (text.isEmpty && atts.isEmpty) return;
          setSt(() => sending = true);
          try {
            await _adminService.addSupportMessage(docId, text: text.isEmpty ? null : text, attachments: atts.isEmpty ? null : atts);
            msgCtrl.clear();
            setSt(() => pendingUploads.clear());
          } catch (e) {
            _showSnack('Gönderilemedi: $e');
          } finally {
            setSt(() => sending = false);
          }
        }

        Widget buildInitialTicket() {
          final attachments = (data['attachments'] as List?)?.whereType<String>().toList() ?? [];
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['message'] ?? '', style: const TextStyle(fontSize: 14)),
                if (attachments.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: attachments.map((u) => _supportThumb(u)).toList(),
                  )
                ],
                const SizedBox(height: 4),
                Text('Kullanıcı Talebi', style: TextStyle(fontSize: 11, color: Colors.teal.shade700, fontWeight: FontWeight.w600)),
              ],
            ),
          );
        }

        Widget buildMessages() {
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('support').doc(docId).collection('messages').orderBy('createdAt', descending: true).limit(300).snapshots(),
            builder: (c, snap) {
              if (snap.hasError) {
                return Center(child: Text('Mesajlar yüklenemedi: ' + snap.error.toString(), textAlign: TextAlign.center));
              }
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data!.docs;
              if (docs.isEmpty) {
                return ListView(
                  reverse: true,
                  children: [buildInitialTicket()],
                );
              }
              return ListView.builder(
                reverse: true,
                itemCount: docs.length + 1,
                padding: const EdgeInsets.only(bottom: 8),
                itemBuilder: (ctx, i) {
                  if (i == docs.length) return buildInitialTicket();
                  final d = docs[i].data();
                  final role = (d['senderRole'] as String?) ?? 'user';
                  final isStaff = role == 'admin' || role == 'moderator';
                  final text = (d['text'] as String?) ?? '';
                  final attachments = (d['attachments'] as List?)?.whereType<String>().toList() ?? [];
                  return Align(
                    alignment: isStaff ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      padding: const EdgeInsets.all(12),
                      constraints: const BoxConstraints(maxWidth: 340),
                      decoration: BoxDecoration(
                        color: isStaff ? Colors.teal.shade600 : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (text.isNotEmpty)
                            Text(text, style: TextStyle(color: isStaff ? Colors.white : Colors.black87)),
                          if (attachments.isNotEmpty) ...[
                            if (text.isNotEmpty) const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: attachments.map((u) => _supportThumb(u, dark: isStaff)).toList(),
                            )
                          ],
                          const SizedBox(height: 4),
                          Text(_formatTs(d['createdAt']), style: TextStyle(fontSize: 10, color: isStaff ? Colors.white70 : Colors.black45)),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        }

        return StatefulBuilder(builder: (context, setSt) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * .85,
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20,16,16,8),
                    child: Row(
                      children: [
                        Expanded(child: Text(data['subject'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                        _buildStatusChip(status),
                        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Text('Kullanıcı: ${data['displayName'] ?? ''}', style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 12),
                        Expanded(child: Text('${data['email'] ?? ''}', style: const TextStyle(fontSize: 12, color: Colors.black54), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Status değiştirici
                  Wrap(spacing: 6, children: [
                    for (final s in ['open','in_progress','closed'])
                      ChoiceChip(
                        label: Text(s),
                        selected: status == s,
                        onSelected: (v) async {
                          if (!v) return;
                          try {
                            await _adminService.updateSupportStatus(docId, s);
                            setSt(() => status = s);
                            _showSnack('Destek durumu güncellendi.');
                          } catch (e) {
                            _showSnack('Güncellenemedi: $e');
                          }
                        },
                      ),
                  ]),
                  const Divider(height: 20),
                  // Mesaj listesi
                  Expanded(child: buildMessages()),
                  if (pendingUploads.isNotEmpty)
                    SizedBox(
                      height: 90,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (c,i){
                          final u = pendingUploads[i];
                          if (u == 'uploading') {
                            return const SizedBox(width:72,height:72,child: Center(child: CircularProgressIndicator(strokeWidth:2)));
                          }
                          return Stack(children:[
                            ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(u, width:72,height:72,fit:BoxFit.cover)),
                            Positioned(right:0,top:0,child: GestureDetector(
                              onTap: ()=> setSt(()=> pendingUploads.removeAt(i)),
                              child: Container(decoration: BoxDecoration(color: Colors.black54,borderRadius: BorderRadius.circular(12)),padding: const EdgeInsets.all(2),child: const Icon(Icons.close,color: Colors.white,size:14)),
                            ))
                          ]);
                        },
                        separatorBuilder: (_,__)=> const SizedBox(width:8),
                        itemCount: pendingUploads.length,
                      ),
                    ),
                  if (status != 'closed')
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8,4,8,8),
                        child: Row(
                          children: [
                            IconButton(icon: const Icon(Icons.photo), onPressed: sending ? null : () => pickImage(setSt)),
                            Expanded(
                              child: TextField(
                                controller: msgCtrl,
                                minLines: 1,
                                maxLines: 4,
                                decoration: const InputDecoration(hintText: 'Yanıt yaz...', border: OutlineInputBorder()),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              icon: sending ? const SizedBox(width:16,height:16,child: CircularProgressIndicator(strokeWidth:2,color: Colors.white)) : const Icon(Icons.send,size:18),
                              label: const Text('Gönder'),
                              onPressed: sending ? null : () => send(setSt),
                            )
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      color: Colors.grey.shade200,
                      padding: const EdgeInsets.all(12),
                      child: const Center(child: Text('Talep kapalı.')),
                    ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Widget _buildBannedUsersTab() {
    final filtered = _bannedSearch.isEmpty
        ? _bannedDocs
        : _bannedDocs.where((d) {
            final data = d.data() ?? {};
            final name = (data['displayName'] as String?)?.toLowerCase() ?? '';
            final email = (data['email'] as String?)?.toLowerCase() ?? '';
            return name.contains(_bannedSearch) || email.contains(_bannedSearch);
          }).toList();
    final totalItems = _bannedSearch.isEmpty ? _bannedTotal : filtered.length;
    final totalPages = totalItems == 0 ? 1 : ((totalItems + _bannedPageSize - 1) ~/ _bannedPageSize);
    final visible = filtered.skip(_bannedPageIndex * _bannedPageSize).take(_bannedPageSize).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Kullanıcı ara (isim / e-posta)',
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
            onChanged: (v) => setState(() { _bannedSearch = v.trim().toLowerCase(); _bannedPageIndex = 0; }),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadInitialBanned,
            child: _bannedLoading && _bannedDocs.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? const Center(child: Text('Banlı kullanıcı yok.'))
                    : ListView.separated(
                        itemCount: visible.length,
                        separatorBuilder: (_, __) => const Divider(height: 0),
                        itemBuilder: (context, i) {
                          final d = visible[i];
                          final data = d.data() ?? {};
                          return ListTile(
                            key: ValueKey(d.id),
                            leading: const Icon(Icons.person_off, color: Colors.red),
                            title: Text(data['displayName'] ?? '—'),
                            subtitle: Text(data['email'] ?? ''),
                            trailing: TextButton(
                              onPressed: () async {
                                try {
                                  await _adminService.unbanUser(d.id);
                                  _showSnack('Kullanıcı aktifleştirildi.');
                                  _loadInitialBanned();
                                } catch (e) {
                                  _showSnack('Hata: $e');
                                }
                              },
                              child: const Text('Ban Kaldır'),
                            ),
                          );
                        },
                      ),
          ),
        ),
        _buildPaginationBar(
          current: _bannedPageIndex,
          totalPages: totalPages,
          totalItems: totalItems,
          pageSize: _bannedPageSize,
          onPageSizeChange: (v){ setState(()=> _bannedPageSize = v); _loadInitialBanned(); },
          canPrev: _bannedPageIndex>0 && !_bannedLoading,
          canNext: _bannedPageIndex + 1 < totalPages,
          loading: _bannedLoading,
          onPrev: ()=> setState(()=> _bannedPageIndex = (_bannedPageIndex -1).clamp(0,_bannedPageIndex)),
          onNext: () async { final t = _bannedPageIndex+1; if (_bannedSearch.isEmpty) await _ensureBannedPage(t); if (mounted) setState(()=> _bannedPageIndex = t.clamp(0,totalPages-1)); },
          onJump: (t) async { if (_bannedSearch.isEmpty) await _ensureBannedPage(t); if (mounted) setState(()=> _bannedPageIndex = t.clamp(0,totalPages-1)); },
        ),
      ],
    );
  }

  Widget _buildReportsTab() {
    final totalPages = _reportTotal==0?1:((_reportTotal + _reportPageSize -1) ~/ _reportPageSize);
    return RefreshIndicator(
      onRefresh: _loadInitialReports,
      child: Column(
        children: [
          _buildReportsFilterBar(),
          Expanded(
            child: _reportLoading && _reportDocs.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _reportDocs.isEmpty
                    ? const Center(child: Text('Rapor yok.'))
                    : ListView.separated(
                        itemCount: (() { final slice = _reportDocs.skip(_reportPageIndex * _reportPageSize).take(_reportPageSize).length; return slice; })(),
                        separatorBuilder: (_, __) => const Divider(height: 0),
                        itemBuilder: (context, i) {
                          final visible = _reportDocs.skip(_reportPageIndex * _reportPageSize).take(_reportPageSize).toList();
                          final d = visible[i];
                          final data = d.data() ?? {};
                          final status = (data['status'] as String?) ?? 'pending';
                          final reportedUserId = (data['reportedUserId'] as String?) ?? '';
                          final reporterId = (data['reporterId'] as String?) ?? '';
                          final reportedContent = (data['reportedContent'] as String?) ?? '';
                          return ListTile(
                            key: ValueKey(d.id),
                            leading: const Icon(Icons.report, color: Colors.orange),
                            title: Text(data['reason'] ?? '—'),
                            subtitle: FutureBuilder<List<String>>(
                              future: Future.wait([
                                _getUserName(reportedUserId),
                                _getUserName(reporterId),
                              ]),
                              builder: (c, snap) {
                                String targetName = reportedUserId;
                                String reporterName = reporterId;
                                if (snap.hasData) {
                                  targetName = snap.data![0];
                                  reporterName = snap.data![1];
                                }
                                final contentPreview = reportedContent.isEmpty
                                    ? ''
                                    : '\nİçerik: ' + (reportedContent.length > 60 ? reportedContent.substring(0,60) + '…' : reportedContent);
                                return Text('Hedef: $targetName\nRaporlayan: $reporterName$contentPreview', maxLines: 4, overflow: TextOverflow.ellipsis);
                              },
                            ),
                            trailing: _buildStatusChip(status),
                            onTap: () => _showReportDetail(d.id, data),
                          );
                        },
                      ),
          ),
          _buildPaginationBar(
            current: _reportPageIndex,
            totalPages: totalPages,
            totalItems: _reportTotal,
            pageSize: _reportPageSize,
            onPageSizeChange: (v){ setState(()=> _reportPageSize = v); _loadInitialReports(); },
            canPrev: _reportPageIndex>0 && !_reportLoading,
            canNext: _reportPageIndex + 1 < totalPages,
            loading: _reportLoading,
            onPrev: ()=> setState(()=> _reportPageIndex = (_reportPageIndex -1).clamp(0,_reportPageIndex)),
            onNext: () async { final t = _reportPageIndex+1; await _ensureReportPage(t); if (mounted) setState(()=> _reportPageIndex = t.clamp(0,totalPages-1)); },
            onJump: (t) async { await _ensureReportPage(t); if (mounted) setState(()=> _reportPageIndex = t.clamp(0,totalPages-1)); },
          ),
        ],
      ),
    );
  }

  Widget _buildReportsFilterBar() {
    const statuses = ['all','pending','reviewed','dismissed'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
            for (final s in statuses)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(s),
                  selected: _reportStatusFilter == s,
                  onSelected: (v) {
                    if (!v) return;
                    setState(() => _reportStatusFilter = s);
                    _loadInitialReports();
                  },
                ),
              ),
        ],
      ),
    );
  }

  // Tekrar ek (bazı önceki düzenlemelerde kayıp olabilmiş) - destek ekleri küçük önizleme
  Widget _supportThumb(String url, {bool dark = false}) {
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (_) => Dialog(
          child: InteractiveViewer(child: Image.network(url, fit: BoxFit.contain)),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 70,
          height: 70,
            color: dark ? Colors.white24 : Colors.black12,
            child: Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
        ),
      ),
    );
  }

  String _formatTs(dynamic ts) {
    if (ts is Timestamp) {
      final dt = ts.toDate();
      final now = DateTime.now();
      if (now.difference(dt).inDays == 0) {
        return '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
      }
      return '${dt.day.toString().padLeft(2,'0')}.${dt.month.toString().padLeft(2,'0')} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    }
    return '';
  }

  void _showReportDetail(String reportId, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        String status = (data['status'] as String?) ?? 'pending';
        final String reportedUserId = (data['reportedUserId'] as String?) ?? '';
        final String reporterId = (data['reporterId'] as String?) ?? ''; // field adı düzeltildi
        final String reason = (data['reason'] as String?) ?? '';
        final String details = (data['details'] as String?) ?? (data['description'] as String? ?? '');
        final String reportedContent = (data['reportedContent'] as String?) ?? '';
        final timestamp = data['timestamp'];

        return StatefulBuilder(builder: (context, setSt) {
          Widget buildReason() {
            if (reason.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Text('Sebep alanı boş ("reason" kaydı yok).', style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.redAccent)),
              );
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Text('Sebep: $reason', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            );
          }

          Widget buildDetails() {
            if (details.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Text('Açıklama yok ("details" alanı boş).', style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
              );
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Text(details, style: const TextStyle(fontSize: 13)),
            );
          }

            Widget buildReportedContent() {
              if (reportedContent.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Text('Raporlanan içerik yok ("reportedContent" kaydı boş).', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
                );
              }
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text('Raporlanan İçerik:\n$reportedContent', style: const TextStyle(fontSize: 12)),
                ),
              );
            }

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * .75,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20,16,16,4),
                    child: Row(
                      children: [
                        const Icon(Icons.report, color: Colors.orange),
                        const SizedBox(width: 8),
                        const Expanded(child: Text('Rapor Detayı', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                        _buildStatusChip(status),
                        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))
                      ],
                    ),
                  ),
                  buildReason(),
                  buildDetails(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: FutureBuilder<String>(
                      future: _getUserName(reporterId),
                      builder: (_, snap) => Text('Raporlayan: ${(snap.data ?? reporterId).isEmpty ? '—' : (snap.data ?? reporterId)}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                    child: FutureBuilder<String>(
                      future: _getUserName(reportedUserId),
                      builder: (_, snap) => Text('Raporlanan: ${(snap.data ?? reportedUserId).isEmpty ? '—' : (snap.data ?? reportedUserId)}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    ),
                  ),
                  if (timestamp != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                      child: Text('Tarih: ${_formatTs(timestamp)}', style: const TextStyle(fontSize: 11, color: Colors.black45)),
                    ),
                  buildReportedContent(),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Wrap(
                      spacing: 6,
                      children: [
                        for (final s in ['pending','reviewed','dismissed'])
                          ChoiceChip(
                            label: Text(s),
                            selected: status == s,
                            onSelected: (v) async {
                              if (!v) return;
                              try {
                                await _adminService.updateReportStatus(reportId, s);
                                setSt(() => status = s);
                                _showSnack('Rapor durumu güncellendi.');
                              } catch (e) {
                                _showSnack('Güncellenemedi: $e');
                              }
                            },
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Wrap(
                      spacing: 12,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.copy, size:18),
                          label: const Text('ID Kopyala'),
                          onPressed: () async {
                            await Clipboard.setData(ClipboardData(text: reportId));
                            _showSnack('Rapor ID kopyalandı');
                          },
                        ),
                        if (reportedUserId.isNotEmpty)
                          ElevatedButton.icon(
                            icon: const Icon(Icons.gavel, size:18),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            label: const Text('Banla'),
                            onPressed: () => _promptBanUser(reportedUserId),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Future<void> _promptBanUser(String userId) async {
    final allowed = await _adminService.canBanUser(userId);
    if (!allowed) {
      _showSnack('Bu kullanıcıyı banlama yetkiniz yok.');
      return;
    }
    final TextEditingController reasonCtrl = TextEditingController();
    final TextEditingController detailsCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Kullanıcıyı Banla'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(labelText: 'Sebep (kısa)', hintText: 'Örn: Spam'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: detailsCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Detay (opsiyonel)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('İptal')),
          ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('Banla')),
        ],
      ),
    );
    if (ok != true) return;
    final reason = reasonCtrl.text.trim();
    final details = detailsCtrl.text.trim().isEmpty ? null : detailsCtrl.text.trim();
    if (reason.isEmpty) {
      _showSnack('Sebep boş olamaz.');
      return;
    }
    try {
      await _adminService.banUser(userId, reason: reason, details: details);
      _showSnack('Kullanıcı banlandı.');
      // Banlı sekmesini tazelemek istiyorsak:
      _loadInitialBanned();
    } catch (e) {
      _showSnack('Ban hatası: $e');
    }
  }

  Widget _buildPaginationBar({
    required int current,
    required int totalPages,
    required int totalItems,
    required int pageSize,
    required void Function(int) onPageSizeChange,
    required bool canPrev,
    required bool canNext,
    required bool loading,
    required VoidCallback onPrev,
    required Future<void> Function() onNext,
    required Future<void> Function(int) onJump,
  }) {
    final controller = TextEditingController(text: (current+1).toString());
    const options = [10,20,50];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface.withValues(alpha: .95), boxShadow:[BoxShadow(color: Colors.black.withValues(alpha:.05), blurRadius:4)]),
      child: Row(children:[
        IconButton(icon: const Icon(Icons.chevron_left), tooltip:'Önceki', onPressed: canPrev? onPrev : null),
        SizedBox(width:54, child: TextField(
          controller: controller,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(isDense:true, contentPadding: EdgeInsets.symmetric(vertical:6), border: OutlineInputBorder()),
          style: const TextStyle(fontSize:13),
          onSubmitted: (v){ final p=int.tryParse(v); if(p!=null && p>0){ onJump(p-1); } },
        )),
        const SizedBox(width:6),
        Text('/ $totalPages', style: const TextStyle(fontWeight: FontWeight.w600)),
        IconButton(icon: const Icon(Icons.chevron_right), tooltip:'Sonraki', onPressed: canNext && !loading ? (){ onNext(); } : null),
        const Spacer(),
        if(!loading) Text('Toplam: $totalItems', style: const TextStyle(fontSize:12,fontWeight: FontWeight.w500)),
        const SizedBox(width:12),
        DropdownButton<int>(
          value: pageSize,
          underline: const SizedBox.shrink(),
          onChanged: (v){ if(v!=null && v!=pageSize) onPageSizeChange(v); },
          items: options.map((e)=> DropdownMenuItem(value:e, child: Text('$e/sa'))).toList(),
        )
      ]),
    );
  }
}
