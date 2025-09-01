import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lingua_chat/data/lesson_data.dart';
import 'package:lingua_chat/models/lesson_model.dart';
import 'package:lingua_chat/navigation/lesson_router.dart';

// --- GRAMER SEKMESİ ANA WIDGET'I (OPTİMİZE EDİLMİŞ) ---
class GrammarTab extends StatefulWidget {
  const GrammarTab({super.key});

  @override
  State<GrammarTab> createState() => _GrammarTabState();
}

class _GrammarTabState extends State<GrammarTab> with TickerProviderStateMixin {
  // Kullanıcı ilerlemesi (Bu veri normalde bir servisten veya veritabanından gelir)
  final Map<String, double> userProgress = const {
    'A1': 1.0,
    'A2': 0.75,
    'B1': 0.33,
    'B2': 0.0,
    'C1': 0.0,
    'C2': 0.0,
  };

  // OPTİMİZASYON: Patika çizim animasyonu için tek seferlik bir controller.
  late final AnimationController _entryAnimationController;
  late final Animation<double> _pathAnimation;

  final levels = const ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
  final levelColors = const [
    Colors.green,
    Colors.lightBlue,
    Colors.orange,
    Colors.deepOrange,
    Colors.red,
    Colors.purple
  ];

  @override
  void initState() {
    super.initState();
    // OPTİMİZASYON: Controller'ın süresi kısaltıldı ve sadece bir kez ileriye çalışacak.
    _entryAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pathAnimation = CurvedAnimation(
      parent: _entryAnimationController,
      curve: Curves.easeInOutCubic,
    );

    _entryAnimationController.forward();
  }

  @override
  void dispose() {
    _entryAnimationController.dispose();
    super.dispose();
  }

  // Patika düğümlerinin pozisyonlarını hesaplayan yardımcı fonksiyon
  Offset _calculateNodePosition(int index, double width) {
    final double horizontalPadding = width / 4;
    final double verticalSpacing = 160.0;
    final double startY = 60.0; // 120.0'dan düşürüldü (üst boşluk azaltıldı)
    double x = (index % 2 == 0)
        ? horizontalPadding - 40
        : width - horizontalPadding - 80;
    double y = startY + (index * verticalSpacing);
    return Offset(x, y);
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, List<Lesson>> lessonsByLevel = {};
    for (var lesson in grammarLessons) {
      lessonsByLevel.putIfAbsent(lesson.level, () => []).add(lesson);
    }

    // OPTİMİZASYON: Yüksekliği içeriğe göre dinamik olarak hesapla
    final double totalHeight =
        60.0 + (levels.length * 160.0) + 100.0; // Üst boşluk azaltıldı (120 -> 60) + (seviye * boşluk) + bitiş payı

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: SizedBox(
        height: totalHeight,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // OPTİMİZASYON: Sürekli tekrar eden AnimatedBuilder yerine tek seferlik animasyon.
            AnimatedBuilder(
              animation: _pathAnimation,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(double.infinity, totalHeight),
                  painter: _CosmicPathPainter(
                    progress: _pathAnimation.value, // Animasyon değeri doğrudan veriliyor
                    levelColors: levelColors,
                  ),
                );
              },
            ),
            // Seviye düğümlerini oluştur
            ...List.generate(levels.length, (index) {
              final level = levels[index];
              final lessonsInLevel = lessonsByLevel[level] ?? [];
              final progress = userProgress[level] ?? 0.0;
              final isLocked = false; // Tüm seviyeler açık (kilit kaldırıldı)
              final position = _calculateNodePosition(
                  index, MediaQuery.of(context).size.width);

              return Positioned(
                top: position.dy,
                left: position.dx,
                child: _LevelPathNode(
                  level: level,
                  lessonCount: lessonsInLevel.length,
                  color: levelColors[index],
                  progress: progress,
                  isLocked: isLocked,
                  // OPTİMİZASYON: Giriş animasyonunu ana controller'a bağla
                  entryAnimation: _entryAnimationController,
                  animationDelay: index * 0.15, // Gecikmeyi biraz artırarak daha hoş bir sıralama sağla
                  onTap: isLocked
                      ? null
                      : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GrammarLevelScreen(
                        level: level,
                        lessons: lessonsInLevel,
                        color: levelColors[index],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// --- PATİKA DÜĞÜMÜ (SEVİYE YILDIZI) ---
class _LevelPathNode extends StatefulWidget {
  final String level;
  final int lessonCount;
  final Color color;
  final double progress;
  final bool isLocked;
  final Animation<double> entryAnimation; // OPTİMİZASYON: Dışarıdan animasyon controller'ı alır
  final double animationDelay;
  final VoidCallback? onTap;

  const _LevelPathNode({
    required this.level,
    required this.lessonCount,
    required this.color,
    required this.progress,
    required this.isLocked,
    required this.entryAnimation,
    required this.animationDelay,
    this.onTap,
  });

  @override
  State<_LevelPathNode> createState() => _LevelPathNodeState();
}

class _LevelPathNodeState extends State<_LevelPathNode>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation, _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // Nabız efekti için controller
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);

    // Giriş animasyonları için dışarıdan gelen controller'ı kullan
    final intervalCurve = CurvedAnimation(
        parent: widget.entryAnimation,
        curve: Interval(widget.animationDelay, (widget.animationDelay + 0.5).clamp(0.0, 1.0),
            curve: Curves.elasticOut));

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(intervalCurve);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(intervalCurve);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = widget.progress >= 1.0;
    final Color displayColor =
    widget.isLocked ? Colors.grey.shade700 : widget.color;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final pulseValue = 1 + (_pulseController.value * 0.05);
              return Transform.scale(
                scale: pulseValue,
                child: child,
              );
            },
            child: SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Dış parlama efekti
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        if (!widget.isLocked)
                          BoxShadow(
                            color: isCompleted
                                ? Colors.amber.withOpacity(0.7)
                                : displayColor.withOpacity(0.5),
                            blurRadius: isCompleted ? 30 : 20,
                            spreadRadius: isCompleted ? 5 : 2,
                          ),
                      ],
                    ),
                  ),
                  // Asıl seviye topu
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: widget.isLocked
                            ? [
                          Colors.grey.shade800,
                          Colors.grey.shade900
                        ]
                            : [
                          (widget.color as MaterialColor).shade300,
                          (widget.color as MaterialColor).shade700
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Center(
                      child: widget.isLocked
                          ? Icon(Icons.lock,
                          color: Colors.white.withOpacity(0.7),
                          size: 32)
                          : Text(
                        widget.level,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              blurRadius: 10,
                              color: Colors.black38,
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
       ),
      );

  }
}

// --- KOZMİK PATİKA ÇİZİCİ (OPTİMİZE EDİLMİŞ) ---
class _CosmicPathPainter extends CustomPainter {
  final double progress;
  final List<Color> levelColors;

  _CosmicPathPainter({required this.progress, required this.levelColors});

  // Patikayı sadece bir kez hesaplamak için
  Path _createPath(Size size) {
    final path = Path();
    // Tüm y koordinatları 60px yukarı kaydırıldı (160->100, 240->180 ...)
    path.moveTo(size.width * 0.25, 100);
    path.quadraticBezierTo(
        size.width * 0.8, 180, size.width * 0.75 - 40, 260);
    path.quadraticBezierTo(
        size.width * 0.1, 340, size.width * 0.25, 420);
    path.quadraticBezierTo(
        size.width * 0.9, 500, size.width * 0.75 - 40, 580);
    path.quadraticBezierTo(
        size.width * 0.2, 660, size.width * 0.25, 740);
    path.quadraticBezierTo(
        size.width * 0.8, 820, size.width * 0.75 - 40, 900);
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _createPath(size);

    // Sabit arka plan çizgisi
    final Paint basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.white.withOpacity(0.2);
    canvas.drawPath(path, basePaint);

    // OPTİMİZASYON: Sadece progress 0'dan büyükse çizim yap.
    if (progress > 0) {
      // Animasyonlu parlak çizgi
      final PathMetric pathMetric = path.computeMetrics().first;
      final Path extractPath =
      pathMetric.extractPath(0.0, pathMetric.length * progress);

      // Parlama efekti için boya
      final Paint glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8.0
        ..shader = LinearGradient(
            colors: levelColors.map((c) => c.withOpacity(0.5)).toList())
            .createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      // Ana yol için boya
      final Paint pathPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..shader = LinearGradient(colors: levelColors)
            .createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawPath(extractPath, glowPaint);
      canvas.drawPath(extractPath, pathPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CosmicPathPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// --- GRAMER SEVİYE DETAY SAYFASI (DEĞİŞİKLİK YOK) ---
class GrammarLevelScreen extends StatelessWidget {
  final String level;
  final List<Lesson> lessons;
  final MaterialColor color;

  const GrammarLevelScreen({
    super.key,
    required this.level,
    required this.lessons,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
            shadowColor: Colors.black.withAlpha(26),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isCompleted
                    ? color.withAlpha(230)
                    : Colors.grey.shade200,
                child: Icon(
                  isCompleted ? Icons.check : lesson.icon,
                  color:
                  isCompleted ? Colors.white : lesson.color,
                ),
                foregroundColor: Colors.white,
              ),
              title: Text(
                lesson.title,
                style: TextStyle(
                  decoration: isCompleted
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                  color: isCompleted
                      ? Colors.grey.shade600
                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.87),
                  fontWeight: isCompleted
                      ? FontWeight.normal
                      : FontWeight.w600,
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios,
                  size: 16, color: Colors.grey),
              onTap: () {
                LessonRouter.navigateToLesson(
                    context, lesson.contentPath, lesson.title);
              },
            ),
          );
        },
      ),
    );
  }
}