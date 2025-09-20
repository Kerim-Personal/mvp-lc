// lib/widgets/linguabot/message_insight_dialog.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:vocachat/models/grammar_analysis.dart';
import 'package:vocachat/models/message_unit.dart';
import 'package:vocachat/widgets/linguabot/metric_gauge.dart';
import 'package:vocachat/widgets/linguabot/stats_section.dart';

class MessageInsightDialog extends StatelessWidget {
  final MessageUnit message;
  final Function(String) onCorrect;

  const MessageInsightDialog({super.key, required this.message, required this.onCorrect});

  String _scoreLabel(double v){
    if(v>=0.9) return 'Near flawless';
    if(v>=0.75) return 'Very good';
    if(v>=0.6) return 'Good';
    if(v>=0.45) return 'Improving';
    if(v>=0.3) return 'Basic';
    return 'Beginner';
  }
  String _cefrExplain(String c){
    switch(c){
      case 'A1': return 'Basic beginner';
      case 'A2': return 'Expanding foundation';
      case 'B1': return 'Intermediate';
      case 'B2': return 'Upper intermediate';
      case 'C1': return 'Advanced';
      case 'C2': return 'Proficient';
      default: return c; }
  }
  String _formalityToString(Formality f){
    switch(f){
      case Formality.informal: return 'Informal';
      case Formality.neutral: return 'Neutral';
      case Formality.formal: return 'Formal';
    }
  }
  String _sentimentLabel(double s){
    if(s>0.35) return 'positive';
    if(s<-0.35) return 'negative';
    return 'neutral';
  }
  String _tenseExplain(String t){
    final l = t.toLowerCase();
    if(l.contains('present perfect continuous')) return 'Continuous action from the past up to now';
    if(l.contains('past perfect continuous')) return 'Long action continuing until a point in the past';
    if(l.contains('future perfect continuous')) return 'Will be continuing until a point in the future';
    if(l.contains('present perfect')) return 'Started in the past; result/effect now';
    if(l.contains('past perfect')) return 'Completed before another past action';
    if(l.contains('future perfect')) return 'Will be completed by a future time';
    if(l.contains('present continuous') || l.contains('present progressive')) return 'Happening right now';
    if(l.contains('past continuous') || l.contains('past progressive')) return 'Ongoing at a specific moment in the past';
    if(l.contains('future continuous') || l.contains('future progressive')) return 'Ongoing at a specific moment in the future';
    if(l.contains('simple present') || l== 'present simple' || (l.contains('present') && l.contains('simple'))) return 'General fact / habit';
    if(l.contains('simple past') || l== 'past simple' || (l.contains('past') && l.contains('simple'))) return 'Completed in the past';
    if(l.contains('simple future') || l== 'future simple' || (l.contains('future') && l.contains('simple'))) return 'Will occur in the future';
    if(l.contains('infinitive')) return 'Infinitive form';
    if(l.contains('imperative')) return 'Imperative mood';
    if(l.contains('conditional')) return 'Conditional structure';
    return t;
  }
  String _summaryText(GrammarAnalysis a){
    final percent = (a.grammarScore*100).round();
    final errorCount = a.errors.length;
    final errorPart = errorCount==0? 'No errors.' : errorCount==1? '1 error.' : '$errorCount errors.';
    final complexityPct = (a.complexity*100).round();
    final tenseShort = _tenseExplain(a.tense);
    final form = _formalityToString(a.formality);
    final cefrExp = _cefrExplain(a.cefr);
    final sentiment = _sentimentLabel(a.sentiment);
    return 'Level ${a.cefr} ($cefrExp), grammar accuracy $percent%. $errorPart\nTense: $tenseShort; form: $form; structural complexity $complexityPct%; sentiment: $sentiment.';
  }
  Widget _statLine({required IconData icon, required Color color, required String title, required String value, String? subtitle}){
    return Container(
      margin: const EdgeInsets.symmetric(vertical:4),
      padding: const EdgeInsets.symmetric(horizontal:14, vertical:10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(120)),
        gradient: LinearGradient(
          colors: [color.withAlpha(30), Colors.transparent],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size:18, color: color),
              const SizedBox(width:10),
              Expanded(child: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize:13))),
              Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize:13)),
            ],
          ),
          if(subtitle!=null) Padding(
            padding: const EdgeInsets.only(top:4, left:28),
            child: Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize:11, height:1.2)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final analysis = message.grammarAnalysis;
    final maxHeight = MediaQuery.of(context).size.height * 0.7;
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.black.withAlpha(191),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.cyan.withAlpha(128))),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight, minWidth: 280),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.science_outlined, color: Colors.cyanAccent),
                      SizedBox(width: 10),
                      Text("Message DNA", style: TextStyle(color: Colors.cyanAccent, fontSize: 22)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('"${message.text}"', style: const TextStyle(color: Colors.white, fontStyle: FontStyle.italic)),
                  const Divider(color: Colors.cyan, height: 20),

                  if (analysis != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha((255*0.05).round()),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.cyan.withAlpha((255*0.3).round())),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Overall Evaluation', style: TextStyle(color: Colors.cyanAccent.shade100, fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height:6),
                          Text(
                            _summaryText(analysis),
                            style: const TextStyle(color: Colors.white70, height:1.3),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height:14),
                    StatsSection(
                      analysis: analysis,
                      vocabRichness: message.vocabularyRichness,
                      scoreLabel: _scoreLabel,
                      cefrExplain: _cefrExplain,
                      tenseExplain: _tenseExplain,
                      formalityToString: _formalityToString,
                      statLineBuilder: ({required icon, required color, required title, required value, subtitle}) => _statLine(icon: icon, color: color, title: title, value: value, subtitle: subtitle),
                    ),
                    const SizedBox(height:18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: MetricGauge(label: "Vocabulary Variety", value: message.vocabularyRichness, color: Colors.amber)),
                        const SizedBox(width:12),
                        Expanded(child: MetricGauge(label: "Sentiment Tone", value: (analysis.sentiment + 1) / 2, color: Colors.green)),
                        const SizedBox(width:12),
                        Expanded(child: MetricGauge(label: "Structural Complexity", value: analysis.complexity, color: Colors.purpleAccent)),
                      ],
                    ),
                    const SizedBox(height:16),
                    if (analysis.corrections.isNotEmpty)
                      _buildCorrectionWidget(context, analysis.corrections.entries.first),
                    if (analysis.errors.isNotEmpty)
                      Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.white24),
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          iconColor: Colors.orangeAccent,
                          collapsedIconColor: Colors.orangeAccent,
                          title: const Text("Error Details", style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                          children: analysis.errors.take(6).map((e) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: RichText(
                              text: TextSpan(
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                                children: [
                                  TextSpan(text: "${e.type}: ", style: const TextStyle(color: Colors.cyanAccent)),
                                  TextSpan(text: e.original, style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.redAccent)),
                                  const TextSpan(text: " → "),
                                  TextSpan(text: e.correction, style: const TextStyle(color: Colors.greenAccent)),
                                  TextSpan(text: " (${e.severity})\n", style: const TextStyle(fontSize: 10, color: Colors.white38)),
                                  TextSpan(text: e.explanation, style: const TextStyle(fontSize: 10, color: Colors.white54)),
                                ],
                              ),
                            ),
                          )).toList(),
                        ),
                      ),
                    if (analysis.suggestions.isNotEmpty)
                      Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.white24),
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          iconColor: Colors.lightBlueAccent,
                          collapsedIconColor: Colors.lightBlueAccent,
                          title: const Text("Suggestions", style: TextStyle(color: Colors.lightBlueAccent, fontWeight: FontWeight.bold)),
                          children: analysis.suggestions.take(6).map((s) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const Text("•", style: TextStyle(color: Colors.lightBlueAccent)),
                            title: Text(s, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          )).toList(),
                        ),
                      ),
                  ],

                  const SizedBox(height: 10),
                  Center(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")))
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCorrectionWidget(BuildContext context, MapEntry<String, String> correction) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.orange.withAlpha(26),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orangeAccent.withAlpha(128))
      ),
      child: Row(
        children: [
          const Icon(Icons.edit, color: Colors.orangeAccent, size: 20),
            const SizedBox(width: 10),
            Expanded(child: RichText(text: TextSpan(
                style: const TextStyle(color: Colors.white, fontSize: 15),
                children: [
                  TextSpan(text: "${correction.key} ", style: const TextStyle(decoration: TextDecoration.lineThrough)),
                  const TextSpan(text: " instead of "),
                  TextSpan(text: correction.value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orangeAccent))
                ]
            ))),
            IconButton(
              icon: const Icon(Icons.task_alt, color: Colors.greenAccent),
              onPressed: () {
                final wrong = correction.key.trim();
                if (wrong.isEmpty) return;
                final pattern = RegExp(r'\b' + RegExp.escape(wrong) + r'\b');
                final newText = message.text.replaceAll(pattern, correction.value);
                onCorrect(newText);
                Navigator.pop(context);
              },
              tooltip: "Apply",
            )
        ],
      ),
    );
  }
}

