// lib/screens/practice_listening_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lingua_chat/models/listening_models.dart';
import 'package:lingua_chat/repositories/listening_repository.dart';
import 'package:lingua_chat/services/listening_progress_service.dart';
import 'package:lingua_chat/screens/practice_listening_detail_screen.dart';
import 'package:lingua_chat/widgets/practice/practice_headers.dart';

class PracticeListeningScreen extends StatefulWidget {
  const PracticeListeningScreen({super.key});
  static const routeName = '/practice-listening';

  @override
  State<PracticeListeningScreen> createState() => _PracticeListeningScreenState();
}

class _PracticeListeningScreenState extends State<PracticeListeningScreen> {
  final _repo = ListeningRepository.instance;
  final _progress = ListeningProgressService.instance;
  ListeningLevel? _levelFilter;

  @override
  Widget build(BuildContext context) {
    final all = _repo.all();
    var filtered = all;
    if (_levelFilter != null) {
      filtered = filtered.where((e) => e.level == _levelFilter).toList();
    }
    final topMargin = EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + kToolbarHeight + 12, 16, 12);

    Widget circleWrapper(Widget child) => Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.38),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 4)],
      ),
      width: 44,
      height: 44,
      child: child,
    );
    final canPop = Navigator.of(context).canPop();
    // Artık AppBar arkası da görüntü altında: safe area boşluğu

    // AppBar transparan olacak.
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: const Text('Listening'),
        leading: canPop ? GestureDetector(
          onTap: () => Navigator.of(context).maybePop(),
          child: circleWrapper(const Icon(Icons.arrow_back, color: Colors.white)),
        ) : null,
        leadingWidth: canPop ? 60 : null,
        actions: [
          circleWrapper(
            PopupMenuButton<ListeningLevel?>(
              icon: const Icon(Icons.filter_list, color: Colors.white),
              onSelected: (v) => setState(() => _levelFilter = v),
              itemBuilder: (c) => [
                const PopupMenuItem(value: null, child: Text('All')),
                ...ListeningLevel.values.map((l) => PopupMenuItem(value: l, child: Text(l.label))),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children:[
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                image: const DecorationImage(
                  image: AssetImage('assets/practice/listening_bg.jpg'),
                  fit: BoxFit.cover,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.50),
                    Colors.black.withValues(alpha: 0.40),
                  ],
                ),
              ),
            ),
          ),
          Column(
            children: [
              ModeHeroHeader(
                tag: 'mode-Listening',
                title: 'Listening Practice',
                subtitle: 'Listen • Understand • Answer',
                image: 'assets/practice/listening_bg.jpg',
                colors: const [Color(0xFF2BC0E4), Color(0xFF84FAB0)],
                icon: Icons.headphones_rounded,
                margin: topMargin,
                hero: false,
              ),
              Expanded(
                child: filtered.isEmpty ? const EmptyState(message: 'No listening exercises found.') : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: filtered.length,
                  itemBuilder: (c, i) {
                    final ex = filtered[i];
                    return AnimatedSlide(
                      duration: const Duration(milliseconds: 300),
                      offset: Offset(0, 0.02 * (1 - (i / (filtered.length.clamp(1, 99))))),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 400),
                        opacity: 1,
                        child: FutureBuilder<Map<String, dynamic>>(
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
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
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
                      color: _levelColor(exercise.level).withValues(alpha: 0.15),
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
                      label: Text('Best: $best/${exercise.questions.length}'),
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
                  Text('${exercise.questions.length} questions'),
                  const Spacer(),
                  if (attempts > 0)
                    Text('$attempts attempts', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.blueGrey)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}