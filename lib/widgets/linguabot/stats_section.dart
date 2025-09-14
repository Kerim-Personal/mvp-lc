// lib/widgets/linguabot/stats_section.dart
import 'package:flutter/material.dart';
import 'package:lingua_chat/models/grammar_analysis.dart';

class StatsSection extends StatefulWidget {
  final GrammarAnalysis analysis;
  final double vocabRichness;
  final String Function(double) scoreLabel;
  final String Function(String) cefrExplain;
  final String Function(String) tenseExplain;
  final String Function(Formality) formalityToString;
  final Widget Function({required IconData icon, required Color color, required String title, required String value, String? subtitle}) statLineBuilder;
  const StatsSection({super.key, required this.analysis, required this.vocabRichness, required this.scoreLabel, required this.cefrExplain, required this.tenseExplain, required this.formalityToString, required this.statLineBuilder});
  @override
  State<StatsSection> createState() => _StatsSectionState();
}

class _StatsSectionState extends State<StatsSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.analysis;
    return Container(
      margin: const EdgeInsets.only(top:4),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(()=> _expanded = !_expanded),
            child: Row(
              children: [
                Icon(_expanded? Icons.expand_less : Icons.expand_more, color: Colors.cyanAccent, size:20),
                const SizedBox(width:6),
                Text(_expanded? 'Hide Metrics' : 'Show Metrics', style: const TextStyle(color: Colors.cyanAccent, fontSize:12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                const SizedBox(height:6),
                widget.statLineBuilder(icon: Icons.score, color: Colors.cyanAccent, title:'Grammar Score', value:'${(a.grammarScore*100).toStringAsFixed(0)}%', subtitle: widget.scoreLabel(a.grammarScore)),
                widget.statLineBuilder(icon: Icons.school, color: Colors.amber, title:'CEFR', value: a.cefr, subtitle: widget.cefrExplain(a.cefr)),
                widget.statLineBuilder(icon: Icons.access_time, color: Colors.lightBlueAccent, title:'Tense', value: a.tense, subtitle: widget.tenseExplain(a.tense)),
                widget.statLineBuilder(icon: Icons.theater_comedy, color: Colors.purpleAccent, title:'Formality', value: widget.formalityToString(a.formality)),
                widget.statLineBuilder(icon: Icons.article_outlined, color: Colors.greenAccent, title:'Word Types', value:'${a.nounCount}/${a.verbCount}/${a.adjectiveCount}', subtitle: 'Noun / Verb / Adjective'),
              ],
            ),
            crossFadeState: _expanded? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds:300),
          )
        ],
      ),
    );
  }
}

