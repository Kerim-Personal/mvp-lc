// lib/screens/saturday_quiz_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lingua_chat/models/quiz_question_model.dart';
import 'package:lingua_chat/screens/quiz_results_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SaturdayQuizScreen extends StatefulWidget {
  const SaturdayQuizScreen({super.key});

  @override
  State<SaturdayQuizScreen> createState() => _SaturdayQuizScreenState();
}

class _SaturdayQuizScreenState extends State<SaturdayQuizScreen> {
  final DocumentReference _quizRef =
  FirebaseFirestore.instance.collection('quizzes').doc('active_quiz');
  final _currentUser = FirebaseAuth.instance.currentUser;

  int _totalScore = 0;
  final Set<int> _answeredQuestions = {};

  Future<void> _answerQuestion(
      int questionIndex, int selectedOption, int correctAnswer, int timeLeft) async {
    if (_currentUser == null || _answeredQuestions.contains(questionIndex)) return;

    setState(() {
      _answeredQuestions.add(questionIndex);
    });

    final isCorrect = selectedOption == correctAnswer;
    int score = isCorrect ? (timeLeft * 10) : 0;

    if (isCorrect) {
      _totalScore += score;
    }

    await _quizRef
        .collection('answers')
        .doc('${_currentUser!.uid}_$questionIndex')
        .set({
      'userId': _currentUser!.uid,
      'answerIndex': selectedOption,
      'isCorrect': isCorrect,
      'score': score,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade700, Colors.indigo.shade900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: StreamBuilder<DocumentSnapshot>(
          stream: _quizRef.snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return _buildWaitingRoom('Yarışma verileri bekleniyor...');
            }

            final quizData = snapshot.data!.data() as Map<String, dynamic>;
            final status = quizData['status'] ?? 'waiting';

            switch (status) {
              case 'countdown':
                return _buildCountdown(quizData['countdown'] ?? 10);
              case 'in_progress':
              // *** ÖNEMLİ DEĞİŞİKLİK: 'key' EKLENDİ ***
                return _buildQuestionView(
                    key: ValueKey(quizData['currentQuestionIndex']),
                    quizData: quizData
                );
              case 'finished':
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => QuizResultsScreen(
                              score: _totalScore,
                              totalQuestions: quizData['totalQuestions'] ?? 20)),
                    );
                  }
                });
                return const Center(child: Text('Yarışma Bitti!', style: TextStyle(color: Colors.white, fontSize: 32)));
              case 'waiting':
              default:
                return _buildWaitingRoom(
                    'Yarışma her Cumartesi 20:00\'de başlar. Lütfen beklemede kalın.');
            }
          },
        ),
      ),
    );
  }

  Widget _buildQuestionView({Key? key, required Map<String, dynamic> quizData}) {
    final int questionIndex = quizData['currentQuestionIndex'];
    final Timestamp endTime = quizData['questionEndTime'];

    final Stream<int> timerStream = Stream.periodic(const Duration(seconds: 1), (i) {
      final remaining = endTime.seconds - Timestamp.now().seconds;
      return remaining > 0 ? remaining : 0;
    }).takeWhile((remaining) => remaining >= 0);

    return FutureBuilder<DocumentSnapshot>(
      key: key, // Bu key, widget'ın yeniden oluşmasını sağlar
      future: _quizRef.collection('questions').doc(questionIndex.toString()).get(),
      builder: (context, questionSnapshot) {
        if (!questionSnapshot.hasData || !questionSnapshot.data!.exists) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }

        final questionData = questionSnapshot.data!.data() as Map<String, dynamic>;
        final question = QuizQuestion(
          questionText: questionData['questionText'],
          options: List<String>.from(questionData['options']),
          correctAnswerIndex: questionData['correctAnswerIndex'],
        );

        final bool isAnswered = _answeredQuestions.contains(questionIndex);

        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Soru ${questionIndex + 1}/${quizData['totalQuestions']}',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  StreamBuilder<int>(
                      stream: timerStream,
                      builder: (context, snapshot) {
                        final timeLeft = snapshot.data ?? 0;
                        return Row(
                          children: [
                            Icon(Icons.timer_outlined, color: timeLeft > 5 ? Colors.amber : Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '$timeLeft s',
                              style: TextStyle(color: timeLeft > 5 ? Colors.amber : Colors.red, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        );
                      }
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  question.questionText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 30),
              // Cevap seçenekleri
              ...List.generate(question.options.length, (index) {
                Color buttonColor = Colors.white.withOpacity(0.2);

                if (isAnswered) {
                  if (index == question.correctAnswerIndex) {
                    buttonColor = Colors.green;
                  } else {
                    buttonColor = Colors.red.withOpacity(0.5);
                  }
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: isAnswered ? null : () {
                      final timeLeft = endTime.seconds - Timestamp.now().seconds;
                      _answerQuestion(questionIndex, index, question.correctAnswerIndex, timeLeft);
                    },
                    child: Text(question.options[index], style: const TextStyle(fontSize: 18)),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWaitingRoom(String text) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.hourglass_top, color: Colors.white, size: 80),
          const SizedBox(height: 20),
          const Text('Haftalık Yarışma', style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildCountdown(int count) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Yarışma Başlıyor!', style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Text('$count', style: const TextStyle(fontSize: 96, color: Colors.amber, fontWeight: FontWeight.bold)),
      ],
    );
  }
}