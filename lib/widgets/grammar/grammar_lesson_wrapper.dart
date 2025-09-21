// lib/widgets/grammar/grammar_lesson_wrapper.dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:vocachat/services/grammar_progress_service.dart';

class GrammarLessonWrapper extends StatefulWidget {
  final String contentPath; // lesson_data.dart içindeki contentPath
  final Widget child; // Mevcut bağımsız ders ekranı (genelde Scaffold döndürüyor)
  final Color? appBarColor; // AppBar rengini alma
  const GrammarLessonWrapper({super.key, required this.contentPath, required this.child, this.appBarColor});

  @override
  State<GrammarLessonWrapper> createState() => _GrammarLessonWrapperState();
}

class _GrammarLessonWrapperState extends State<GrammarLessonWrapper> with SingleTickerProviderStateMixin {
  bool _completed = false;
  bool _loading = true;
  bool _updating = false;
  bool _atEnd = false; // sayfa sonuna ulaşıldı mı
  bool _playCelebration = false; // tamamlanınca animasyon oynat
  late final AnimationController _lottieController;
  bool _lottieListenerAdded = false; // tekrar listener eklemeyi engelle

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
    _load();
  }

  @override
  void dispose() {
    _lottieController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final done = await GrammarProgressService.instance.isCompleted(widget.contentPath);
    if (mounted) setState(() { _completed = done; _loading = false; });
  }

  Future<void> _toggleCompleted() async {
    if (_updating) return;
    setState(() { _updating = true; });
    if (_completed) {
      await GrammarProgressService.instance.unmarkCompleted(widget.contentPath);
      if (mounted) setState(() { _completed = false; });
    } else {
      await GrammarProgressService.instance.markCompleted(widget.contentPath);
      if (mounted) {
        setState(() {
          _completed = true;
          _playCelebration = true; // animasyonu tetikle
        });
        // Animasyon kontrolü (composition yüklendikten sonra süre ayarlanacak)
      }
    }
    if (mounted) setState(() { _updating = false; });
  }

  bool get _showButton => !_loading && _atEnd; // sadece sonuna gelince

  bool _handleScroll(ScrollNotification n) {
    // Sadece kök (depth == 0) dikey scroll'ları dikkate al
    if (n.metrics.axis != Axis.vertical || n.depth != 0) return false;
    final max = n.metrics.maxScrollExtent;
    final pos = n.metrics.pixels;
    // İçerik kaydırılabiliyorsa (max > 0) alt sınır eşiğini kontrol et.
    // Kaydırılamıyorsa (max==0) otomatik göster (tek ekranlık içerik).
    final reached = max == 0 ? true : pos >= (max - 60);
    if (reached != _atEnd) {
      setState(() { _atEnd = reached; });
    }
    return false; // olayı yaymaya devam et
  }

  Widget _buildSuccessAnimation() {
    return Lottie.asset(
      'assets/animations/success.json',
      controller: _lottieController,
      fit: BoxFit.contain,
      onLoaded: (comp) {
        _lottieController
          ..duration = comp.duration
          ..forward(from: 0);
        if (!_lottieListenerAdded) {
          _lottieController.addStatusListener((status) {
            if (status == AnimationStatus.completed && mounted) {
              setState(() { _playCelebration = false; });
            }
          });
          _lottieListenerAdded = true;
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final btnDisabled = _loading || _updating;
    final label = _completed ? 'Completed (Undo)' : 'Mark as Completed';
    final Color bgColor = widget.appBarColor ?? Theme.of(context).colorScheme.primary;
    final Color fgColor = Colors.white; // AppBar üzerindeki tipik kontrast

    return NotificationListener<ScrollNotification>(
      onNotification: _handleScroll,
      child: Stack(
        children: [
          widget.child,
          if (_playCelebration)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: Center(
                  child: SizedBox(
                    width: 300,
                    height: 300,
                    child: _buildSuccessAnimation(),
                  ),
                ),
              ),
            ),
          // Buton sadece scroll sonuna gelince görünür
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !_showButton,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    offset: _showButton ? Offset.zero : const Offset(0, 0.2),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 280),
                      opacity: _showButton ? 1 : 0,
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            backgroundColor: bgColor,
                            foregroundColor: fgColor,
                            elevation: 4,
                          ),
                          icon: _updating
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Icon(_completed ? Icons.check_circle : Icons.flag_outlined, color: fgColor),
                          label: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          onPressed: btnDisabled ? null : _toggleCompleted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
