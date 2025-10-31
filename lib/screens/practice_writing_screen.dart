// lib/screens/practice_writing_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vocachat/models/writing_models.dart';
import 'package:vocachat/repositories/writing_repository.dart';
import 'package:vocachat/screens/practice_writing_detail_screen.dart';
import 'package:vocachat/widgets/practice/practice_headers.dart';

class PracticeWritingScreen extends StatefulWidget {
  const PracticeWritingScreen({super.key});
  static const routeName = '/practice-writing';

  @override
  State<PracticeWritingScreen> createState() => _PracticeWritingScreenState();
}

// Null tabanlı seçimlerdeki olası tutarsızlıkları önlemek için açık filtre seçeneği
enum _FilterOption { all, beginner, intermediate, advanced }

class _PracticeWritingScreenState extends State<PracticeWritingScreen> {
  final _repo = WritingRepository.instance;
  late final List<WritingTask> _allTasks;
  // Görünür listeyi state'te tut
  late List<WritingTask> _visibleTasks;
  WritingLevel? _levelFilter; // null => All
  _FilterOption _menuSelection = _FilterOption.all;

  Color _levelColor(WritingLevel l) => switch (l) {
        WritingLevel.beginner => Colors.green,
        WritingLevel.intermediate => Colors.orange,
        WritingLevel.advanced => Colors.red,
      };

  @override
  void initState() {
    super.initState();
    _allTasks = _repo.getAllTasks();
    _visibleTasks = List<WritingTask>.from(_allTasks);
  }

  void _applyFilter(WritingLevel? level) {
    setState(() {
      _levelFilter = level;
      if (level == null) {
        // All
        _visibleTasks = List<WritingTask>.from(_allTasks);
      } else {
        _visibleTasks = List<WritingTask>.from(_repo.getTasksByLevel(level));
      }
    });
  }

  void _onMenuSelected(_FilterOption opt) {
    _menuSelection = opt; // Menü highlight'ı için local state
    switch (opt) {
      case _FilterOption.all:
        _applyFilter(null);
        break;
      case _FilterOption.beginner:
        _applyFilter(WritingLevel.beginner);
        break;
      case _FilterOption.intermediate:
        _applyFilter(WritingLevel.intermediate);
        break;
      case _FilterOption.advanced:
        _applyFilter(WritingLevel.advanced);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Artık state'teki görünür listeyi kullan
    final tasks = _visibleTasks;
    final topMargin = EdgeInsets.fromLTRB(
      16,
      MediaQuery.of(context).padding.top + kToolbarHeight + 12,
      16,
      12,
    );

    Widget circleWrapper(Widget child) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.38),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 4),
            ],
          ),
          child: child,
        );
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        titleTextStyle: Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: const Text('Writing'),
        leading: canPop
            ? GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: circleWrapper(const Icon(Icons.arrow_back, color: Colors.white)),
              )
            : null,
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFFF9A9E).withValues(alpha: 0.3),
              const Color(0xFFFECAB3).withValues(alpha: 0.2),
            ],
          ),
        ),
        child: Column(
          children: [
            ModeHeroHeader(
              tag: 'mode-Writing',
              title: 'Writing Practice',
              subtitle: 'Write • Create • Express',
              image: 'assets/practice/writing_bg.jpg',
              colors: const [Color(0xFFFF9A9E), Color(0xFFFECAB3)],
              icon: Icons.edit_rounded,
              margin: topMargin,
              hero: false,
            ),
            Expanded(
              child: tasks.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text(
                          'No tasks match your filters.',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: tasks.length,
                      itemBuilder: (c, i) {
                        final task = tasks[i];
                        return Card(
                          key: ValueKey(task.id),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PracticeWritingDetailScreen(taskId: task.id),
                              ),
                            ),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Text(task.emoji, style: const TextStyle(fontSize: 32)),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _levelColor(task.level).withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            task.level.label,
                                            style: TextStyle(
                                              color: _levelColor(task.level),
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          task.task,
                                          style: Theme.of(context).textTheme.bodyMedium,
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios, size: 16),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
