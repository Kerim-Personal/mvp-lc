// lib/screens/practice_reading_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lingua_chat/models/reading_models.dart';
import 'package:lingua_chat/repositories/reading_repository.dart';
import 'package:lingua_chat/screens/practice_reading_story_screen.dart';
import 'package:lingua_chat/widgets/practice/practice_headers.dart';

class PracticeReadingScreen extends StatefulWidget {
  const PracticeReadingScreen({super.key});
  static const routeName = '/practice-reading';

  @override
  State<PracticeReadingScreen> createState() => _PracticeReadingScreenState();
}

class _PracticeReadingScreenState extends State<PracticeReadingScreen> {
  final _repo = ReadingRepository.instance;
  ReadingLevel? _levelFilter;

  Color _levelColor(ReadingLevel l) => switch (l) {
    ReadingLevel.beginner => Colors.green,
    ReadingLevel.intermediate => Colors.orange,
    ReadingLevel.advanced => Colors.red,
  };

  @override
  Widget build(BuildContext context) {
    final all = _repo.all();
    var filtered = all;
    if (_levelFilter != null) {
      filtered = filtered.where((s) => s.level == _levelFilter).toList();
    }
    final topMargin = EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + kToolbarHeight + 12, 16, 12);

    // AppBar artık arkada; transparan kullanılacak.
    Widget circleWrapper(Widget child) => Container(
      margin: const EdgeInsets.symmetric(horizontal:4, vertical:6),
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.38),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 4)],
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
        titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: const Text('Reading'),
        leading: canPop ? GestureDetector(
          onTap: ()=> Navigator.of(context).maybePop(),
          child: circleWrapper(const Icon(Icons.arrow_back, color: Colors.white)),
        ) : null,
        leadingWidth: canPop ? 60 : null,
        actions: [
          circleWrapper(
            PopupMenuButton<ReadingLevel?>(
              icon: const Icon(Icons.filter_list, color: Colors.white),
              onSelected: (v) => setState(() => _levelFilter = v),
              itemBuilder: (c) => [
                const PopupMenuItem(value: null, child: Text('All')),
                ...ReadingLevel.values.map((l) => PopupMenuItem(value: l, child: Text(l.label))),
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
                  image: AssetImage('assets/practice/reading_bg.jpg'),
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
                tag: 'mode-Reading',
                title: 'Reading Practice',
                subtitle: 'Read • Explore • Understand',
                image: 'assets/practice/reading_bg.jpg',
                colors: const [Color(0xFFA18CD1), Color(0xFF915ADB)],
                icon: Icons.menu_book_rounded,
                margin: topMargin,
                hero: false,
              ),
              Expanded(
                child: filtered.isEmpty ? const EmptyState(message: 'No stories match your filters.') : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
                                      color: _levelColor(story.level).withValues(alpha: 0.15),
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
        ],
      ),
    );
  }
}