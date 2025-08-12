// lib/widgets/discover/grammar_tab.dart

import 'package:flutter/material.dart';
import 'package:lingua_chat/data/lesson_data.dart'; // YENİ: Ders verileri buradan import edildi.
import 'package:lingua_chat/models/lesson_model.dart'; // YENİ: Lesson modeli buradan import edildi.
import 'package:lingua_chat/navigation/lesson_router.dart';


// --- GRAMER SEKMESİ ANA WIDGET'I (YENİDEN TASARLANDI) ---
class GrammarTab extends StatelessWidget {
  GrammarTab({super.key});

  // Örnek kullanıcı ilerlemesi. Bu veriyi Firestore'dan veya başka bir state management çözümüyle yönetmelisiniz.
  final Map<String, double> userProgress = const {
    'A1': 1.0,   // %100 tamamlandı
    'A2': 0.75,  // %75 tamamlandı
    'B1': 0.33,  // %33 tamamlandı
    'B2': 0.0,
    'C1': 0.0,
    'C2': 0.0,
  };

  @override
  Widget build(BuildContext context) {
    final Map<String, List<Lesson>> lessonsByLevel = {};
    for (var lesson in grammarLessons) { // Artık grammarLessons listesi lesson_data.dart dosyasından geliyor.
      lessonsByLevel.putIfAbsent(lesson.level, () => []).add(lesson);
    }
    final levels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
    final levelColors = [
      Colors.green, Colors.lightBlue, Colors.orange,
      Colors.deepOrange, Colors.red, Colors.purple
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      itemCount: levels.length,
      itemBuilder: (context, index) {
        final level = levels[index];
        final lessonsInLevel = lessonsByLevel[level] ?? [];
        final progress = userProgress[level] ?? 0.0;
        final isLocked = (index > 0) && ((userProgress[levels[index - 1]] ?? 0.0) < 1.0);

        return LevelPathNode(
          level: level,
          lessonCount: lessonsInLevel.length,
          color: levelColors[index],
          progress: progress,
          isLocked: isLocked,
          isLeftAligned: index.isEven,
          onTap: isLocked ? null : () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GrammarLevelScreen(
                  level: level,
                  lessons: lessonsInLevel,
                  color: levelColors[index]
              ),
            ),
          ),
        );
      },
    );
  }
}

// --- PATİKA DÜĞÜMÜ (HER SEVİYE İÇİN) ---
class LevelPathNode extends StatelessWidget {
  final String level;
  final int lessonCount;
  final Color color;
  final double progress;
  final bool isLocked;
  final bool isLeftAligned;
  final VoidCallback? onTap;

  const LevelPathNode({
    super.key,
    required this.level,
    required this.lessonCount,
    required this.color,
    required this.progress,
    required this.isLocked,
    required this.isLeftAligned,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      child: Row(
        mainAxisAlignment: isLeftAligned ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (!isLeftAligned) const Spacer(),
          Column(
            crossAxisAlignment: isLeftAligned ? CrossAxisAlignment.start : CrossAxisAlignment.end,
            children: [
              InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 180,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isLocked
                          ? [Colors.grey.shade500, Colors.grey.shade600]
                          : [(color as MaterialColor).shade300, (color as MaterialColor).shade500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      if (!isLocked)
                        BoxShadow(
                          color: color.withAlpha((0.4 * 255).round()), // withOpacity(0.4)
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        )
                    ],
                  ),
                  child: Column(
                    children: [
                      if (isLocked)
                        Icon(Icons.lock_outline, color: Colors.white.withAlpha((0.8 * 255).round()), size: 48)
                      else
                        Text(
                          level,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              shadows: [Shadow(blurRadius: 10, color: Colors.black26)]
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        '$lessonCount Konu',
                        style: TextStyle(
                          color: Colors.white.withAlpha((0.9 * 255).round()),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (!isLocked)
                Container(
                  width: 180,
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      Icon(
                        progress == 1.0 ? Icons.check_circle : Icons.hourglass_empty,
                        color: progress == 1.0 ? Colors.green.shade700 : Colors.grey.shade600,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      )
                    ],
                  ),
                ),
            ],
          ),
          if (isLeftAligned) const Spacer(),
        ],
      ),
    );
  }
}


// --- GRAMER SEVİYE DETAY SAYFASI ---
class GrammarLevelScreen extends StatelessWidget {
  final String level;
  final List<Lesson> lessons;
  final MaterialColor color;

  const GrammarLevelScreen(
      {super.key,
        required this.level,
        required this.lessons,
        required this.color});

  @override
  Widget build(BuildContext context) {
    // GÜNCELLEME: Örnek tamamlanmış dersler listesi düzenlendi.
    final Set<String> completedLessons = {'Present Continuous'};

    return Scaffold(
      appBar: AppBar(
        title: Text('$level Gramer Konuları'),
        backgroundColor: color.shade400,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: lessons.length,
        itemBuilder: (context, index) {
          final lesson = lessons[index];
          final isCompleted = completedLessons.contains(lesson.title);
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            elevation: 2,
            shadowColor: Colors.black.withAlpha((0.1 * 255).round()),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isCompleted ? color.withAlpha((0.9 * 255).round()) : Colors.grey.shade200,
                child: Icon(
                  isCompleted ? Icons.check : lesson.icon,
                  color: isCompleted ? Colors.white : lesson.color,
                ),
                foregroundColor: Colors.white,
              ),
              title: Text(
                lesson.title,
                style: TextStyle(
                    decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                    color: isCompleted ? Colors.grey.shade600 : Colors.black87,
                    fontWeight: isCompleted ? FontWeight.normal : FontWeight.w600
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios,
                  size: 16, color: Colors.grey),
              onTap: () {
                // Yönlendirme için merkezi LessonRouter'ı kullan
                LessonRouter.navigateToLesson(context, lesson.contentPath, lesson.title);
              },
            ),
          );
        },
      ),
    );
  }
}