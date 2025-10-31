// lib/screens/practice_reading_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vocachat/models/reading_models.dart';
import 'package:vocachat/repositories/reading_repository.dart';
import 'package:vocachat/screens/practice_reading_story_screen.dart';
import 'package:vocachat/widgets/practice/practice_headers.dart';

class PracticeReadingScreen extends StatefulWidget {
  const PracticeReadingScreen({super.key});
  static const routeName = '/practice-reading';

  @override
  State<PracticeReadingScreen> createState() => _PracticeReadingScreenState();
}

// Yazma ekranıyla aynı filtre seçenekleri
enum _FilterOption { all, beginner, intermediate, advanced }

class _PracticeReadingScreenState extends State<PracticeReadingScreen> {
  final _repo = ReadingRepository.instance;
  late final List<ReadingStory> _allStories;
  late List<ReadingStory> _visibleStories;
  _FilterOption _menuSelection = _FilterOption.all;
  late final ScrollController _scrollController;

  Color _levelColor(ReadingLevel l) => switch (l) {
        ReadingLevel.beginner => Colors.green,
        ReadingLevel.intermediate => Colors.orange,
        ReadingLevel.advanced => Colors.red,
      };

  @override
  void initState() {
    super.initState();
    _allStories = _repo.all();
    _visibleStories = List<ReadingStory>.from(_allStories);
    _scrollController = ScrollController();
  }

  void _applyFilter(ReadingLevel? level) {
    setState(() {
      if (level == null) {
        _visibleStories = List<ReadingStory>.from(_allStories);
      } else {
        _visibleStories = _allStories.where((s) => s.level == level).toList();
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
        _applyFilter(ReadingLevel.beginner);
        break;
      case _FilterOption.intermediate:
        _applyFilter(ReadingLevel.intermediate);
        break;
      case _FilterOption.advanced:
        _applyFilter(ReadingLevel.advanced);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stories = _visibleStories;
    final topMargin = EdgeInsets.fromLTRB(
      16,
      MediaQuery.of(context).padding.top + kToolbarHeight + 12,
      16,
      12,
    );

    // AppBar artık arkada; transparan kullanılacak.
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
      backgroundColor: Colors.black,
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
        title: const Text('Reading'),
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
      body: Stack(
        children: [
          Positioned.fill(
            child: const DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black,
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
                child: stories.isEmpty
                    ? const EmptyState(message: 'No stories match your filters.')
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: stories.length,
                        itemBuilder: (c, i) {
                          final story = stories[i];
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
                                          child: Text(
                                            story.level.label,
                                            style: TextStyle(
                                              color: _levelColor(story.level),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(Icons.menu_book, size: 18, color: Colors.deepPurple.shade400),
                                        const SizedBox(width: 4),
                                        Text(story.category, style: Theme.of(context).textTheme.bodySmall),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      story.title,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      story.description ?? story.content,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}