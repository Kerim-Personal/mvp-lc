import 'package:flutter/material.dart';

class VerbToBeLessonScreen extends StatelessWidget {
  const VerbToBeLessonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verb "to be" (am/is/are)'),
        backgroundColor: Colors.green,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          _LessonSection(
            title: 'Introduction to "to be"',
            content:
            "The verb 'to be' is one of the most important verbs in English. It is used to describe states, identities, and qualities. It changes its form depending on the subject.",
          ),
          _LessonSection(
            title: 'Forms in the Present Tense',
            content:
            "In the present tense, 'to be' has three forms: **am, is, are**.",
          ),
          _ExampleTable(
            rows: [
              {'Subject': 'I', 'Form': 'am', 'Example': 'I am a student.'},
              {'Subject': 'You, We, They', 'Form': 'are', 'Example': 'They are happy.'},
              {'Subject': 'He, She, It', 'Form': 'is', 'Example': 'She is a doctor.'},
            ],
          ),
          _LessonSection(
            title: 'Negative Forms',
            content:
            "To make a negative sentence, simply add **'not'** after the verb 'to be'.",
          ),
          _ExampleList(
            examples: [
              "I **am not** tired.",
              "He **is not** (isn't) from Spain.",
              "We **are not** (aren't) late.",
            ],
          ),
          _LessonSection(
            title: 'Question Forms',
            content:
            "To ask a question, invert the subject and the verb 'to be'.",
          ),
          _ExampleList(
            examples: [
              "**Am I** right?",
              "**Is she** a teacher?",
              "**Are they** ready?",
            ],
          ),
          _TacticsSection(
            tactics: [
              "**Contractions are key:** In spoken English and informal writing, always use contractions like 'I'm', 'he's', 'they're', 'isn't', and 'aren't'. It sounds more natural.",
              "**Check subject-verb agreement:** This is the most common mistake. Always double-check if your subject matches the form of 'to be' (e.g., 'People **are**...', not 'People is...').",
            ],
          ),
        ],
      ),
    );
  }
}

// --- Ders İçeriği için Yardımcı Widget'lar ---
// Bu widget'ları ayrı bir dosyaya taşıyarak tüm derslerde kullanabilirsiniz.

class _LessonSection extends StatelessWidget {
  final String title;
  final String content;
  const _LessonSection({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(content, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _ExampleTable extends StatelessWidget {
  final List<Map<String, String>> rows;
  const _ExampleTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    final columns = rows.first.keys.map((key) => DataColumn(label: Text(key, style: const TextStyle(fontWeight: FontWeight.bold)))).toList();
    final dataRows = rows.map((row) {
      final cells = row.values.map((value) => DataCell(Text(value))).toList();
      return DataRow(cells: cells);
    }).toList();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: DataTable(columns: columns, rows: dataRows),
    );
  }
}

class _ExampleList extends StatelessWidget {
  final List<String> examples;
  const _ExampleList({required this.examples});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: examples
            .map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ', style: TextStyle(fontSize: 16)),
              Expanded(child: Text(e, style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic))),
            ],
          ),
        ))
            .toList(),
      ),
    );
  }
}

class _TacticsSection extends StatelessWidget {
  final List<String> tactics;
  const _TacticsSection({required this.tactics});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.amber.shade50,
      margin: const EdgeInsets.only(top: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.amber.shade800),
                const SizedBox(width: 8),
                Text("Pro Tips & Tactics", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.amber.shade900)),
              ],
            ),
            const SizedBox(height: 12),
            ...tactics.map((tactic) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡 ', style: TextStyle(fontSize: 16)),
                  Expanded(child: Text(tactic, style: const TextStyle(fontSize: 16))),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}