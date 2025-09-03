// lib/screens/practice_speaking_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lingua_chat/models/speaking_models.dart';
import 'package:lingua_chat/repositories/speaking_repository.dart';
import 'package:lingua_chat/screens/practice_speaking_detail_screen.dart';
import 'package:lingua_chat/widgets/practice/practice_headers.dart';

class PracticeSpeakingScreen extends StatefulWidget {
  const PracticeSpeakingScreen({super.key});
  static const routeName = '/practice-speaking';
  @override
  State<PracticeSpeakingScreen> createState() => _PracticeSpeakingScreenState();
}

class _PracticeSpeakingScreenState extends State<PracticeSpeakingScreen> {
  final _repo = SpeakingRepository.instance;
  SpeakingMode? _modeFilter;

  @override
  Widget build(BuildContext context) {
    var list = _repo.all();
    if (_modeFilter!=null) list = list.where((p)=> p.mode==_modeFilter).toList();

    final topMargin = EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + kToolbarHeight + 12, 16, 12);

    // AppBar transparan olacak.
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
        title: const Text('Speaking'),
        leading: canPop ? GestureDetector(
          onTap: ()=> Navigator.of(context).maybePop(),
          child: circleWrapper(const Icon(Icons.arrow_back, color: Colors.white)),
        ) : null,
        leadingWidth: canPop ? 60 : null,
        actions: [
          circleWrapper(
            PopupMenuButton<SpeakingMode?>(
              icon: const Icon(Icons.filter_list, color: Colors.white),
              onSelected: (v)=> setState(()=> _modeFilter = v),
              itemBuilder: (c)=> [
                const PopupMenuItem(value:null, child: Text('All')),
                ...SpeakingMode.values.map((m)=> PopupMenuItem(value:m, child: Text(m.label)))
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
                image: const DecorationImage(
                  image: AssetImage('assets/practice/speaking_bg.jpg'),
                  fit: BoxFit.cover,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.28),
                    Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.88),
                  ],
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
              const SizedBox(height:8),
              Expanded(
                child: list.isEmpty ? const EmptyState(message: 'No speaking prompts found.') : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16,8,16,24),
                  itemCount: list.length,
                  itemBuilder: (c,i){
                    final p = list[i];
                    return AnimatedSlide(
                      duration: const Duration(milliseconds: 300),
                      offset: Offset(0, 0.02 * (1 - (i / (list.length.clamp(1, 99))))),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 400),
                        opacity: 1,
                        child: _SpeakingPromptCard(prompt: p, onTap: (){
                          Navigator.of(context).push(
                              MaterialPageRoute(builder: (_)=> PracticeSpeakingDetailScreen(promptId: p.id))
                          );
                        }),
                      ),
                    );
                  },
                ),
              )
            ],
          ),
        ]
      ),
    );
  }
}

class _SpeakingPromptCard extends StatelessWidget {
  final SpeakingPrompt prompt;
  final VoidCallback onTap;
  const _SpeakingPromptCard({required this.prompt, required this.onTap});

  Color _modeColor(SpeakingMode m) => switch (m) {
    SpeakingMode.shadowing => Colors.deepPurple,
    SpeakingMode.repeat => Colors.teal,
    SpeakingMode.roleplay => Colors.indigo,
    SpeakingMode.qna => Colors.orange,
  };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.only(bottom:14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:[
              Row(children:[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal:10, vertical:4),
                  decoration: BoxDecoration(
                    color: _modeColor(prompt.mode).withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(prompt.mode.label, style: TextStyle(color:_modeColor(prompt.mode), fontWeight: FontWeight.w600)),
                ),
                const Spacer(),
                Icon(Icons.mic, size:18, color: Colors.grey.shade600),
              ]),
              const SizedBox(height:10),
              Text(prompt.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height:6),
              Text(prompt.context, maxLines: 2, overflow: TextOverflow.ellipsis),
              if(prompt.tips.isNotEmpty)...[
                const SizedBox(height:8),
                Wrap(
                  spacing:6, runSpacing:4,
                  children: prompt.tips.take(3).map((t)=> Chip(label: Text(t, style: const TextStyle(fontSize:11)), visualDensity: VisualDensity.compact)).toList(),
                )
              ]
            ],
          ),
        ),
      ),
    );
  }
}
