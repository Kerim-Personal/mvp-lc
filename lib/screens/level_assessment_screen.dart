// lib/screens/level_assessment_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lingua_chat/screens/root_screen.dart'; // YÖNLENDİRME DEĞİŞTİ

// Sorular için basit bir veri modeli
class Question {
  final String questionText;
  final List<String> options;
  final int correctAnswerIndex;

  const Question({
    required this.questionText,
    required this.options,
    required this.correctAnswerIndex,
  });
}

class LevelAssessmentScreen extends StatefulWidget {
  const LevelAssessmentScreen({super.key});

  @override
  State<LevelAssessmentScreen> createState() => _LevelAssessmentScreenState();
}

class _LevelAssessmentScreenState extends State<LevelAssessmentScreen> {
  // TODO: Bu kısmı kendi sorularınızla güncelleyin
  final List<Question> _questions = List.generate(
    20,
        (index) => Question(
      questionText: 'Soru ${index + 1}: "Apple" kelimesinin Türkçe karşılığı nedir?',
      options: ['Armut', 'Elma', 'Çilek', 'Muz'],
      correctAnswerIndex: 1,
    ),
  );

  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _isLoading = false;

  void _answerQuestion(int selectedOptionIndex) {
    if (selectedOptionIndex == _questions[_currentQuestionIndex].correctAnswerIndex) {
      _score++;
    }

    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      _finishQuiz();
    }
  }

  String _calculateLevel(int score) {
    if (score <= 5) {
      return 'A1';
    } else if (score <= 8) {
      return 'A2';
    } else if (score <= 12) {
      return 'B1';
    } else if (score <= 16) {
      return 'B2';
    } else if (score <= 19) {
      return 'C1';
    } else {
      return 'C2';
    }
  }

  Future<void> _finishQuiz() async {
    setState(() {
      _isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final level = _calculateLevel(_score);
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'level': level,
        });
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const RootScreen()), // YÖNLENDİRME DEĞİŞTİ
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Seviyeniz kaydedilemedi: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    final currentQuestion = _questions[_currentQuestionIndex];
    return Scaffold(
      appBar: AppBar(
        title: Text('Seviye Belirleme Testi (${_currentQuestionIndex + 1}/20)'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Text(
              currentQuestion.questionText,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            ...List.generate(currentQuestion.options.length, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _answerQuestion(index),
                  child: Text(currentQuestion.options[index], style: const TextStyle(fontSize: 16)),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}