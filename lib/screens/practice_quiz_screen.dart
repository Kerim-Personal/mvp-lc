// lib/screens/practice_quiz_screen.dart

import 'package:flutter/material.dart';
import 'package:lingua_chat/models/quiz_question_model.dart';
import 'package:lingua_chat/screens/quiz_results_screen.dart';

class PracticeQuizScreen extends StatefulWidget {
  final String title;
  final Color themeColor;
  final List<QuizQuestion> questions;

  const PracticeQuizScreen({
    super.key,
    required this.title,
    required this.themeColor,
    required this.questions,
  });

  @override
  State<PracticeQuizScreen> createState() => _PracticeQuizScreenState();
}

class _PracticeQuizScreenState extends State<PracticeQuizScreen> {
  int _current = 0;
  int _score = 0;
  int? _selectedIndex;
  bool _locked = false;

  void _onSelect(int index) {
    if (_locked) return;
    setState(() {
      _selectedIndex = index;
      _locked = true;
      if (index == widget.questions[_current].correctAnswerIndex) {
        _score++;
      }
    });
  }

  void _next() {
    if (_current < widget.questions.length - 1) {
      setState(() {
        _current++;
        _selectedIndex = null;
        _locked = false;
      });
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => QuizResultsScreen(
            score: _score,
            totalQuestions: widget.questions.length,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.questions[_current];
    final progress = (_current + 1) / widget.questions.length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: widget.themeColor,
        foregroundColor: Colors.white,
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  color: widget.themeColor,
                  backgroundColor: widget.themeColor.withAlpha(38), // ~0.15
                ),
                const SizedBox(height: 16),
                Text(
                  'Soru ${_current + 1} / ${widget.questions.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  q.questionText,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: q.options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final isSelected = _selectedIndex == i;
                final isCorrect = i == q.correctAnswerIndex;
                Color? tileColor;
                Color borderColor = Colors.grey.shade300;
                if (_locked) {
                  if (isCorrect) {
                    tileColor = Colors.green.shade50;
                    borderColor = Colors.green;
                  } else if (isSelected && !isCorrect) {
                    tileColor = Colors.red.shade50;
                    borderColor = Colors.red;
                  }
                } else if (isSelected) {
                  tileColor = widget.themeColor.withAlpha(20); // ~0.08
                  borderColor = widget.themeColor;
                }

                return InkWell(
                  onTap: () => _onSelect(i),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: tileColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Text(q.options[i])),
                        if (_locked && isCorrect)
                          const Icon(Icons.check_circle, color: Colors.green)
                        else if (_locked && isSelected && !isCorrect)
                          const Icon(Icons.cancel, color: Colors.red)
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _locked ? _next : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.themeColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: Icon(
                    _current == widget.questions.length - 1
                        ? Icons.flag_circle_outlined
                        : Icons.arrow_forward_ios,
                  ),
                  label: Text(
                    _current == widget.questions.length - 1 ? 'Bitir' : 'Sonraki',
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
