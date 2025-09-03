// lib/widgets/grammar/grammar_lesson_wrapper.dart
import 'package:flutter/material.dart';
import 'package:lingua_chat/services/grammar_progress_service.dart';

class GrammarLessonWrapper extends StatefulWidget {
  final String contentPath; // lesson_data.dart içindeki contentPath
  final Widget child; // Mevcut bağımsız ders ekranı (genelde Scaffold döndürüyor)
  const GrammarLessonWrapper({super.key, required this.contentPath, required this.child});

  @override
  State<GrammarLessonWrapper> createState() => _GrammarLessonWrapperState();
}

class _GrammarLessonWrapperState extends State<GrammarLessonWrapper> {
  bool _completed = false;
  bool _loading = true;
  bool _updating = false;
  bool _atEnd = false; // sayfa sonuna ulaşıldı mı

  @override
  void initState() {
    super.initState();
    _load();
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
      if (mounted) {
        setState(() { _completed = false; });
        // SnackBar kaldırıldı
      }
    } else {
      await GrammarProgressService.instance.markCompleted(widget.contentPath);
      if (mounted) {
        setState(() { _completed = true; });
        // SnackBar kaldırıldı
      }
    }
    if (mounted) setState(() { _updating = false; });
  }

  bool get _showButton => !_loading && _atEnd; // sadece sonuna gelince

  bool _handleScroll(ScrollNotification n) {
    final max = n.metrics.maxScrollExtent;
    final pos = n.metrics.pixels;
    final reached = max == 0 || pos >= (max - 60); // eşik
    if (reached != _atEnd) {
      setState(() { _atEnd = reached; });
    }
    return false; // olayı yaymaya devam et
  }

  @override
  Widget build(BuildContext context) {
    final btnDisabled = _loading || _updating;
    final label = _completed ? 'Completed (Undo)' : 'Mark as Completed';
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScroll,
      child: Stack(
        children: [
          widget.child,
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
                            backgroundColor: _completed ? Colors.green.shade600 : Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            elevation: 6,
                          ),
                          icon: _updating
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Icon(_completed ? Icons.check_circle : Icons.flag_outlined),
                          label: Text(
                            label,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
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
