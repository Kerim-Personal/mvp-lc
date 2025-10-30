// lib/screens/practice_writing_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vocachat/models/writing_models.dart';
import 'package:vocachat/repositories/writing_repository.dart';
import 'package:vocachat/screens/practice_writing_detail_screen.dart';

class PracticeWritingScreen extends StatefulWidget {
  const PracticeWritingScreen({super.key});
  static const routeName = '/practice-writing';

  @override
  State<PracticeWritingScreen> createState() => _PracticeWritingScreenState();
}

class _PracticeWritingScreenState extends State<PracticeWritingScreen> {
  final _repo = WritingRepository.instance;
  WritingLevel? _levelFilter;

  Color _levelColor(WritingLevel l) => switch (l) {
    WritingLevel.beginner => Colors.green,
    WritingLevel.intermediate => Colors.orange,
    WritingLevel.advanced => Colors.red,
  };

  @override
  Widget build(BuildContext context) {
    var tasks = _repo.getAllTasks();
    if (_levelFilter != null) {
      tasks = _repo.getTasksByLevel(_levelFilter!);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Writing Practice'),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        actions: [
          PopupMenuButton<WritingLevel?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (level) => setState(() => _levelFilter = level),
            itemBuilder: (c) => [
              const PopupMenuItem(value: null, child: Text('Tüm Seviyeler')),
              ...WritingLevel.values.map((l) =>
                PopupMenuItem(value: l, child: Text(l.label))
              ),
            ],
          ),
        ],
      ),
      body: tasks.isEmpty
        ? const Center(child: Text('Görev bulunamadı'))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (c, i) {
              final task = tasks[i];
              return Card(
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
    );
  }
}
