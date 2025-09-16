import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:lingua_chat/services/translation_service.dart';
import 'package:characters/characters.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

/// Reusable message / comment composer with optional:
/// - Speech to text
/// - Emoji picker (simple text emoticons)
/// - Translation preview (native <-> EN)
/// - Character limit
class MessageComposer extends StatefulWidget {
  final Future<void> Function(String text) onSend;
  final String hintText;
  final bool enabled;
  final bool enableSpeech;
  final bool enableEmojis;
  final bool enableTranslation;
  final String nativeLanguage; // user native language code, e.g. 'tr'
  final int maxLines;
  final int? characterLimit; // disable send if exceeded
  final bool showTranslationPanelInitially;
  final ValueChanged<bool>? onEmojiVisibilityChanged; // yeni: ebeveyne emoji açık/kapalı bildir
  final ValueChanged<bool>? onInputFocusChanged; // yeni: TextField fokus bildirimi

  const MessageComposer({super.key,
    required this.onSend,
    this.hintText = 'Type your message…',
    this.enabled = true,
    this.enableSpeech = true,
    this.enableEmojis = true,
    this.enableTranslation = false,
    required this.nativeLanguage,
    this.maxLines = 4,
    this.characterLimit,
    this.showTranslationPanelInitially = false,
    this.onEmojiVisibilityChanged,
    this.onInputFocusChanged,
  });

  @override
  State<MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<MessageComposer> {
  final TextEditingController _controller = TextEditingController();
  bool _isComposing = false;
  final FocusNode _focusNode = FocusNode();

  // Emoji picker görünürlüğü
  bool _showEmojiPicker = false;

  // Speech
  final SpeechToText _speech = SpeechToText();
  bool _speechReady = false;
  bool _listening = false;
  String _speechBaseText = '';
  String? _enLocaleId;

  // Translation
  bool _showTranslationPanel = false;
  bool _translating = false;
  String? _translatedPreview;
  String _selectedTargetCode = 'en';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _showEmojiPicker) {
        setState(() => _showEmojiPicker = false); // Klavye açılırken emoji panelini kapat
        widget.onEmojiVisibilityChanged?.call(false);
      }
      widget.onInputFocusChanged?.call(_focusNode.hasFocus);
    });
    if (widget.enableSpeech) _initSpeech();
    _showTranslationPanel = widget.showTranslationPanelInitially;
    _selectedTargetCode = widget.nativeLanguage == 'en' ? 'en' : widget.nativeLanguage; // default
  }

  void _onTextChanged() {
    final composing = _controller.text.trim().isNotEmpty;
    if (composing != _isComposing || _translatedPreview != null) {
      setState(() {
        _isComposing = composing;
        _translatedPreview = null; // invalidate previous translation
      });
    }
  }

  Future<void> _initSpeech() async {
    _speechReady = await _speech.initialize(onStatus: (s) {
      if (s == 'done' || s == 'notListening') {
        if (mounted) setState(() => _listening = false);
      }
    }, onError: (e) {
      if (mounted) setState(() => _listening = false);
    });
    if (_speechReady) {
      try {
        final locales = await _speech.locales();
        _enLocaleId = locales.firstWhere((l) => l.localeId == 'en_US', orElse: () => locales.firstWhere((l)=> l.localeId.startsWith('en'))).localeId;
      } catch (_) {
        _enLocaleId = 'en_US';
      }
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    if (_listening) _speech.stop();
    super.dispose();
  }

  void _toggleEmojiPicker() {
    if (!widget.enableEmojis) return;
    setState(() => _showEmojiPicker = !_showEmojiPicker);
    widget.onEmojiVisibilityChanged?.call(_showEmojiPicker);
    if (_showEmojiPicker) {
      FocusScope.of(context).unfocus();
    } else {
      // Panel kapandıysa kullanıcı yazmaya devam edebilmek için odak geri verilebilir.
      _focusNode.requestFocus();
    }
  }

  Future<void> _toggleListening() async {
    if (!widget.enableSpeech) return;
    if (!_speechReady) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Device does not support speech recognition or permission denied.')));
      return;
    }
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }
    _speechBaseText = _controller.text;
    setState(() => _listening = true);
    await _speech.listen(onResult: (res) {
      final recognized = res.recognizedWords;
      final newText = (_speechBaseText.isEmpty ? recognized : (_speechBaseText + (recognized.isEmpty ? '' : ' ' + recognized)));
      _controller.value = TextEditingValue(text: newText, selection: TextSelection.collapsed(offset: newText.length));
    }, localeId: _enLocaleId ?? 'en_US');
  }

  void _insertEmoji(String emoji) {
    final text = _controller.text;
    final sel = _controller.selection;
    final start = sel.start >= 0 ? sel.start : text.length;
    final end = sel.end >= 0 ? sel.end : text.length;
    final newText = text.replaceRange(start, end, emoji);
    _controller.value = TextEditingValue(text: newText, selection: TextSelection.collapsed(offset: start + emoji.length));
  }

  Future<void> _selectTargetAndTranslate(String targetCode) async {
    if (!widget.enableTranslation) return;
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() {
        _selectedTargetCode = targetCode;
        _translatedPreview = null;
      });
      return;
    }
    setState(() {
      _selectedTargetCode = targetCode;
      _translating = true;
    });
    try {
      final native = widget.nativeLanguage.toLowerCase();
      // Kaynak dili otomatik tespit et
      String detected = await TranslationService.instance.detectLanguage(text);
      if (detected == 'und') {
        // Belirsizse hedefe göre mantıklı varsayım
        if (targetCode == 'en') {
          detected = native; // muhtemelen anadil -> EN
        } else if (targetCode == native) {
          detected = 'en'; // muhtemelen EN -> anadil
        } else {
          detected = native; // varsayılan
        }
      }
      // Kaynak ve hedef aynıysa (ör: kullanıcı sadece düğmeye bastı) çeviri gereksiz
      if (detected == targetCode) {
        if (mounted) setState(() => _translatedPreview = text);
      } else {
        final result = await TranslationService.instance.translatePair(
          text,
          sourceCode: detected,
          targetCode: targetCode,
        );
        if (!mounted) return;
        setState(() => _translatedPreview = result.trim());
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Translation failed: $e')));
    } finally {
      if (mounted) setState(() => _translating = false);
    }
  }

  void _applyTranslatedToInput() {
    if (!widget.enableTranslation) return;
    final text = _translatedPreview?.trim();
    if (text == null || text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No translation to apply.')));
      return;
    }
    _controller.value = TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }

  bool get _overCharacterLimit {
    if (widget.characterLimit == null) return false;
    return _controller.text.characters.length > widget.characterLimit!;
  }

  Future<void> _handleSend() async {
    if (!_isComposing || !widget.enabled || _overCharacterLimit) return;
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final toSend = text;
    _controller.clear();
    setState(() {
      _translatedPreview = null;
      _isComposing = false;
    });
    await widget.onSend(toSend);
  }

  Widget _buildLangToggle(Color onSurface) {
    final native = widget.nativeLanguage.toLowerCase();
    final bool isEnNative = native == 'en';
    final theme = Theme.of(context);

    Widget pillButton(String code) {
      final bool selected = _selectedTargetCode == code;
      return InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _translating ? null : () => _selectTargetAndTranslate(code),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? _fade(theme.colorScheme.primary, 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: selected ? Colors.transparent : theme.dividerColor),
          ),
          child: Text(
            code.toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: selected ? theme.colorScheme.primary : _fade(onSurface, 0.7),
            ),
          ),
        ),
      );
    }

    if (isEnNative) {
      return pillButton('en');
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        pillButton(native),
        const SizedBox(width: 8),
        pillButton('en'),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool hasPreview =
        _translatedPreview != null && _translatedPreview!.trim().isNotEmpty;
    final Color onSurface = theme.colorScheme.onSurface;
    final Color iconBase = theme.iconTheme.color ?? onSurface;

    final textField = TextField(
      controller: _controller,
      focusNode: _focusNode,
      enabled: widget.enabled,
      textCapitalization: TextCapitalization.sentences,
      minLines: 1,
      maxLines: widget.maxLines,
      cursorColor: theme.colorScheme.primary,
      style: const TextStyle(fontSize: 16, height: 1.4),
      decoration: InputDecoration(
        prefixIcon: widget.enableEmojis
            ? IconButton(
                icon: Icon(_showEmojiPicker
                    ? Icons.keyboard_hide_rounded
                    : Icons.emoji_emotions_outlined),
                splashRadius: 20,
                padding: const EdgeInsets.all(0),
                constraints:
                    const BoxConstraints(minWidth: 40, minHeight: 40),
                color: iconBase.withValues(alpha: 0.6),
                onPressed: widget.enabled ? _toggleEmojiPicker : null,
                tooltip: 'Emoji',
              )
            : null,
        suffixIcon: widget.enableTranslation
            ? IconButton(
                icon: Icon(_showTranslationPanel
                    ? Icons.translate_rounded
                    : Icons.g_translate_outlined),
                splashRadius: 20,
                padding: const EdgeInsets.all(0),
                constraints:
                    const BoxConstraints(minWidth: 40, minHeight: 40),
                color: iconBase.withValues(alpha: 0.6),
                onPressed: () =>
                    setState(() => _showTranslationPanel = !_showTranslationPanel),
                tooltip: 'Translate',
              )
            : null,
        hintText: widget.hintText,
        hintStyle: TextStyle(color: theme.hintColor.withValues(alpha: 0.8)),
        filled: true,
        fillColor: isDark
            ? Colors.grey.shade800.withValues(alpha: 0.8)
            : Colors.white.withValues(alpha: 0.9),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: theme.dividerColor, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: theme.dividerColor, width: 1.5),
        ),
      ),
    );

    final inputRow = Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: textField),
        const SizedBox(width: 4),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: (_isComposing || _listening)
                ? LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.7)])
                : LinearGradient(colors: [theme.disabledColor.withValues(alpha: 0.5), theme.disabledColor.withValues(alpha: 0.3)]),
            boxShadow: [
              if (_isComposing || _listening)
                BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.55), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: SizedBox(
            width: 52,
            height: 52,
            child: IconButton(
              icon: Icon(
                _isComposing ? Icons.send_rounded : (_listening ? Icons.mic : Icons.mic_none),
                color: Colors.white,
                size: 24,
              ),
              onPressed: !widget.enabled
                  ? null
                  : () async {
                      if (_isComposing) {
                        await _handleSend();
                      } else {
                        await _toggleListening();
                      }
                    },
              splashRadius: 30,
            ),
          ),
        ),
      ],
    );

    // PopScope: Geri tuşu önce emoji panelini/klavyeyi kapatsın (predictive back uyumlu)
    return PopScope(
      canPop: !(_showEmojiPicker || _focusNode.hasFocus),
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_showEmojiPicker) {
          setState(() => _showEmojiPicker = false);
          return;
        }
        if (_focusNode.hasFocus) {
          _focusNode.unfocus();
          return;
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.transparent,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.enableTranslation && _showTranslationPanel)
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOutCubic,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6), // daha az boşluk
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(18), // küçültüldü
                          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.035),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 6, 4, 4),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.translate_rounded,
                                    size: 16,
                                    color: _fade(theme.colorScheme.onSurface, 0.55),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Translation',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: _fade(theme.colorScheme.onSurface, 0.78),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (_translating)
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  IconButton(
                                    splashRadius: 18,
                                    iconSize: 18,
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.close_rounded),
                                    onPressed: () => setState(() => _showTranslationPanel = false),
                                    tooltip: 'Close',
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxHeight: 80), // 120 -> 80
                                child: SingleChildScrollView(
                                  child: Text(
                                    hasPreview ? _translatedPreview! : 'Translation will appear here...',
                                    style: TextStyle(
                                      color: onSurface.withValues(alpha: hasPreview ? 0.9 : 0.5),
                                      fontSize: 13,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const Divider(height: 1, indent: 12, endIndent: 12),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(child: _buildLangToggle(theme.colorScheme.onSurface)),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    height: 34,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      ),
                                      onPressed: hasPreview ? _applyTranslatedToInput : null,
                                      icon: const Icon(Icons.check_circle_outline, size: 16),
                                      label: const Text('Apply', style: TextStyle(fontSize: 13)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  inputRow,
                  if (_overCharacterLimit)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6, right: 4),
                        child: Text('Character limit exceeded (${widget.characterLimit})', style: TextStyle(fontSize: 11, color: theme.colorScheme.error)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_showEmojiPicker && widget.enableEmojis)
            SizedBox(
              height: 300,
              child: EmojiPicker(
                 onEmojiSelected: (category, emoji) {
                   _insertEmoji(emoji.emoji);
                 },
                 config: Config(
                   height: 300,
                   checkPlatformCompatibility: true,
                   emojiViewConfig: const EmojiViewConfig(
                    emojiSizeMax: 28,
                    backgroundColor: Colors.transparent,
                  ),
                  categoryViewConfig: CategoryViewConfig(
                    backgroundColor: theme.cardColor,
                    iconColor: _fade(iconBase, 0.55),
                    iconColorSelected: theme.colorScheme.primary,
                    indicatorColor: theme.colorScheme.primary,
                  ),
                  bottomActionBarConfig: const BottomActionBarConfig(enabled: false),
                  skinToneConfig: const SkinToneConfig(enabled: true),
                  searchViewConfig: SearchViewConfig(
                    backgroundColor: theme.cardColor,
                    hintText: 'Ara',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _fade(Color base, double alpha) {
    return base.withValues(alpha: alpha);
  }
}
