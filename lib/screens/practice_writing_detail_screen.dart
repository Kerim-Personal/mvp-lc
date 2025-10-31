// lib/screens/practice_writing_detail_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vocachat/models/writing_models.dart';
import 'package:vocachat/repositories/writing_repository.dart';
import 'package:vocachat/screens/writing_analysis_screen.dart';
import 'dart:convert';

class PracticeWritingDetailScreen extends StatefulWidget {
  final String taskId;
  const PracticeWritingDetailScreen({super.key, required this.taskId});

  @override
  State<PracticeWritingDetailScreen> createState() => _PracticeWritingDetailScreenState();
}

class _PracticeWritingDetailScreenState extends State<PracticeWritingDetailScreen> {
  final _controller = TextEditingController();
  final _repo = WritingRepository.instance;
  late WritingTask task;
  bool _checking = false;
  WritingAnalysis? _analysis;
  String _targetLanguage = 'en';
  String _nativeLanguage = 'tr';

  @override
  void initState() {
    super.initState();
    task = _repo.getTaskById(widget.taskId)!;
    _loadUserLanguages();
    _controller.addListener(() => setState(() {}));
  }

  Future<void> _loadUserLanguages() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final data = snap.data();
        setState(() {
          _targetLanguage = data?['targetLanguage'] as String? ?? 'en';
          _nativeLanguage = data?['nativeLanguage'] as String? ?? 'tr';
        });
      }
    } catch (_) {}
  }

  int get _charCount => _controller.text.length;

  Color _charCountColor() {
    final minChars = task.level.minChars;
    if (_charCount == 0) return Colors.grey;
    if (_charCount < minChars) return Colors.orange;
    return Colors.green;
  }

  Future<void> _checkWriting() async {
    if (_controller.text.trim().length < task.level.minChars) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You must write at least ${task.level.minChars} characters.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _checking = true);

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('aiWritingCheck');
      final result = await callable.call({
        'text': _controller.text.trim(),
        'task': task.task,
        'targetLanguage': _targetLanguage,
        'nativeLanguage': _nativeLanguage,
      });

      // Cloud Functions yanıtını sağlam şekilde parse et (String/Map desteği)
      Map<String, dynamic> topLevel;
      final raw = result.data;
      if (raw is String) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          topLevel = Map<String, dynamic>.from(decoded);
        } else {
          throw Exception('Invalid response');
        }
      } else if (raw is Map) {
        topLevel = Map<String, dynamic>.from(raw);
      } else {
        throw Exception('Invalid response type');
      }

      Map<String, dynamic> analysisData;
      final a = topLevel['analysis'];
      if (a == null) {
        // Bazı modeller direkt analizi döndürebilir
        analysisData = topLevel;
      } else if (a is String) {
        final decA = jsonDecode(a);
        if (decA is Map) {
          analysisData = Map<String, dynamic>.from(decA);
        } else {
          throw Exception('Invalid analysis payload');
        }
      } else if (a is Map) {
        analysisData = Map<String, dynamic>.from(a);
      } else {
        throw Exception('Unexpected analysis format');
      }

      setState(() {
        _analysis = WritingAnalysis.fromJson(analysisData);
        _checking = false;
      });

      // Analiz sonuçlarını yeni sayfada göster
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => WritingAnalysisScreen(
              analysis: _analysis!,
              task: task,
              userText: _controller.text.trim(),
              onEditAgain: () {
                // Kullanıcı düzenle butonuna basarsa hiçbir şey yapma
                // Zaten önceki sayfaya dönecek
              },
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _checking = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analysis error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minChars = task.level.minChars;
    final canCheck = _charCount >= minChars && !_checking;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(task.level.icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(task.level.label, style: const TextStyle(fontSize: 16)),
          ],
        ),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.03),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Görev kartı - Kompakt
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.indigo.shade400,
                            Colors.indigo.shade600,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.indigo.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(task.emoji, style: const TextStyle(fontSize: 24)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  task.level.label,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.edit, color: Colors.white, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Min: $minChars',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            task.task,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Yazı alanı - Kompakt
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.create, color: Colors.blue, size: 16),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Your Writing',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _charCountColor().withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _charCountColor().withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.edit,
                                        size: 12,
                                        color: _charCountColor(),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$_charCount/$minChars',
                                        style: TextStyle(
                                          color: _charCountColor(),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_charCount > 0)
                                  IconButton(
                                    onPressed: () {
                                      _controller.clear();
                                      setState(() => _analysis = null);
                                    },
                                    icon: const Icon(Icons.delete_outline, size: 20),
                                    tooltip: 'Clear',
                                    color: Colors.red,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _charCountColor().withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: TextField(
                                controller: _controller,
                                maxLines: 8,
                                style: const TextStyle(fontSize: 14, height: 1.5),
                                decoration: InputDecoration(
                                  hintText: 'Write here...',
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.all(12),
                                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Check butonu - Sabit alt kısım
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: canCheck
                        ? LinearGradient(
                            colors: [
                              Colors.green.shade400,
                              Colors.green.shade600,
                            ],
                          )
                        : null,
                    color: canCheck ? null : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: canCheck
                        ? [
                            BoxShadow(
                              color: Colors.green.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : [],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: canCheck ? _checkWriting : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_checking)
                              const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            else
                              Icon(
                                Icons.check_circle_outline,
                                color: canCheck ? Colors.white : Colors.grey.shade600,
                                size: 24,
                              ),
                            const SizedBox(width: 10),
                            Text(
                              _checking ? 'Analyzing...' : 'Check',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: canCheck ? Colors.white : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
