import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vocachat/services/admin_service.dart';

class SupportTicketDetailScreen extends StatefulWidget {
  final String ticketId;
  final Map<String, dynamic> ticketData;
  const SupportTicketDetailScreen({super.key, required this.ticketId, required this.ticketData});

  @override
  State<SupportTicketDetailScreen> createState() => _SupportTicketDetailScreenState();
}

class _SupportTicketDetailScreenState extends State<SupportTicketDetailScreen> {
  final _msgCtrl = TextEditingController();
  bool _sending = false;
  bool _loadingUser = true;
  bool _isPremium = false;
  String? _uid;
  final _auth = FirebaseAuth.instance;
  final _picker = ImagePicker();
  final List<String> _pendingUploads = [];

  @override
  void initState() {
    super.initState();
    _uid = _auth.currentUser?.uid;
    _loadUser();
  }

  Future<void> _loadUser() async {
    if (_uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(_uid).get();
      _isPremium = (doc.data()?['isPremium'] as bool?) ?? false;
    } catch (_) {}
    if (mounted) setState(() => _loadingUser = false);
  }

  Future<void> _pickImage() async {
    final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 1600);
    if (x == null) return;
    try {
      setState(() => _pendingUploads.add('uploading'));
      final fileBytes = await x.readAsBytes();
      final name = 'msg_${DateTime.now().millisecondsSinceEpoch}_${x.name}';
      final ref = FirebaseStorage.instance.ref().child('support').child(_uid ?? 'anon').child(widget.ticketId).child(name);
      await ref.putData(fileBytes);
      final url = await ref.getDownloadURL();
      setState(() {
        _pendingUploads.remove('uploading');
        _pendingUploads.add(url);
      });
    } catch (e) {
      setState(() => _pendingUploads.remove('uploading'));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }
  }

  Future<void> _send() async {
    if (_uid == null || !_isPremium) return;
    final text = _msgCtrl.text.trim();
    if (text.isEmpty && _pendingUploads.isEmpty) return;
    setState(() => _sending = true);
    try {
      final attachments = _pendingUploads.where((e) => e != 'uploading').toList();
      await AdminService().addUserSupportMessage(widget.ticketId, text: text.isEmpty ? null : text, attachments: attachments.isEmpty ? null : attachments);
      _msgCtrl.clear();
      setState(() => _pendingUploads.clear());
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = (widget.ticketData['status'] as String?) ?? 'open';
    final closed = status == 'closed';
    return Scaffold(
      appBar: AppBar(title: Text(widget.ticketData['subject'] ?? 'Request')),
      body: Column(
        children: [
          _buildHeader(status),
          const Divider(height: 0),
          Expanded(child: _buildMessages()),
          if (!_loadingUser && _isPremium && !closed) _buildComposer() else if (closed) _buildClosedBanner(),
        ],
      ),
    );
  }

  Widget _buildHeader(String status) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.ticketData['message'] ?? '', style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          _statusChip(status),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('support').doc(widget.ticketId).collection('messages').orderBy('createdAt', descending: true).limit(200).snapshots(),
      builder: (c, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('No messages.'));
        }
        return ListView.builder(
          reverse: true,
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            final d = docs[i].data();
            final senderRole = (d['senderRole'] as String?) ?? 'user';
            final mine = d['senderId'] == _uid;
            final attachments = (d['attachments'] as List?)?.whereType<String>().toList() ?? [];
            return Align(
              alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                padding: const EdgeInsets.all(12),
                constraints: const BoxConstraints(maxWidth: 320),
                decoration: BoxDecoration(
                  color: mine ? Colors.teal.shade600 : (senderRole == 'admin' || senderRole == 'moderator' ? Colors.blueGrey.shade100 : Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if ((d['text'] as String?)?.isNotEmpty == true)
                      Text(
                        d['text'],
                        style: TextStyle(color: mine ? Colors.white : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.87)),
                      ),
                    if (attachments.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: attachments.map((u) => _thumb(u, mine)).toList(),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      _fmtTime(d['createdAt']),
                      style: TextStyle(fontSize: 10, color: mine ? Colors.white70 : Colors.black45),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _thumb(String url, bool mine) {
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
          color: mine ? Colors.white24 : Colors.black12,
          width: 72,
          height: 72,
          child: Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
        ),
      ),
    );
  }

  String _fmtTime(dynamic ts) {
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

  Widget _buildComposer() {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_pendingUploads.isNotEmpty)
            SizedBox(
              height: 90,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                scrollDirection: Axis.horizontal,
                itemCount: _pendingUploads.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (c, i) {
                  final u = _pendingUploads[i];
                  if (u == 'uploading') {
                    return const SizedBox(width:72,height:72,child: Center(child: CircularProgressIndicator(strokeWidth:2)));
                  }
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(u, width: 72, height: 72, fit: BoxFit.cover),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: GestureDetector(
                          onTap: () => setState(() => _pendingUploads.removeAt(i)),
                          child: Container(
                            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.all(2),
                            child: const Icon(Icons.close, color: Colors.white, size: 14),
                          ),
                        ),
                      )
                    ],
                  );
                },
              ),
            ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.photo),
                onPressed: _sending ? null : _pickImage,
              ),
              Expanded(
                child: TextField(
                  controller: _msgCtrl,
                  minLines: 1,
                  maxLines: 5,
                  decoration: const InputDecoration(hintText: 'Type a message...'),
                ),
              ),
              IconButton(
                icon: _sending ? const SizedBox(width:20,height:20,child: CircularProgressIndicator(strokeWidth:2)) : const Icon(Icons.send, color: Colors.teal),
                onPressed: _sending ? null : _send,
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClosedBanner() => Container(
    padding: const EdgeInsets.all(16),
    color: Colors.grey.shade200,
    child: const SafeArea(
      top: false,
      child: Text('Request is closed; new messages cannot be sent.', textAlign: TextAlign.center),
    ),
  );

  Widget _statusChip(String status) {
    Color c;
    switch (status) {
      case 'closed':
        c = Colors.green;
        break;
      case 'in_progress':
        c = Colors.orange;
        break;
      default:
        c = Colors.blueGrey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: c.withValues(alpha: .15), borderRadius: BorderRadius.circular(12)),
      child: Text(status, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
