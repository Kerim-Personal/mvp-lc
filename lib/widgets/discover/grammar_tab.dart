import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:vocachat/data/lesson_data.dart';
import 'package:vocachat/models/lesson_model.dart';
import 'package:vocachat/navigation/lesson_router.dart';
import 'package:vocachat/services/grammar_progress_service.dart';

// --- GRAMER SEKMESİ ANA WIDGET'I (OPTİMİZE EDİLMİŞ) ---
class GrammarTab extends StatefulWidget {
  const GrammarTab({super.key, this.replayTrigger = 0});
  final int replayTrigger; // dışarıdan tetikleyici

  @override
  State<GrammarTab> createState() => _GrammarTabState();
}

class _GrammarTabState extends State<GrammarTab> with TickerProviderStateMixin {
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

  // Dinamik ilerleme
  Map<String, double> _levelProgress = {};
  bool _progressLoading = true;

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
    _computeProgress();
  }

  Future<void> _computeProgress() async {
    final completed = await GrammarProgressService.instance.getCompleted();
    // Grupla
    final Map<String, List<Lesson>> grouped = {};
    for (final l in grammarLessons) {
      grouped.putIfAbsent(l.level, () => []).add(l);
    }
    final Map<String, double> result = {};
    for (final level in levels) {
      final list = grouped[level] ?? [];
      if (list.isEmpty) {
        result[level] = 0;
        continue;
      }
      final done = list.where((l) => completed.contains(l.contentPath)).length;
      result[level] = done / list.length;
    }
    if (mounted) setState(() { _levelProgress = result; _progressLoading = false; });
  }

  @override
  void dispose() {
    _entryAnimationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant GrammarTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.replayTrigger != widget.replayTrigger) {
      _entryAnimationController.forward(from: 0);
      _computeProgress();
    }
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
              final progress = _progressLoading ? 0.0 : (_levelProgress[level] ?? 0.0);
              final position = _calculateNodePosition(index, MediaQuery.of(context).size.width);

              return Positioned(
                top: position.dy,
                left: position.dx,
                child: _LevelPathNode(
                  level: level,
                  lessonCount: lessonsInLevel.length,
                  color: levelColors[index],
                  progress: progress,
                  // isLocked konsepti şimdilik yok edildi
                  isLocked: false,
                  entryAnimation: _entryAnimationController,
                  animationDelay: index * 0.15,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GrammarLevelScreen(
                          level: level,
                          lessons: lessonsInLevel,
                          color: levelColors[index],
                        ),
                      ),
                    );
                    await _computeProgress();
                  },
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
                                ? Colors.amber.withValues(alpha: 0.7)
                                : displayColor.withValues(alpha: 0.5),
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
                          color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Center(
                      child: widget.isLocked
                          ? Icon(Icons.lock,
                          color: Colors.white.withValues(alpha: 0.7),
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
      ..color = Colors.white.withValues(alpha: 0.2);
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
            colors: levelColors.map((c) => c.withValues(alpha: 0.5)).toList())
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
class GrammarLevelScreen extends StatefulWidget {
  final String level;
  final List<Lesson> lessons;
  final MaterialColor color;
  const GrammarLevelScreen({super.key, required this.level, required this.lessons, required this.color});
  @override
  State<GrammarLevelScreen> createState() => _GrammarLevelScreenState();
}

class _GrammarLevelScreenState extends State<GrammarLevelScreen> {
  Set<String> _completedGlobal = {}; // tüm dersler
  Set<String> _completedLevel = {};  // sadece bu seviye dersleri
  double _progress = 0;
  bool _loading = true;

  Future<void> _loadProgress() async {
    final completed = await GrammarProgressService.instance.getCompleted();
    final ids = widget.lessons.map((l) => l.contentPath).toList();
    final progress = await GrammarProgressService.instance.levelProgress(widget.level, ids);
    final levelSet = ids.where(completed.contains).toSet();
    if (mounted) {
      setState(() {
        _completedGlobal = completed;
        _completedLevel = levelSet;
        _progress = progress;
        _loading = false;
      });
    }
  }

  @override
  void initState() { super.initState(); _loadProgress(); }

  Future<void> _openLesson(Lesson lesson) async {
    await LessonRouter.navigateToLesson(context, lesson.contentPath, lesson.title);
    await _loadProgress();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.color;
    final theme = Theme.of(context);
    final progressPct = (_progress * 100).round();
    final levelCompletedCount = _completedLevel.length;
    final levelTotal = widget.lessons.length;
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.level} Grammar Topics'),
        backgroundColor: base.shade500,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          minHeight: 10,
                          value: _loading ? 0 : _progress,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          valueColor: AlwaysStoppedAnimation(base.shade700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Text(
                        _loading ? '...' : '$progressPct%',
                        key: ValueKey(progressPct),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _loading ? 'Loading progress...' : '$levelCompletedCount/$levelTotal topics completed',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Divider(height: 24, thickness: 0.6),
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: widget.lessons.length,
              itemBuilder: (context, index) {
                final lesson = widget.lessons[index];
                final isCompleted = _completedGlobal.contains(lesson.contentPath);
                return _LessonTopicTile(
                  lesson: lesson,
                  color: widget.color,
                  isCompleted: isCompleted,
                  isNew: false,
                  onTap: () => _openLesson(lesson),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonTopicTile extends StatelessWidget {
  final Lesson lesson;
  final MaterialColor color;
  final bool isCompleted;
  final bool isNew;
  final VoidCallback onTap;
  const _LessonTopicTile({
    required this.lesson,
    required this.color,
    required this.isCompleted,
    required this.isNew,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final bg = dark
        ? Color.lerp(Colors.grey.shade900, color.shade800, 0.15)!
        : Color.lerp(Colors.white, color.shade50, 0.7)!;
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [bg, bg.withValues(alpha: 0.85)],
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: color.shade900.withValues(alpha: dark ? 0.15 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          )
        ],
        border: Border.all(
          color: isCompleted
              ? color.shade400.withValues(alpha: 0.6)
              : color.shade200.withValues(alpha: dark ? 0.4 : 0.7),
          width: 1.1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isCompleted
                        ? [color.shade600, color.shade800]
                        : [color.shade300, color.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.shade900.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    isCompleted ? Icons.check_rounded : lesson.icon,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            lesson.title,
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w600,
                              decoration: isCompleted ? TextDecoration.lineThrough : null,
                              color: isCompleted
                                  ? theme.colorScheme.onSurface.withValues(alpha: 0.55)
                                  : theme.colorScheme.onSurface.withValues(alpha: 0.9),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: -4,
                      children: [
                        if (isCompleted)
                          _StatusChip(
                            label: 'Completed',
                            color: color.shade600,
                            icon: Icons.verified_rounded,
                          )
                        else ...[
                          _StatusChip(
                            label: 'Topic',
                            color: color.shade300,
                            icon: Icons.menu_book_outlined,
                          )
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _StatusChip({required this.label, required this.color, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
