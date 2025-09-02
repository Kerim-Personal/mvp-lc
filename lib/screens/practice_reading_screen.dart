// lib/screens/practice_reading_screen.dart
import 'package:flutter/material.dart';
import 'package:lingua_chat/models/reading_models.dart';
import 'package:lingua_chat/repositories/reading_repository.dart';
import 'package:lingua_chat/screens/practice_reading_story_screen.dart';

class PracticeReadingScreen extends StatefulWidget {
  const PracticeReadingScreen({super.key});
  static const routeName = '/practice-reading';

  @override
  State<PracticeReadingScreen> createState() => _PracticeReadingScreenState();
}

class _PracticeReadingScreenState extends State<PracticeReadingScreen> {
  final _repo = ReadingRepository.instance;
  final TextEditingController _searchCtrl = TextEditingController();
  ReadingLevel? _levelFilter;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text.trim().toLowerCase()));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Color _levelColor(ReadingLevel l) => switch (l) {
    ReadingLevel.beginner => Colors.green,
    ReadingLevel.intermediate => Colors.orange,
    ReadingLevel.advanced => Colors.red,
  };

  @override
  Widget build(BuildContext context) {
    final all = _repo.all();
    var filtered = all.where((s) => _query.isEmpty || s.title.toLowerCase().contains(_query) || s.category.toLowerCase().contains(_query)).toList();
    if (_levelFilter != null) {
      filtered = filtered.where((s) => s.level == _levelFilter).toList();
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading Stories'),
        actions: [
          PopupMenuButton<ReadingLevel?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (v) => setState(() => _levelFilter = v),
            itemBuilder: (c) => [
              const PopupMenuItem(value: null, child: Text('All')),
              ...ReadingLevel.values.map((l) => PopupMenuItem(value: l, child: Text(l.label))),
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
                hintText: 'Search (title / category)',
                filled: true,
                fillColor: Colors.purple.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: filtered.length,
              itemBuilder: (c, i) {
                final story = filtered[i];
                return InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PracticeReadingStoryScreen(storyId: story.id),
                      ),
                    );
                  },
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
                                  color: _levelColor(story.level).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(story.level.label, style: TextStyle(color: _levelColor(story.level), fontWeight: FontWeight.w600)),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.menu_book, size: 18, color: Colors.deepPurple.shade400),
                              const SizedBox(width: 4),
                              Text(story.category, style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(story.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text(story.description ?? story.content, maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 8),
                          Row(children: [
                            Icon(Icons.text_snippet, size: 16, color: Colors.deepPurple.shade300),
                            const SizedBox(width: 4),
                            Text('${story.sentences.length} sentences'),
                          ])
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
    );
  }
}