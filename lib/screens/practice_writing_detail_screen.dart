// lib/screens/practice_writing_detail_screen.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lingua_chat/models/writing_models.dart';
import 'package:lingua_chat/repositories/writing_repository.dart';
import 'package:lingua_chat/services/writing_evaluator.dart';
import 'package:lingua_chat/services/writing_progress_service.dart';
import 'package:lingua_chat/services/translation_service.dart';

class PracticeWritingDetailScreen extends StatefulWidget {
  final String promptId;
  const PracticeWritingDetailScreen({super.key, required this.promptId});

  @override
  State<PracticeWritingDetailScreen> createState() => _PracticeWritingDetailScreenState();
}

class _PracticeWritingDetailScreenState extends State<PracticeWritingDetailScreen> {
  late WritingPrompt prompt;
  final _progress = WritingProgressService.instance;
  final _evaluator = WritingEvaluator.instance;
  final _controller = TextEditingController();
  Timer? _autosaveTimer;
  bool _loadingProgress = true;
  Map<String,dynamic> _progressData = {};
  WritingEvaluation? _evaluation;
  bool _evaluating = false;
  String _nativeLang = 'en';
  bool _showVocabTranslations = false;
  final Map<String,String> _vocabTranslations = {};
  bool _translatingVocab = false;

  @override
  void initState() {
    super.initState();
    prompt = WritingRepository.instance.byId(widget.promptId)!;
    _loadUserLang();
    _loadProgress();
    _controller.addListener(_scheduleAutosave);
  }

  Future<void> _loadUserLang() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final code = (snap.data()?['nativeLanguage'] as String?)?.trim();
        if (code!=null && code.isNotEmpty) {
          setState(()=>_nativeLang = code);
        }
      }
    } catch(_) {}
  }

  Future<void> _loadProgress() async {
    final data = await _progress.getPrompt(prompt.id);
    setState((){
      _progressData = data;
      final draft = data['draft'] as String?;
      if (draft!=null && draft.trim().isNotEmpty) {
        _controller.text = draft;
      }
      _loadingProgress = false;
    });
  }

  void _scheduleAutosave() {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(milliseconds: 900), _saveDraft);
    setState((){}); // kelime sayısı güncelleme vs.
  }
  Future<void> _saveDraft() async {
    final text = _controller.text.trim();
    await _progress.saveDraft(prompt.id, text);
  }

  int get _wordCount => _controller.text.trim().isEmpty ? 0 : _controller.text.trim().split(RegExp(r'\s+')).where((w)=>w.trim().isNotEmpty).length;

  Color _wordCountColor() {
    if (_wordCount==0) return Colors.grey;
    if (_wordCount < prompt.level.minWords) return Colors.redAccent;
    if (_wordCount > prompt.level.maxWords) return Colors.orange;
    return Colors.green;
  }

  Future<void> _evaluate() async {
    setState(()=>_evaluating=true);
    await Future.delayed(const Duration(milliseconds: 200));
    final ev = _evaluator.evaluate(_controller.text, prompt);
    setState((){ _evaluation = ev; _evaluating=false; });
  }

  Future<void> _submit() async {
    if (_controller.text.trim().isEmpty) return;
    if (_evaluation == null) {
      await _evaluate();
    }
    final ev = _evaluation!;
    await _progress.recordSubmission(id: prompt.id, text: _controller.text.trim(), score: ev.completionScore, wordCount: ev.wordCount);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gönderildi ve kaydedildi.')));
    _loadProgress();
  }

  Future<void> _toggleVocabTranslations() async {
    if (_nativeLang=='en') {
      setState(()=> _showVocabTranslations = !_showVocabTranslations);
      return;
    }
    if (_showVocabTranslations) { setState(()=> _showVocabTranslations = false); return; }
    setState(()=> _translatingVocab = true);
    try {
      await TranslationService.instance.ensureReady(_nativeLang);
      for (final w in prompt.targetVocab) {
        if (_vocabTranslations.containsKey(w)) continue;
        final tr = await TranslationService.instance.translateFromEnglish(w, _nativeLang);
        _vocabTranslations[w] = tr;
      }
      setState(()=> _showVocabTranslations = true);
    } catch(_) {} finally { if (mounted) setState(()=> _translatingVocab = false); }
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    _controller.removeListener(_scheduleAutosave);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bestScore = (_progressData['bestScore'] as num?)?.toDouble();
    return Scaffold(
      appBar: AppBar(
        title: Text(prompt.title),
        actions: [
          if (bestScore != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Chip(
                label: Text('En iyi: ${bestScore.toStringAsFixed(0)}'),
                backgroundColor: Colors.blue.withValues(alpha:.15),
              ),
            ),
        ],
      ),
      body: _loadingProgress ? const Center(child: CircularProgressIndicator()) : Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16,12,16,160),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PromptHeader(prompt: prompt, wordCount: _wordCount),
                  const SizedBox(height: 12),
                  _FocusPointsSection(prompt: prompt),
                  if (prompt.targetVocab.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _TargetVocabSection(
                      prompt: prompt,
                      showTranslations: _showVocabTranslations,
                      onToggle: _toggleVocabTranslations,
                      translations: _vocabTranslations,
                      loading: _translatingVocab,
                      nativeLang: _nativeLang,
                    ),
                  ],
                  if (prompt.sampleOutline != null) ...[
                    const SizedBox(height: 12),
                    _ExpandableCard(title: 'Önerilen Taslak', child: Text(prompt.sampleOutline!)),
                  ],
                  if (prompt.sampleAnswer != null) ...[
                    const SizedBox(height: 8),
                    _ExpandableCard(title: 'Örnek Cevap', child: Text(prompt.sampleAnswer!)),
                  ],
                  const SizedBox(height: 16),
                  _EditorCard(
                    controller: _controller,
                    minWords: prompt.level.minWords,
                    maxWords: prompt.level.maxWords,
                    wordCount: _wordCount,
                    color: _wordCountColor(),
                  ),
                  const SizedBox(height: 16),
                  _EvaluationArea(
                    evaluation: _evaluation,
                    evaluating: _evaluating,
                    onEvaluate: _evaluate,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    final canSubmit = _controller.text.trim().isNotEmpty;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16,10,16,12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:.07), blurRadius: 10, offset: const Offset(0,-2))],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _evaluating ? null : _evaluate,
                icon: const Icon(Icons.analytics_outlined),
                label: Text(_evaluation==null? 'Değerlendir' : 'Yeniden Değerlendir'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: canSubmit ? _submit : null,
                icon: const Icon(Icons.send_rounded),
                label: const Text('Gönder'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromptHeader extends StatelessWidget {
  final WritingPrompt prompt;
  final int wordCount;
  const _PromptHeader({required this.prompt, required this.wordCount});
  Color _levelColor(WritingLevel l) => switch (l) {
    WritingLevel.beginner => Colors.green,
    WritingLevel.intermediate => Colors.orange,
    WritingLevel.advanced => Colors.red,
  };
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal:12, vertical:6),
                  decoration: BoxDecoration(
                    color: _levelColor(prompt.level).withValues(alpha:.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(prompt.level.label, style: TextStyle(color: _levelColor(prompt.level), fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 8),
                Text(prompt.type.label, style: Theme.of(context).textTheme.bodySmall),
                const Spacer(),
                Text('Kelime: $wordCount', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 12),
            Text(prompt.instructions, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _FocusPointsSection extends StatelessWidget {
  final WritingPrompt prompt;
  const _FocusPointsSection({required this.prompt});
  @override
  Widget build(BuildContext context) {
    return _ExpandableCard(
      title: 'Dikkat Noktaları',
      initiallyExpanded: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final f in prompt.focusPoints)
            Padding(
              padding: const EdgeInsets.only(bottom:6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 16, height:1.3)),
                  Expanded(child: Text(f, style: const TextStyle(height:1.3))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TargetVocabSection extends StatelessWidget {
  final WritingPrompt prompt;
  final bool showTranslations;
  final VoidCallback onToggle;
  final Map<String,String> translations;
  final bool loading;
  final String nativeLang;
  const _TargetVocabSection({
    required this.prompt,
    required this.showTranslations,
    required this.onToggle,
    required this.translations,
    required this.loading,
    required this.nativeLang,
  });
  @override
  Widget build(BuildContext context) {
    return _ExpandableCard(
      title: 'Hedef Kelimeler',
      actions: [
        if (loading) const SizedBox(width:18, height:18, child: CircularProgressIndicator(strokeWidth:2))
        else TextButton(onPressed: onToggle, child: Text(showTranslations? 'Gizle' : (nativeLang=='en'? 'Göster' : 'Çevir'))) ,
      ],
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final w in prompt.targetVocab)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal:12, vertical:8),
              decoration: BoxDecoration(
                color: Colors.pink.withValues(alpha:.08),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.pink.withValues(alpha:.3)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(w, style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (showTranslations)
                    Text(
                      translations[w] ?? w,
                      style: TextStyle(fontSize: 11, color: Colors.pink.shade700),
                    )
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _EditorCard extends StatelessWidget {
  final TextEditingController controller;
  final int minWords;
  final int maxWords;
  final int wordCount;
  final Color color;
  const _EditorCard({
    required this.controller,
    required this.minWords,
    required this.maxWords,
    required this.wordCount,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16,12,16,16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Taslak', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('$wordCount kelime', style: TextStyle(color: color, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 160, maxHeight: 360),
              child: TextField(
                controller: controller,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: 'Buraya yaz...',
                  filled: true,
                  fillColor: Colors.pink.withValues(alpha:.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.pink.withValues(alpha:.2))),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text('Hedef: $minWords - $maxWords kelime', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _EvaluationArea extends StatelessWidget {
  final WritingEvaluation? evaluation;
  final bool evaluating;
  final VoidCallback onEvaluate;
  const _EvaluationArea({
    required this.evaluation,
    required this.evaluating,
    required this.onEvaluate,
  });
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Değerlendirme', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                if (evaluating) const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2))
                else IconButton(onPressed: onEvaluate, icon: const Icon(Icons.refresh)),
              ],
            ),
            const SizedBox(height: 12),
            if (evaluation == null && !evaluating)
              Text('Henüz değerlendirilmedi. "Değerlendir" butonu ile analiz al.' , style: Theme.of(context).textTheme.bodyMedium)
            else if (evaluation != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _MetricChip(label: 'Kelime', value: evaluation!.wordCount.toString()),
                      _MetricChip(label: 'Leksik Çeşitlilik', value: (evaluation!.lexicalDiversity*100).toStringAsFixed(1)+'%'),
                      _MetricChip(label: 'Ø Cümle Uz.', value: evaluation!.avgSentenceLength.toStringAsFixed(1)),
                      _MetricChip(label: 'Flesch', value: evaluation!.fleschReadingEase.toStringAsFixed(0)),
                      _MetricChip(label: 'Skor', value: evaluation!.completionScore.toStringAsFixed(0)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Öneriler', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ...evaluation!.suggestions.map((s)=> Padding(
                    padding: const EdgeInsets.only(bottom:6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• '),
                        Expanded(child: Text(s)),
                      ],
                    ),
                  )),
                  if (evaluation!.repeatedWords.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text('Sık Tekrarlar: '+evaluation!.repeatedWords.take(8).join(', '), style: Theme.of(context).textTheme.bodySmall),
                  ]
                ],
              )
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  const _MetricChip({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.indigo.withValues(alpha:.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.indigo.withValues(alpha:.35)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.indigo.shade700)),
        ],
      ),
    );
  }
}

class _ExpandableCard extends StatefulWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final bool initiallyExpanded;
  const _ExpandableCard({super.key, required this.title, required this.child, this.actions, this.initiallyExpanded=false});
  @override
  State<_ExpandableCard> createState() => _ExpandableCardState();
}
class _ExpandableCardState extends State<_ExpandableCard> with SingleTickerProviderStateMixin {
  late bool _expanded;
  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16,10,16,12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(widget.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                if (widget.actions != null) ...widget.actions!,
                IconButton(
                  onPressed: ()=> setState(()=> _expanded = !_expanded),
                  icon: AnimatedRotation(
                    turns: _expanded? .5: 0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(Icons.expand_more),
                  ),
                )
              ],
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: widget.child,
              crossFadeState: _expanded? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            )
          ],
        ),
      ),
    );
  }
}

