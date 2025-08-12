// lib/screens/saturday_quiz_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lingua_chat/data/saturday_quiz_questions.dart';
import 'package:lingua_chat/models/quiz_question_model.dart';
import 'package:lingua_chat/screens/quiz_results_screen.dart';

class SaturdayQuizScreen extends StatefulWidget {
  const SaturdayQuizScreen({super.key});

  @override
  State<SaturdayQuizScreen> createState() => _SaturdayQuizScreenState();
}

enum QuizState { waiting, countdown, inProgress, finished }

class _SaturdayQuizScreenState extends State<SaturdayQuizScreen> {
  QuizState _quizState = QuizState.waiting;
  Timer? _timer;
  int _countdown = 60;
  int _currentQuestionIndex = 0;
  int _questionTimeLeft = 20;
  int _totalScore = 0;
  List<QuizQuestion> _questions = [];
  int? _selectedOptionIndex;

  @override
  void initState() {
    super.initState();
    _questions = (saturdayQuizQuestions..shuffle()).take(20).toList();
    _initializeQuiz();
  }

  void _initializeQuiz() {
    final now = DateTime.now();
    if (now.weekday == DateTime.saturday && now.hour >= 20) {
      // Eğer Cumartesi ve saat 20.00 veya sonrasıysa, doğrudan başlat
      _startCountdown();
    } else {
      // Değilse, bekleme modunda kal
      _quizState = QuizState.waiting;
      // Gerçek zamanlı kontrol için periyodik bir zamanlayıcı ayarla
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final currentTime = DateTime.now();
        if (currentTime.weekday == DateTime.saturday && currentTime.hour >= 20) {
          timer.cancel();
          _startCountdown();
        }
      });
    }
  }

  void _startCountdown() {
    setState(() => _quizState = QuizState.countdown);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
        _startQuiz();
      }
    });
  }

  void _startQuiz() {
    setState(() => _quizState = QuizState.inProgress);
    _askQuestion();
  }

  void _askQuestion() {
    setState(() {
      _questionTimeLeft = 20;
      _selectedOptionIndex = null;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_questionTimeLeft > 0) {
        setState(() => _questionTimeLeft--);
      } else {
        _nextQuestion();
      }
    });
  }

  void _answerQuestion(int optionIndex) {
    if (_selectedOptionIndex != null) return; // Zaten cevaplandıysa tekrar işlem yapma

    _timer?.cancel();
    final question = _questions[_currentQuestionIndex];
    if (optionIndex == question.correctAnswerIndex) {
      // Puanlama: Kalan süre x 10 (Ör: 15 saniye kala cevap = 150 puan)
      _totalScore += _questionTimeLeft * 10;
    }
    setState(() => _selectedOptionIndex = optionIndex);
    // Cevap verdikten sonra 2 saniye bekle ve sonraki soruya geç
    Future.delayed(const Duration(seconds: 2), _nextQuestion);
  }

  void _nextQuestion() {
    _timer?.cancel();
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() => _currentQuestionIndex++);
      _askQuestion();
    } else {
      _finishQuiz();
    }
  }

  void _finishQuiz() {
    setState(() => _quizState = QuizState.finished);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => QuizResultsScreen(
          score: _totalScore,
          totalQuestions: _questions.length,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
        child: Center(
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_quizState) {
      case QuizState.waiting:
        return _buildWaitingRoom();
      case QuizState.countdown:
        return _buildCountdown();
      case QuizState.inProgress:
        return _buildQuestionView();
      default:
        return const CircularProgressIndicator(color: Colors.white);
    }
  }

  Widget _buildWaitingRoom() {
    return const Padding(
      padding: EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hourglass_top, color: Colors.white, size: 80),
          SizedBox(height: 20),
          Text(
            'Haftalık Yarışma',
            style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            'Yarışma her Cumartesi 20:00\'de başlar. Lütfen beklemede kalın.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdown() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Yarışma Başlıyor!',
          style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 20),
        Text(
          '$_countdown',
          style: TextStyle(fontSize: 96, color: Colors.amber, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildQuestionView() {
    final question = _questions[_currentQuestionIndex];
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Soru Sayacı ve Zaman
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Soru ${_currentQuestionIndex + 1}/${_questions.length}',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              Row(
                children: [
                  Icon(Icons.timer_outlined, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '$_questionTimeLeft s',
                    style: const TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Soru Metni
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
          // Seçenekler
          ...List.generate(question.options.length, (index) {
            Color buttonColor = Colors.white.withOpacity(0.2);
            if (_selectedOptionIndex != null) {
              if (index == question.correctAnswerIndex) {
                buttonColor = Colors.green;
              } else if (index == _selectedOptionIndex) {
                buttonColor = Colors.red;
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
                onPressed: () => _answerQuestion(index),
                child: Text(question.options[index], style: const TextStyle(fontSize: 18)),
              ),
            );
          }),
        ],
      ),
    );
  }
}