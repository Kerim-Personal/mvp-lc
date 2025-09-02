// lib/screens/practice_speaking_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lingua_chat/models/speaking_models.dart';
import 'package:lingua_chat/repositories/speaking_repository.dart';
import 'package:lingua_chat/screens/practice_speaking_detail_screen.dart';

class PracticeSpeakingScreen extends StatefulWidget {
  const PracticeSpeakingScreen({super.key});
  static const routeName = '/practice-speaking';
  @override
  State<PracticeSpeakingScreen> createState() => _PracticeSpeakingScreenState();
}

class _PracticeSpeakingScreenState extends State<PracticeSpeakingScreen> {
  final _repo = SpeakingRepository.instance;
  SpeakingMode? _modeFilter;
  final TextEditingController _searchCtrl = TextEditingController();
  String _q = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(()=> setState(()=> _q = _searchCtrl.text.trim().toLowerCase()));
  }
  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var list = _repo.all();
    if (_modeFilter!=null) list = list.where((p)=> p.mode==_modeFilter).toList();
    if (_q.isNotEmpty) list = list.where((p) => p.title.toLowerCase().contains(_q) || p.context.toLowerCase().contains(_q)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Speaking Practice'),
        actions: [
          PopupMenuButton<SpeakingMode?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (v)=> setState(()=> _modeFilter = v),
            itemBuilder: (c)=> [
              const PopupMenuItem(value:null, child: Text('All')),
              ...SpeakingMode.values.map((m)=> PopupMenuItem(value:m, child: Text(m.label)))
            ],
          )
        ],
      ),
      body: Stack(
          children:[
            const _SpeakingBackdrop(),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16,12,16,4),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Search (title / context)',
                      filled: true,
                      fillColor: Colors.orange.withAlpha(12), // Equivalent to withValues(alpha: .05)
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                SizedBox(
                  height: 46,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal:12),
                    scrollDirection: Axis.horizontal,
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: _modeFilter==null,
                        onSelected: (_)=> setState(()=> _modeFilter=null),
                      ),
                      const SizedBox(width:8),
                      ...SpeakingMode.values.map((m)=> Padding(
                        padding: const EdgeInsets.only(right:8),
                        child: FilterChip(
                          label: Text(m.label),
                          selected: _modeFilter==m,
                          onSelected: (_)=> setState(()=> _modeFilter = m),
                        ),
                      ))
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16,8,16,16),
                    itemCount: list.length,
                    itemBuilder: (c,i){
                      final p = list[i];
                      return _SpeakingPromptCard(prompt: p, onTap: (){
                        Navigator.of(context).push(
                            MaterialPageRoute(builder: (_)=> PracticeSpeakingDetailScreen(promptId: p.id))
                        );
                      });
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
                    color: _modeColor(prompt.mode).withAlpha(40), // Equivalent to withValues(alpha: .16)
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

// Lightly animated background for a professional, fluid feel
class _SpeakingBackdrop extends StatefulWidget { const _SpeakingBackdrop(); @override State<_SpeakingBackdrop> createState()=> _SpeakingBackdropState(); }
class _SpeakingBackdropState extends State<_SpeakingBackdrop> with SingleTickerProviderStateMixin {
  late final AnimationController _c;@override void initState(){super.initState();_c= AnimationController(vsync:this, duration: const Duration(seconds:18))..repeat();}
  @override void dispose(){_c.dispose(); super.dispose();}
  @override Widget build(BuildContext context){
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context,_) {
          return CustomPaint(
            painter: _WavePainter(_c.value),
            child: Container(
              decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      colors:[Color(0xFF101522), Color(0xFF182235)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight
                  )
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double t; _WavePainter(this.t);
  @override void paint(Canvas canvas, Size size){
    final lines = 6; final amp = 14.0; final gap = size.height/(lines+1);
    for(int i=0;i<lines;i++){
      final path = Path(); final yBase = gap*(i+1);
      for(double x=0;x<=size.width;x+=8){
        final y = yBase + math.sin((x/size.width*4*math.pi)+ t*2*math.pi + i)*amp * (1 - (i/lines)*.35);
        if(x==0){ path.moveTo(x,y);} else { path.lineTo(x,y);} }
      final lineColor = const LinearGradient(colors:[Color(0xFF3FB9FF), Color(0xFF7C4DFF)])
          .createShader(Rect.fromLTWH(0,0,size.width,size.height));
      final p = Paint()
        ..style=PaintingStyle.stroke
        ..strokeWidth=1.4
        ..shader=lineColor
        ..color=Colors.white.withAlpha(71 - (i*8)); // Equivalent to withValues(alpha: .28 - i*0.03)
      canvas.drawPath(path, p);
    }
  }
  @override bool shouldRepaint(_WavePainter old)=> old.t!=t;
}
