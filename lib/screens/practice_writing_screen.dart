// lib/screens/practice_writing_screen.dart
import 'package:flutter/material.dart';
import 'package:lingua_chat/models/writing_models.dart';
import 'package:lingua_chat/repositories/writing_repository.dart';
import 'package:lingua_chat/screens/practice_writing_detail_screen.dart';

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
  final TextEditingController _searchCtrl = TextEditingController();
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
    if (_query.isNotEmpty) {
      prompts = prompts.where((p) => p.title.toLowerCase().contains(_query) || p.category.toLowerCase().contains(_query)).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Writing Tasks'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
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
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16,10,16,4),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search (title / category)',
                filled: true,
                fillColor: Colors.pink.withOpacity(0.06),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16,8,16,16),
              itemCount: prompts.length,
              itemBuilder: (c,i){
                final p = prompts[i];
                return InkWell(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_)=> PracticeWritingDetailScreen(promptId: p.id))).then((_){ setState((){});}),
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
                                color: _levelColor(p.level).withOpacity(0.18),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(p.level.label, style: TextStyle(color:_levelColor(p.level), fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(width:8),
                            Text(p.type.label, style: Theme.of(context).textTheme.bodySmall),
                            const Spacer(),
                            Text('${p.suggestedMinutes} min', style: Theme.of(context).textTheme.bodySmall),
                          ]),
                          const SizedBox(height:10),
                          Text(p.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height:6),
                          Text(p.instructions, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium),
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
    );
  }
}