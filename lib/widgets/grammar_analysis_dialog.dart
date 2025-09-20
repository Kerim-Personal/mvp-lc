// lib/widgets/grammar_analysis_dialog.dart

import 'package:flutter/material.dart';
import 'package:vocachat/models/grammar_analysis.dart';

void showGrammarAnalysisDialog(BuildContext context, GrammarAnalysis ga, String original) {
  String formalityText(Formality f) {
    switch (f) {
      case Formality.informal:
        return 'Samimi';
      case Formality.neutral:
        return 'Nötr';
      case Formality.formal:
        return 'Resmi';
    }
  }

  final maxH = MediaQuery.of(context).size.height * 0.7;
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.black.withValues(alpha: 0.85),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.cyanAccent.withValues(alpha: .4)),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH, minWidth: 300),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: const [
                    Icon(Icons.science_outlined, color: Colors.cyanAccent),
                    SizedBox(width: 8),
                    Text('Gramer Analizi',
                        style: TextStyle(
                            color: Colors.cyanAccent,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('"$original"',
                    style: const TextStyle(
                        color: Colors.white70, fontStyle: FontStyle.italic)),
                const Divider(color: Colors.cyanAccent, height: 22),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _pill(Icons.score, '${(ga.grammarScore * 100).toStringAsFixed(0)}%'),
                    _pill(Icons.school, ga.cefr),
                    _pill(Icons.access_time, ga.tense),
                    _pill(Icons.theater_comedy, formalityText(ga.formality)),
                    _pill(Icons.translate, 'N:${ga.nounCount}'),
                    _pill(Icons.text_rotation_none, 'V:${ga.verbCount}'),
                    _pill(Icons.color_lens, 'Adj:${ga.adjectiveCount}'),
                  ],
                ),
                const SizedBox(height: 12),
                if (ga.corrections.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.orangeAccent.withValues(alpha: .6)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.edit, color: Colors.orangeAccent, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                            children: [
                              ...ga.corrections.entries.take(1).map(
                                (e) => TextSpan(children: [
                                  TextSpan(
                                      text: e.key,
                                      style: const TextStyle(
                                          decoration:
                                              TextDecoration.lineThrough,
                                          color: Colors.redAccent)),
                                  const TextSpan(text: ' → '),
                                  TextSpan(
                                      text: e.value,
                                      style: const TextStyle(
                                          color: Colors.greenAccent,
                                          fontWeight: FontWeight.w600)),
                                ]),
                              )
                            ],
                          ),
                        ),
                      )
                    ]),
                  ),
                if (ga.errors.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.white24),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      iconColor: Colors.orangeAccent,
                      collapsedIconColor: Colors.orangeAccent,
                      title: const Text('Hatalar',
                          style: TextStyle(
                              color: Colors.orangeAccent,
                              fontWeight: FontWeight.bold)),
                      children: ga.errors.take(6).map((e) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12),
                                children: [
                                  TextSpan(
                                      text: '${e.type}: ',
                                      style: const TextStyle(
                                          color: Colors.cyanAccent)),
                                  TextSpan(
                                      text: e.original,
                                      style: const TextStyle(
                                          decoration:
                                              TextDecoration.lineThrough,
                                          color: Colors.redAccent)),
                                  const TextSpan(text: ' → '),
                                  TextSpan(
                                      text: e.correction,
                                      style: const TextStyle(
                                          color: Colors.greenAccent)),
                                  TextSpan(
                                      text: ' (${e.severity})\n',
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.white38)),
                                  TextSpan(
                                      text: e.explanation,
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.white54)),
                                ],
                              ),
                            ),
                          ))
                          .toList(),
                    ),
                  ),
                ],
                if (ga.suggestions.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.white24),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      iconColor: Colors.lightBlueAccent,
                      collapsedIconColor: Colors.lightBlueAccent,
                      title: const Text('Öneriler',
                          style: TextStyle(
                              color: Colors.lightBlueAccent,
                              fontWeight: FontWeight.bold)),
                      children: ga.suggestions
                          .take(6)
                          .map((s) => ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: const Text('•',
                                    style: TextStyle(
                                        color: Colors.lightBlueAccent)),
                                title: Text(s,
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 12)),
                              ))
                          .toList(),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Kapat'),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _pill(IconData i, String text) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.cyanAccent.withValues(alpha: .3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(i, size: 13, color: Colors.cyanAccent),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );

