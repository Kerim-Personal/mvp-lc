// lib/screens/practice_speaking_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vocachat/models/speaking_models.dart';
import 'package:vocachat/repositories/speaking_repository.dart';
import 'package:vocachat/screens/practice_speaking_detail_screen.dart';
import 'package:vocachat/widgets/practice/practice_headers.dart';

class PracticeSpeakingScreen extends StatefulWidget {
  const PracticeSpeakingScreen({super.key});
  static const routeName = '/practice-speaking';

  @override
  State<PracticeSpeakingScreen> createState() => _PracticeSpeakingScreenState();
}

// Seviye filtresi (Writing/Reading/Listening ile aynı)
enum _FilterOption { all, beginner, intermediate, advanced }

class _PracticeSpeakingScreenState extends State<PracticeSpeakingScreen> {
  final _repo = SpeakingRepository.instance;
  late final List<SpeakingPrompt> _allPrompts;
  late List<SpeakingPrompt> _visiblePrompts;
  _FilterOption _menuSelection = _FilterOption.all;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _allPrompts = _repo.all();
    _visiblePrompts = List<SpeakingPrompt>.from(_allPrompts);
    _scrollController = ScrollController();
  }

  void _applyFilter(SpeakingLevel? level) {
    setState(() {
      if (level == null) {
        _visiblePrompts = List<SpeakingPrompt>.from(_allPrompts);
      } else {
        _visiblePrompts = _allPrompts.where((p) => p.level == level).toList();
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
        _applyFilter(SpeakingLevel.beginner);
        break;
      case _FilterOption.intermediate:
        _applyFilter(SpeakingLevel.intermediate);
        break;
      case _FilterOption.advanced:
        _applyFilter(SpeakingLevel.advanced);
        break;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = _visiblePrompts;
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 4)],
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
        titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: const Text('Speaking'),
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
                PopupMenuItem(value: _FilterOption.all, child: Text('All')),
                PopupMenuItem(value: _FilterOption.beginner, child: Text('Beginner')),
                PopupMenuItem(value: _FilterOption.intermediate, child: Text('Intermediate')),
                PopupMenuItem(value: _FilterOption.advanced, child: Text('Advanced')),
              ],
            ),
          )
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
                tag: 'mode-Speaking',
                title: 'Speaking Practice',
                subtitle: 'Speak • Repeat • Improve',
                image: 'assets/practice/speaking_bg.jpg',
                colors: const [Color(0xFFFFCF71), Color(0xFF2376DD)],
                icon: Icons.mic_rounded,
                margin: topMargin,
                hero: false,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: list.isEmpty
                  ? const Center(child: Text('No speaking prompts found.', style: TextStyle(color: Colors.white)))
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: list.length,
                      itemBuilder: (c, i) {
                        final p = list[i];
                        return _SpeakingPromptCard(
                          prompt: p,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => PracticeSpeakingDetailScreen(promptId: p.id))
                            );
                          },
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

class _SpeakingPromptCard extends StatelessWidget {
  final SpeakingPrompt prompt;
  final VoidCallback onTap;
  const _SpeakingPromptCard({required this.prompt, required this.onTap});

  Color _levelColor(SpeakingLevel level) => switch (level) {
    SpeakingLevel.beginner => Colors.green,
    SpeakingLevel.intermediate => Colors.orange,
    SpeakingLevel.advanced => Colors.red,
  };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _levelColor(prompt.level).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.signal_cellular_alt, size: 14, color: _levelColor(prompt.level)),
                        const SizedBox(width: 4),
                        Text(
                          prompt.level.name.toUpperCase(),
                          style: TextStyle(
                            color: _levelColor(prompt.level),
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.mic, size: 18, color: Colors.grey.shade600),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                prompt.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                prompt.context,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.format_quote, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    '${prompt.targets.length} sentences',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

