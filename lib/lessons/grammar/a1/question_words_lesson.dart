import 'package:flutter/material.dart';
import 'dart:async';

// --- ANA DERS EKRANI ---
class QuestionWordsLessonScreen extends StatefulWidget {
  const QuestionWordsLessonScreen({super.key});

  @override
  State<QuestionWordsLessonScreen> createState() =>
      _QuestionWordsLessonScreenState();
}

class _QuestionWordsLessonScreenState extends State<QuestionWordsLessonScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 220.0,
            stretch: true,
            pinned: true,
            backgroundColor: Colors.blue.shade700,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: const Text('Question Words',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.blue.shade500, Colors.cyan.shade500],
                  ),
                ),
                child: const Center(
                  child:
                  Icon(Icons.quiz_outlined, size: 80, color: Colors.white24),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _AnimatedLessonBlock(
                  controller: _controller,
                  interval: const Interval(0.1, 0.7),
                  child: const _LessonBlock(
                    icon: Icons.help_outline,
                    title: 'Soruların Anahtarı: 5W1H',
                    content:
                    "İngilizcede bilgi almak için kullandığımız sihirli kelimelere hoş geldin! 'What, Where, When, Who, Why' ve 'How' (5W1H) olarak bilinen bu kelimeler, merak ettiklerimizi sormamızı sağlar. Onlar olmadan sohbetler eksik kalırdı!",
                  ),
                ),
                _AnimatedLessonBlock(
                  controller: _controller,
                  interval: const Interval(0.2, 0.8),
                  child: _ExampleCard(
                    title: 'Her Soru Farklı Bir Kapıyı Açar',
                    examples: [
                      Example(
                          icon: Icons.person_search_outlined,
                          category: 'Who:',
                          sentence: 'Asks about a person.'),
                      Example(
                          icon: Icons.location_searching_outlined,
                          category: 'Where:',
                          sentence: 'Asks about a place.'),
                      Example(
                          icon: Icons.event_note_outlined,
                          category: 'When:',
                          sentence: 'Asks about a time.'),
                    ],
                  ),
                ),
                _AnimatedLessonBlock(
                  controller: _controller,
                  interval: const Interval(0.3, 0.9),
                  child: _ExampleTable(
                    title: 'Soru Kelimeleri ve Anlamları',
                    headers: const ['Kelime', 'Ne Sorar?', 'Örnek Cümle'],
                    rows: const [
                      ['What', 'Nesne/Fikir/Eylem', 'What is your name?'],
                      ['Where', 'Yer/Konum', 'Where do you live?'],
                      ['When', 'Zaman', 'When is the party?'],
                      ['Who', 'Kişi', 'Who is that boy?'],
                      ['Why', 'Sebep', 'Why are you late?'],
                      ['How', 'Yol/Durum', 'How are you?'],
                    ],
                  ),
                ),
                _AnimatedLessonBlock(
                  controller: _controller,
                  interval: const Interval(0.4, 1.0),
                  child: _ExampleTable(
                    title: 'Cümle Yapısı: Soru + Yardımcı Fiil',
                    headers: const ['Soru Kelimesi', 'Yardımcı Fiil', 'Özne', 'Ana Fiil'],
                    rows: const [
                      ['Where', 'do', 'you', 'work?'],
                      ['What', 'is', 'she', 'doing?'],
                      ['When', 'did', 'they', 'arrive?'],
                    ],
                  ),
                ),
                _AnimatedLessonBlock(
                  controller: _controller,
                  interval: const Interval(0.6, 1.0),
                  child: const _TipCard(
                    title: 'Profesyonel Taktikler',
                    tips: [
                      '**"How" Çok Yönlüdür:** "How" kelimesi tek başına "nasıl" anlamına gelse de, "how much" (ne kadar - sayılamayan), "how many" (kaç tane - sayılabilen), "how often" (ne sıklıkla) ve "how old" (kaç yaşında) gibi birçok farklı soru kalıbı oluşturur.',
                      '**"Who" vs "Whom":** "Who" genellikle özneyi sorarken ("Who called?"), "whom" nesneyi sorar ve daha resmidir ("Whom did you call?"). Günlük dilde genellikle her iki durumda da "who" kullanılır.',
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(height: 30, thickness: 1),
                _AnimatedLessonBlock(
                    controller: _controller,
                    interval: const Interval(0.7, 1.0),
                    child: _QuickQuiz()),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// --- YARDIMCI WIDGET'LAR ---

class _LessonBlock extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  const _LessonBlock(
      {required this.icon, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue.shade700, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(content,
                style: TextStyle(
                    fontSize: 16, color: Colors.grey.shade800, height: 1.5)),
          ],
        ),
      ),
    );
  }
}

class _ExampleCard extends StatelessWidget {
  final String title;
  final List<Example> examples;
  const _ExampleCard({required this.title, required this.examples});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...examples.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  Icon(e.icon, size: 22, color: Colors.blue.shade800),
                  const SizedBox(width: 12),
                  Text(e.category,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(e.sentence,
                          style: const TextStyle(
                              fontSize: 16, fontStyle: FontStyle.italic))),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class _ExampleTable extends StatelessWidget {
  final String title;
  final List<String> headers;
  final List<List<String>> rows;
  const _ExampleTable(
      {required this.title, required this.headers, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor:
                MaterialStateProperty.all(Colors.blue.shade50),
                columns: headers
                    .map((h) => DataColumn(
                    label: Text(h,
                        style:
                        const TextStyle(fontWeight: FontWeight.bold))))
                    .toList(),
                rows: rows
                    .map((row) => DataRow(
                    cells:
                    row.map((cell) => DataCell(Text(cell))).toList()))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final String title;
  final List<String> tips;
  const _TipCard({required this.title, required this.tips});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline,
                  color: Colors.amber.shade800, size: 28),
              const SizedBox(width: 12),
              Text(title,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade900)),
            ],
          ),
          const SizedBox(height: 12),
          ...tips.map((tip) {
            final parts = tip.split('**');
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡 ', style: TextStyle(fontSize: 16)),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade800,
                            height: 1.5),
                        children: [
                          for (int i = 0; i < parts.length; i++)
                            TextSpan(
                              text: parts[i],
                              style: i.isOdd
                                  ? const TextStyle(fontWeight: FontWeight.bold)
                                  : null,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _QuickQuiz extends StatefulWidget {
  @override
  State<_QuickQuiz> createState() => _QuickQuizState();
}

class _QuickQuizState extends State<_QuickQuiz> {
  int? _selectedAnswer1;
  int? _selectedAnswer2;
  int? _selectedAnswer3;
  bool _showResult = false;

  void _checkAnswers() {
    setState(() {
      _showResult = true;
    });
    Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _selectedAnswer1 = null;
          _selectedAnswer2 = null;
          _selectedAnswer3 = null;
          _showResult = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isCorrect1 = _selectedAnswer1 == 1;
    final isCorrect2 = _selectedAnswer2 == 0;
    final isCorrect3 = _selectedAnswer3 == 2;
    final canCheck = _selectedAnswer1 != null &&
        _selectedAnswer2 != null &&
        _selectedAnswer3 != null;

    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text('Hadi Test Edelim!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _QuizQuestion(
              question: '1. ___ is your favorite singer?',
              options: const ['What', 'Who', 'Where'],
              selectedAnswer: _selectedAnswer1,
              correctAnswer: 1,
              showResult: _showResult,
              onChanged: (value) => setState(() => _selectedAnswer1 = value),
            ),
            _QuizQuestion(
              question: '2. ___ are my keys? I can\'t find them.',
              options: const ["Where", "Why", "When"],
              selectedAnswer: _selectedAnswer2,
              correctAnswer: 0,
              showResult: _showResult,
              onChanged: (value) => setState(() => _selectedAnswer2 = value),
            ),
            _QuizQuestion(
              question: '3. ___ are you crying?',
              options: const ['What', 'How', 'Why'],
              selectedAnswer: _selectedAnswer3,
              correctAnswer: 2,
              showResult: _showResult,
              onChanged: (value) => setState(() => _selectedAnswer3 = value),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: canCheck && !_showResult ? _checkAnswers : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              child:
              const Text('Kontrol Et', style: TextStyle(fontSize: 16)),
            ),
            if (_showResult)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  isCorrect1 && isCorrect2 && isCorrect3
                      ? 'Harika! Hepsi doğru!'
                      : 'Tekrar dene, başarabilirsin!',
                  style: TextStyle(
                      color: isCorrect1 && isCorrect2 && isCorrect3
                          ? Colors.green.shade800
                          : Colors.red.shade800,
                      fontWeight: FontWeight.bold),
                ),
              )
          ],
        ),
      ),
    );
  }
}

class _QuizQuestion extends StatelessWidget {
  final String question;
  final List<String> options;
  final int? selectedAnswer;
  final int correctAnswer;
  final bool showResult;
  final ValueChanged<int?> onChanged;

  const _QuizQuestion({
    required this.question,
    required this.options,
    required this.selectedAnswer,
    required this.correctAnswer,
    required this.showResult,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(options.length, (index) {
            Color? color;
            if (showResult) {
              if (index == correctAnswer) {
                color = Colors.green.shade100;
              } else if (index == selectedAnswer) {
                color = Colors.red.shade100;
              }
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: ChoiceChip(
                label: Text(options[index]),
                selected: selectedAnswer == index,
                onSelected: (isSelected) =>
                    onChanged(isSelected ? index : null),
                backgroundColor: color,
                selectedColor: Colors.blue.shade200,
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _AnimatedLessonBlock extends StatelessWidget {
  final AnimationController controller;
  final Interval interval;
  final Widget child;

  const _AnimatedLessonBlock({
    required this.controller,
    required this.interval,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: controller, curve: interval),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
            .animate(CurvedAnimation(parent: controller, curve: interval)),
        child: child,
      ),
    );
  }
}

class Example {
  final IconData icon;
  final String category;
  final String sentence;
  const Example(
      {required this.icon, required this.category, required this.sentence});
}