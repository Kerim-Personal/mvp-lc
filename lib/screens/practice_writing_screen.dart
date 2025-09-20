// lib/screens/practice_writing_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vocachat/models/writing_models.dart';
import 'package:vocachat/repositories/writing_repository.dart';
import 'package:vocachat/screens/practice_writing_detail_screen.dart';
import 'package:vocachat/widgets/practice/practice_headers.dart';
import 'package:vocachat/services/writing_progress_service.dart';

class PracticeWritingScreen extends StatefulWidget {
  const PracticeWritingScreen({super.key});
  static const routeName = '/practice-writing';
  @override
  State<PracticeWritingScreen> createState() => _PracticeWritingScreenState();
}

class _PracticeWritingScreenState extends State<PracticeWritingScreen> {
  final _repo = WritingRepository.instance;
  WritingLevel? _levelFilter;
  WritingType? _typeFilter;
  // Search kaldırıldı
  final _progress = WritingProgressService.instance; // progress ekleme
  final Map<String, Map<String,dynamic>> _progressCache = {}; // hızlı erişim
  bool _loadingProgress = false;

  @override
  void initState() {
    super.initState();
    // _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text.trim().toLowerCase()));
    _primeProgress();
  }

  Future<void> _primeProgress() async {
    setState(()=> _loadingProgress = true);
    for (final p in _repo.all()) {
      final data = await _progress.getPrompt(p.id);
      _progressCache[p.id] = data;
    }
    if (mounted) setState(()=> _loadingProgress = false);
  }

  @override
  void dispose() {
    // _searchCtrl.dispose();
    super.dispose();
  }

  Color _levelColor(WritingLevel l) => switch (l) {
    WritingLevel.beginner => Colors.green,
    WritingLevel.intermediate => Colors.orange,
    WritingLevel.advanced => Colors.red,
  };

  @override
  Widget build(BuildContext context) {
    var prompts = _repo.all();
    if (_levelFilter != null) prompts = prompts.where((p) => p.level == _levelFilter).toList();
    if (_typeFilter != null) prompts = prompts.where((p) => p.type == _typeFilter).toList();

    // AppBar artık arkasından içerik geçmediği için küçük üst boşluk
    final topMargin = EdgeInsets.fromLTRB(
      16,
      MediaQuery.of(context).padding.top + kToolbarHeight + 12,
      16,
      12,
    );

    Color _appBarBg(){
      final b = Theme.of(context).brightness;
      return b==Brightness.dark ? Colors.black.withValues(alpha:0.55) : Colors.white.withValues(alpha:0.92);
    }

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
        title: const Text('Writing'),
        leading: canPop ? GestureDetector(
          onTap: ()=> Navigator.of(context).maybePop(),
          child: circleWrapper(const Icon(Icons.arrow_back, color: Colors.white)),
        ) : null,
        leadingWidth: canPop ? 60 : null,
        actions: [
          circleWrapper(
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list, color: Colors.white),
              onSelected: (v) {
                if (v.startsWith('L_')) {
                  setState(()=> _levelFilter = v=='L_all'? null : WritingLevel.values.firstWhere((e)=>e.name==v.substring(2)));
                } else if (v.startsWith('T_')) {
                  setState(()=> _typeFilter = v=='T_all'? null : WritingType.values.firstWhere((e)=>e.name==v.substring(2)));
                }
              },
              itemBuilder: (c) => [
                const PopupMenuItem(value: 'L_all', child: Text('Level: All')),
                ...WritingLevel.values.map((l)=> PopupMenuItem(value: 'L_${l.name}', child: Text(l.label))),
                const PopupMenuDivider(),
                const PopupMenuItem(value: 'T_all', child: Text('Type: All')),
                ...WritingType.values.map((t)=> PopupMenuItem(value: 'T_${t.name}', child: Text(t.label))),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children:[
          // Fullscreen background (image + gradient overlay)
          Positioned.fill(
            child: Stack(children:[
               const Positioned.fill(
                 child: Image(
                   image: AssetImage('assets/practice/writing_bg.jpg'),
                   fit: BoxFit.cover,
                 ),
               ),
               Positioned.fill(
                 child: DecoratedBox(
                   decoration: BoxDecoration(
                     gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors:[
                        Colors.black.withValues(alpha:0.45),
                        Colors.black.withValues(alpha:0.38),
                      ],
                     ),
                   ),
                 ),
               )
             ]),
           ),
           Column(
             children: [
               ModeHeroHeader(
                 tag: 'mode-Writing',
                 title: 'Writing Practice',
                 subtitle: 'Think • Write • Shine',
                 image: 'assets/practice/writing_bg.jpg',
                 colors: const [Color(0xFFFF9A9E), Color(0xFFF76D84)],
                 icon: Icons.edit_rounded,
                 margin: topMargin,
                 hero: false,
               ),
               const SizedBox(height:8),
               // FilterChip satırı kaldırıldı
               if (_loadingProgress)
                 const Padding(
                   padding: EdgeInsets.only(top:6),
                   child: LinearProgressIndicator(minHeight: 3),
                 ),
               Expanded(
                 child: prompts.isEmpty ? const EmptyState(message: 'Eşleşen yazma görevi yok.') : ListView.builder(
                   padding: const EdgeInsets.fromLTRB(16,8,16,24),
                   itemCount: prompts.length,
                   itemBuilder: (c,i){
                     final p = prompts[i];
                     final prog = _progressCache[p.id];
                     final best = (prog?['bestScore'] as num?)?.toDouble();
                     final attempts = (prog?['attempts'] as int?) ?? 0;
                     return InkWell(
                       onTap: () => Navigator.of(context)
                           .push(MaterialPageRoute(builder: (_)=> PracticeWritingDetailScreen(promptId: p.id)))
                           .then((_){ _primeProgress(); setState((){});}),
                       borderRadius: BorderRadius.circular(18),
                       child: Card(
                         margin: const EdgeInsets.only(bottom:14),
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                         child: Padding(
                           padding: const EdgeInsets.all(16),
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Row(children:[
                                 Container(
                                   padding: const EdgeInsets.symmetric(horizontal:10, vertical:4),
                                   decoration: BoxDecoration(
                                     color: _levelColor(p.level).withValues(alpha: 0.18),
                                     borderRadius: BorderRadius.circular(12),
                                   ),
                                   child: Text(p.level.label, style: TextStyle(color:_levelColor(p.level), fontWeight: FontWeight.w600)),
                                 ),
                                 const SizedBox(width:8),
                                 Text(p.type.label, style: Theme.of(context).textTheme.bodySmall),
                                 const Spacer(),
                                 if (best!=null) Tooltip(
                                   message: 'En iyi skor',
                                   child: Row(children:[
                                     const Icon(Icons.star, size:16, color: Colors.amber),
                                     Text(best.toStringAsFixed(0), style: const TextStyle(fontWeight: FontWeight.w600))
                                   ]),
                                 ),
                                 if (attempts>0) Padding(
                                   padding: const EdgeInsets.only(left:8),
                                   child: Text('x$attempts', style: Theme.of(context).textTheme.bodySmall),
                                 )
                               ]),
                               const SizedBox(height:10),
                               Text(p.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                               const SizedBox(height:6),
                               Text(p.instructions, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium),
                               const SizedBox(height:10),
                               Row(children:[
                                 Icon(Icons.timer, size:16, color: Colors.grey.shade600),
                                 const SizedBox(width:4),
                                 Text('${p.suggestedMinutes} dk'),
                                 const Spacer(),
                                 if (prog?['draft'] != null && (prog?['draft'] as String).trim().isNotEmpty)
                                   const Icon(Icons.save, size:16, color: Colors.green)
                               ])
                             ],
                           ),
                         ),
                       ),
                     );
                   },
                 ),
               )
             ],
           ),
         ],
       ),
    );
  }
}
