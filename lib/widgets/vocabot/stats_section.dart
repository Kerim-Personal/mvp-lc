// lib/widgets/vocabot/stats_section.dart
import 'package:flutter/material.dart';
import 'package:vocachat/models/grammar_analysis.dart';

class StatsSection extends StatefulWidget {
  final GrammarAnalysis analysis;
  final Widget Function({required IconData icon, required Color color, required String title, required String value, String? subtitle}) statLineBuilder;
  const StatsSection({super.key, required this.analysis, required this.statLineBuilder});
  @override
  State<StatsSection> createState() => _StatsSectionState();
}

class _StatsSectionState extends State<StatsSection> {
  bool _expanded = false;

  String _sentimentLabel(double s){
    if(s>0.35) return 'positive';
    if(s<-0.35) return 'negative';
    return 'neutral';
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.analysis;
    final accPct = (a.grammarScore*100).toStringAsFixed(0);
    final compPct = (a.complexity*100).toStringAsFixed(0);
    final tone = _sentimentLabel(a.sentiment);
    final errors = a.errors.length;
    final formality = a.formality.name; // informal / neutral / formal
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
                widget.statLineBuilder(icon: Icons.score, color: Colors.cyanAccent, title:'Accuracy', value:'$accPct%'),
                widget.statLineBuilder(icon: Icons.error_outline, color: Colors.orangeAccent, title:'Errors', value:'$errors'),
                widget.statLineBuilder(icon: Icons.account_tree, color: Colors.purpleAccent, title:'Complexity', value:'$compPct%'),
                widget.statLineBuilder(icon: Icons.graphic_eq, color: Colors.greenAccent, title:'Tone', value:tone),
                widget.statLineBuilder(icon: Icons.theater_comedy, color: Colors.lightBlueAccent, title:'Formality', value: formality),
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
