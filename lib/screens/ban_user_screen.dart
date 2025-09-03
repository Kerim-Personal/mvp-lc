// lib/screens/ban_user_screen.dart
import 'package:flutter/material.dart';
import 'package:lingua_chat/services/admin_service.dart';

class BanUserScreen extends StatefulWidget {
  final String targetUserId;
  const BanUserScreen({super.key, required this.targetUserId});

  @override
  State<BanUserScreen> createState() => _BanUserScreenState();
}

class _BanUserScreenState extends State<BanUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  bool _isSubmitting = false;
  String? _selectedReason; // secili sebep

  final List<String> _reasons = const [
    'Harassment, bullying, or threats',
    'Hate speech / discrimination',
    'Violence or dangerous behavior',
    'Sexual inappropriateness',
    'Spam, fraud, or impersonation',
    'Other',
  ];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await AdminService().banUser(
        widget.targetUserId,
        reason: _reasonController.text.trim(),
        details: _detailsController.text.trim().isEmpty ? null : _detailsController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User banned.'), backgroundColor: Colors.red),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ban failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showReasonSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                height: 4,
                width: 42,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal:16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Select Ban Reason', style: Theme.of(context).textTheme.titleMedium),
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _reasons.length,
                  itemBuilder: (c, i) {
                    final reason = _reasons[i];
                    final selected = reason == _selectedReason;
                    return ListTile(
                      title: Text(reason),
                      trailing: selected ? const Icon(Icons.check, color: Colors.red) : null,
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
              const SizedBox(height: 8),
            ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ban Account')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _reasonController,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Ban Reason', suffixIcon: Icon(Icons.arrow_drop_down)),
                onTap: _showReasonSheet,
                validator: (v) => (v == null || v.isEmpty) ? 'Please select a reason' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _detailsController,
                decoration: const InputDecoration(labelText: 'Details (optional)'),
                minLines: 2,
                maxLines: 5,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48), backgroundColor: Colors.red),
                  child: _isSubmitting ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) : const Text('Ban', style: TextStyle(color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}