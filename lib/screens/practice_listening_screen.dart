// lib/screens/practice_listening_screen.dart
import 'package:flutter/material.dart';
import 'package:lingua_chat/models/listening_models.dart';
import 'package:lingua_chat/repositories/listening_repository.dart';
import 'package:lingua_chat/services/listening_progress_service.dart';
import 'package:lingua_chat/screens/practice_listening_detail_screen.dart';

class PracticeListeningScreen extends StatefulWidget {
  const PracticeListeningScreen({super.key});
  static const routeName = '/practice-listening';

  @override
  State<PracticeListeningScreen> createState() => _PracticeListeningScreenState();
}

class _PracticeListeningScreenState extends State<PracticeListeningScreen> {
  final _repo = ListeningRepository.instance;
  final _progress = ListeningProgressService.instance;
  final TextEditingController _searchCtrl = TextEditingController();
  ListeningLevel? _levelFilter;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final all = _repo.all();
    var filtered = all.where((e) => _query.isEmpty || e.title.toLowerCase().contains(_query) || e.category.toLowerCase().contains(_query)).toList();
    if (_levelFilter != null) {
      filtered = filtered.where((e) => e.level == _levelFilter).toList();
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listening Alıştırmaları'),
        actions: [
          PopupMenuButton<ListeningLevel?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (v) => setState(() => _levelFilter = v),
            itemBuilder: (c) => [
              const PopupMenuItem(value: null, child: Text('Tümü')),
              ...ListeningLevel.values.map((l) => PopupMenuItem(value: l, child: Text(l.label))),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Ara (başlık / kategori)',
                filled: true,
                fillColor: Colors.blue.withValues(alpha: .04),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: filtered.length,
              itemBuilder: (c, i) {
                final ex = filtered[i];
                return FutureBuilder<Map<String, dynamic>>(
                  future: _progress.getExercise(ex.id),
                  builder: (c, snap) {
                    final p = snap.data;
                    final attempts = p?['attempts'] ?? 0;
                    final best = p?['best'];
                    return _ExerciseCard(
                      exercise: ex,
                      attempts: attempts,
                      best: best,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PracticeListeningDetailScreen(exerciseId: ex.id),
                          ),
                        ).then((_) => setState(() {}));
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final ListeningExercise exercise;
  final int attempts;
  final int? best;
  final VoidCallback onTap;
  const _ExerciseCard({
    required this.exercise,
    required this.attempts,
    required this.best,
    required this.onTap,
  });

  Color _levelColor(ListeningLevel l) => switch (l) {
        ListeningLevel.beginner => Colors.green,
        ListeningLevel.intermediate => Colors.orange,
        ListeningLevel.advanced => Colors.red,
      };

  @override
  Widget build(BuildContext context) {
    final duration = Duration(milliseconds: exercise.durationMs);
    final m = duration.inMinutes;
    final s = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return InkWell(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.only(bottom: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _levelColor(exercise.level).withValues(alpha: .15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(exercise.level.label, style: TextStyle(color: _levelColor(exercise.level), fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.record_voice_over, size: 18, color: Colors.blueGrey.shade600),
                  const SizedBox(width: 4),
                  Text(exercise.accent, style: Theme.of(context).textTheme.bodySmall),
                  const Spacer(),
                  if (best != null)
                    Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text('En iyi: $best/${exercise.questions.length}'),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(exercise.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(exercise.description ?? exercise.category, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.timer, size: 16, color: Colors.blueGrey.shade500),
                  const SizedBox(width: 4),
                  Text('${m}m ${s}s'),
                  const SizedBox(width: 14),
                  Icon(Icons.question_answer, size: 16, color: Colors.blueGrey.shade500),
                  const SizedBox(width: 4),
                  Text('${exercise.questions.length} soru'),
                  const Spacer(),
                  if (attempts > 0)
                    Text('$attempts deneme', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.blueGrey)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
