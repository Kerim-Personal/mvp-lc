// lib/screens/report_user_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

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

  // Rapor nedenleri listesi
  final List<String> _reportReasons = const [
    'Cheating / Unfair Advantage',
    'Inappropriate Username',
    'Impersonation',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    // Artık Firestore’dan kontrol yapmıyoruz; fonksiyon hatası üzerinden yöneteceğiz
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

    setState(() { _isSubmitting = true; });

    try {
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final createReport = functions.httpsCallable('createReport');
      final String reason = (_reasonController.text).trim();
      final String details = _detailsController.text.trim();

      await createReport.call({
        'reportedUserId': widget.reportedUserId,
        'reason': reason,
        'details': details.isEmpty ? null : details,
        'reportedContent': widget.reportedContent,
        'reportedContentId': widget.reportedContentId,
        'reportedContentType': widget.reportedContentType,
        'reportedContentParentId': widget.reportedContentParentId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Your report has been submitted for review.'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } on FirebaseFunctionsException catch (e) {
      // createReport sunucu tarafı hataları: already-exists, resource-exhausted, invalid-argument vb.
      String msg = 'An error occurred while submitting the report.';
      if (e.code == 'already-exists') {
        msg = 'You have already reported this content.';
        setState(() => _alreadyReported = true);
      } else if (e.code == 'resource-exhausted') {
        msg = 'You are reporting too fast. Please wait and try again.';
      } else if (e.code == 'invalid-argument') {
        msg = 'Please provide a valid reason (max length limits apply).';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('An unexpected error occurred: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() { _isSubmitting = false; });
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
      appBar: AppBar(
        title: const Text('Report User'),
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
