// lib/screens/report_user_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportUserScreen extends StatefulWidget {
  final String reportedUserId;
  final String? reportedContent;
  final String? reportedContentId; // içerik ID
  final String? reportedContentType; // 'post', 'group_message' vb.
  final String? reportedContentParentId; // group room id gibi üst id

  const ReportUserScreen({
    super.key,
    required this.reportedUserId,
    this.reportedContent,
    this.reportedContentId,
    this.reportedContentType,
    this.reportedContentParentId,
  });

  @override
  State<ReportUserScreen> createState() => _ReportUserScreenState();
}

class _ReportUserScreenState extends State<ReportUserScreen> {
  String? _selectedReason;
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  bool _isSubmitting = false;
  final _currentUser = FirebaseAuth.instance.currentUser;
  final _formKey = GlobalKey<FormState>();
  bool _alreadyReported = false; // aynı kullanıcı aynı içeriği raporladı mı?

  // Eksik olan rapor nedenleri listesi geri eklendi
  final List<String> _reportReasons = const [
    'Cheating / Unfair Advantage',
    'Inappropriate Username',
    'Impersonation',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _checkAlreadyReported();
  }

  Future<void> _checkAlreadyReported() async {
    if (_currentUser == null) return;
    final cid = widget.reportedContentId;
    if (cid == null || cid.isEmpty) return; // içerik ID yoksa bloklama yapma
    try {
      final docId = '${_currentUser.uid}_$cid';
      final doc = await FirebaseFirestore.instance.collection('reports').doc(docId).get();
      if (mounted && doc.exists) {
        setState(() => _alreadyReported = true);
      }
    } catch (_) {
      // sessiz geç
    }
  }

  Future<void> _submitReport() async {
    if (_alreadyReported) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have already reported this content.')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('You must be signed in to submit a report.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    // Yarış durumunu önlemek için doc id temelli kontrol
    String? fixedDocId;
    if (widget.reportedContentId != null && widget.reportedContentId!.isNotEmpty) {
      fixedDocId = '${_currentUser.uid}_${widget.reportedContentId}';
      try {
        final existing = await FirebaseFirestore.instance.collection('reports').doc(fixedDocId).get();
        if (existing.exists) {
          setState(() => _alreadyReported = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You have already reported this content.')),
          );
          return;
        }
      } catch (_) {}
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final col = FirebaseFirestore.instance.collection('reports');
      if (fixedDocId != null) {
        await col.doc(fixedDocId).set({
          'reporterId': _currentUser.uid,
          'reportedUserId': widget.reportedUserId,
          'reason': _selectedReason,
          'details': _detailsController.text.trim(),
          'reportedContent': widget.reportedContent,
          'reportedContentId': widget.reportedContentId,
          'reportedContentType': widget.reportedContentType,
          'reportedContentParentId': widget.reportedContentParentId,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'pending',
        });
      } else {
        await col.add({
          'reporterId': _currentUser.uid,
          'reportedUserId': widget.reportedUserId,
          'reason': _selectedReason,
          'details': _detailsController.text.trim(),
          'reportedContent': widget.reportedContent,
          'reportedContentId': widget.reportedContentId,
            'reportedContentType': widget.reportedContentType,
            'reportedContentParentId': widget.reportedContentParentId,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'pending',
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Your report has been submitted for review.'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('An error occurred while submitting the report: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showReportReasonsModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Select a Report Reason',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const Divider(height: 1),
            LimitedBox(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _reportReasons.length,
                itemBuilder: (context, index) {
                  final reason = _reportReasons[index];
                  return ListTile(
                    title: Text(reason),
                    onTap: () {
                      setState(() {
                        _selectedReason = reason;
                        _reasonController.text = reason;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _detailsController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textMuted = theme.colorScheme.onSurface.withOpacity(0.65);
    return Scaffold(
      // backgroundColor sabit açık renkten tema varsayılana bırakıldı
      // backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Report User'),
        // backgroundColor ve foregroundColor sabit zorlamalardan arındırıldı, tema kendi uygular
        // backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? Colors.white,
        // foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 1,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                children: [
                  if (_alreadyReported)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(.12),
                        border: Border.all(color: Colors.orangeAccent.withOpacity(.5)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orangeAccent),
                          SizedBox(width: 8),
                          Expanded(child: Text('You already reported this content. No need to submit again.')),
                        ],
                      ),
                    ),
                  Icon(Icons.report_problem_outlined, color: theme.colorScheme.error, size: 60),
                  const SizedBox(height: 16),
                  Text(
                    'Report Community Guidelines Violation',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Select the most accurate reason (e.g. cheating, inappropriate name, impersonation). This action cannot be undone.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(color: textMuted),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _reasonController,
                    readOnly: true,
                    onTap: _showReportReasonsModal,
                    decoration: InputDecoration(
                      labelText: 'Report Reason',
                      suffixIcon: const Icon(Icons.arrow_drop_down),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) => (value == null || value.isEmpty) ? 'Please select a reason.' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _detailsController,
                    decoration: InputDecoration(
                      labelText: 'Additional Details (Optional)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton(
                onPressed: (_isSubmitting || _alreadyReported) ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Text(
                        'Submit Report',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
