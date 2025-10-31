// lib/screens/practice_listening_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vocachat/models/listening_models.dart';
import 'package:vocachat/repositories/listening_repository.dart';
import 'package:vocachat/services/listening_progress_service.dart';
import 'package:vocachat/screens/practice_listening_detail_screen.dart';
import 'package:vocachat/widgets/practice/practice_headers.dart';

class PracticeListeningScreen extends StatefulWidget {
  const PracticeListeningScreen({super.key});
  static const routeName = '/practice-listening';

  @override
  State<PracticeListeningScreen> createState() => _PracticeListeningScreenState();
}

// Yazma ekranındaki gibi açık filtre seçenekleri
enum _FilterOption { all, beginner, intermediate, advanced }

class _PracticeListeningScreenState extends State<PracticeListeningScreen> {
  final _repo = ListeningRepository.instance;
  final _progress = ListeningProgressService.instance;
  late final List<ListeningExercise> _allExercises;
  late List<ListeningExercise> _visibleExercises;
  _FilterOption _menuSelection = _FilterOption.all;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _allExercises = _repo.all();
    _visibleExercises = List<ListeningExercise>.from(_allExercises);
    _scrollController = ScrollController();
  }

  void _applyFilter(ListeningLevel? level) {
    setState(() {
      if (level == null) {
        _visibleExercises = List<ListeningExercise>.from(_allExercises);
      } else {
        _visibleExercises = _allExercises.where((e) => e.level == level).toList();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  void _onMenuSelected(_FilterOption opt) {
    _menuSelection = opt;
    switch (opt) {
      case _FilterOption.all:
        _applyFilter(null);
        break;
      case _FilterOption.beginner:
        _applyFilter(ListeningLevel.beginner);
        break;
      case _FilterOption.intermediate:
        _applyFilter(ListeningLevel.intermediate);
        break;
      case _FilterOption.advanced:
        _applyFilter(ListeningLevel.advanced);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercises = _visibleExercises;
    final topMargin = EdgeInsets.fromLTRB(
      16,
      MediaQuery.of(context).padding.top + kToolbarHeight + 12,
      16,
      12,
    );

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

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
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
            PopupMenuButton<_FilterOption>(
              icon: const Icon(Icons.filter_list, color: Colors.white),
              initialValue: _menuSelection,
              onSelected: _onMenuSelected,
              itemBuilder: (c) => const [
                PopupMenuItem<_FilterOption>(value: _FilterOption.all, child: Text('All')),
                PopupMenuItem<_FilterOption>(value: _FilterOption.beginner, child: Text('Beginner')),
                PopupMenuItem<_FilterOption>(value: _FilterOption.intermediate, child: Text('Intermediate')),
                PopupMenuItem<_FilterOption>(value: _FilterOption.advanced, child: Text('Advanced')),
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
                image: DecorationImage(
                  image: AssetImage('assets/practice/main_bg.png'),
                  fit: BoxFit.cover,
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
                child: exercises.isEmpty ? const EmptyState(message: 'No listening exercises found.') : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: exercises.length,
                  itemBuilder: (c, i) {
                    final ex = exercises[i];
                    return AnimatedSlide(
                      duration: const Duration(milliseconds: 300),
                      offset: Offset(0, 0.02 * (1 - (i / (exercises.length.clamp(1, 99))))),
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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