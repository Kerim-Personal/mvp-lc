import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:vocachat/services/translation_service.dart';
import 'package:vocachat/services/ai_translation_service.dart';
import 'package:characters/characters.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:circle_flags/circle_flags.dart';
import 'package:vocachat/services/grammar_progress_service.dart';
import 'package:vocachat/data/lesson_data.dart';
import 'package:vocachat/models/lesson_model.dart';

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
  final bool enableTranslation; // görünürlük
  final String nativeLanguage; // user native language code, e.g. 'tr'
  final int maxLines;
  final int? characterLimit; // disable send if exceeded
  final bool showTranslationPanelInitially;
  final ValueChanged<bool>? onEmojiVisibilityChanged; // yeni: ebeveyne emoji açık/kapalı bildir
  final ValueChanged<bool>? onInputFocusChanged; // yeni: TextField fokus bildirimi
  final bool isPremium; // premium etkileşim izni
  final bool useAiTranslation; // VocaBot ekranına özel AI çeviri
  final String? aiTargetLanguage; // AI çeviri hedef dil kodu
  // Senaryo seçimi
  final String? selectedScenario;
  final ValueChanged<String?>? onScenarioChanged;
  // Yeni: Gramer pratik başlatma callback'i
  final ValueChanged<Lesson>? onGrammarPractice;

  const MessageComposer({super.key,
    required this.onSend,
    this.hintText = 'Message',
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
    this.isPremium = false,
    this.useAiTranslation = false,
    this.aiTargetLanguage,
    this.selectedScenario,
    this.onScenarioChanged,
    this.onGrammarPractice,
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

  // Geçici dil dokunma highlight
  String? _flashLang;
  Timer? _flashTimer;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _showEmojiPicker) {
        setState(() =>
        _showEmojiPicker = false); // Klavye açılırken emoji panelini kapat
        widget.onEmojiVisibilityChanged?.call(false);
      }
      widget.onInputFocusChanged?.call(_focusNode.hasFocus);
    });
    if (widget.enableSpeech) _initSpeech();
    _showTranslationPanel = widget.showTranslationPanelInitially;
  }

  void _onTextChanged() {
    final composing = _controller.text
        .trim()
        .isNotEmpty;
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
        _enLocaleId = locales
            .firstWhere((l) => l.localeId == 'en_US', orElse: () =>
            locales.firstWhere((l) => l.localeId.startsWith('en')))
            .localeId;
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
    _flashTimer?.cancel();
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(
          'Device does not support speech recognition or permission denied.')));
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
      final newText = (_speechBaseText.isEmpty ? recognized : (_speechBaseText +
          (recognized.isEmpty ? '' : ' ' + recognized)));
      _controller.value = TextEditingValue(text: newText,
          selection: TextSelection.collapsed(offset: newText.length));
    }, localeId: _enLocaleId ?? 'en_US');
  }

  void _insertEmoji(String emoji) {
    final text = _controller.text;
    final sel = _controller.selection;
    final start = sel.start >= 0 ? sel.start : text.length;
    final end = sel.end >= 0 ? sel.end : text.length;
    final newText = text.replaceRange(start, end, emoji);
    _controller.value = TextEditingValue(text: newText,
        selection: TextSelection.collapsed(offset: start + emoji.length));
  }

  Future<void> _selectTargetAndTranslate(String targetCode) async {
    if (!widget.enableTranslation)
      return;
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() {
        _translatedPreview = null;
      });
      return;
    }
    setState(() {
      _translating = true;
    });
    try {
      if (widget.useAiTranslation) {
        // AI modunda kaynak dili otomatik tespit etmesi için sourceCode göndermiyoruz.
        final result = await AiTranslationService.instance.translate(
          text: text,
          targetCode: targetCode,
        );
        if (!mounted) return;
        setState(() => _translatedPreview = result.trim());
      } else {
        final native = widget.nativeLanguage.toLowerCase();
        String detected = await TranslationService.instance.detectLanguage(
            text);
        if (detected == 'und') {
          if (targetCode == 'en') {
            detected = native;
          } else if (targetCode == native) {
            detected = 'en';
          } else {
            detected = native;
          }
        }
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
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Translation failed: $e')));
    } finally {
      if (mounted) setState(() => _translating = false);
    }
  }

  void _applyTranslatedToInput() {
    if (!widget.enableTranslation)
      return;
    final text = _translatedPreview?.trim();
    if (text == null || text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No translation to apply.')));
      return;
    }
    _controller.value = TextEditingValue(
        text: text, selection: TextSelection.collapsed(offset: text.length));
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
    final theme = Theme.of(context);

    String flagForLanguage(String code) {
      final base = code
          .toLowerCase()
          .split('-')
          .first;
      switch (base) {
        case 'en':
          return 'gb'; // veya 'us' tercih edilebilir
        case 'tr':
          return 'tr';
        case 'ar':
          return 'sa'; // Arapça
        case 'fa':
          return 'ir'; // Farsça
        case 'ps':
          return 'af'; // Peştuca
        case 'ur':
          return 'pk'; // Urduca
        case 'hi':
          return 'in'; // Hintçe
        case 'bn':
          return 'bd'; // Bengalce
        case 'zh':
          return 'cn'; // Çince (basitleştirilmiş varsayılan)
        case 'ja':
          return 'jp';
        case 'ko':
          return 'kr';
        case 'de':
          return 'de';
        case 'fr':
          return 'fr';
        case 'es':
          return 'es';
        case 'pt':
          return 'br'; // Portekizce (Brezilya yaygın)
        case 'it':
          return 'it';
        case 'ru':
          return 'ru';
        case 'uk':
          return 'ua';
        case 'pl':
          return 'pl';
        case 'nl':
          return 'nl';
        case 'sv':
          return 'se';
        case 'no':
          return 'no';
        case 'da':
          return 'dk';
        case 'fi':
          return 'fi';
        case 'el':
          return 'gr';
        case 'he':
          return 'il';
        case 'vi':
          return 'vn';
        case 'id':
          return 'id';
        case 'ms':
          return 'my';
        case 'th':
          return 'th';
        default:
          return base; // fallback: aynı kodu dene
      }
    }

    Widget langFlagButton(String code) {
      final flagCode = flagForLanguage(code);
      final bool highlight = _flashLang == code;
      return InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: _translating ? null : () {
          _flashTimer?.cancel();
          setState(() => _flashLang = code);
          _flashTimer = Timer(const Duration(milliseconds: 380), () {
            if (mounted) setState(() => _flashLang = null);
          });
          _selectTargetAndTranslate(code);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            border: Border.all(
              color: highlight ? theme.colorScheme.primary : theme.dividerColor
                  .withValues(alpha: 0.6),
              width: 1, // sabit
            ),
            borderRadius: BorderRadius.circular(26),
            color: highlight
                ? theme.colorScheme.primary.withValues(alpha: 0.22)
                : theme.colorScheme.surface,
          ),
          child: CircleFlag(flagCode, size: 24),
        ),
      );
    }

    if (widget.useAiTranslation) {
      final target = (widget.aiTargetLanguage ?? 'en').toLowerCase();
      if (target == native) {
        return langFlagButton(target);
      }
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          langFlagButton(native),
          const SizedBox(width: 8),
          langFlagButton(target),
        ],
      );
    }

    final bool isEnNative = native == 'en';
    if (isEnNative) {
      // Sadece EN varsa tek buton (tıklanınca yine çeviri tetiklenir)
      return langFlagButton('en');
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        langFlagButton(native),
        const SizedBox(width: 8),
        langFlagButton('en'),
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
        suffixIcon: _buildSuffixIcons(iconBase),
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
                ? LinearGradient(colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withValues(alpha: 0.7)
            ])
                : LinearGradient(colors: [
              theme.disabledColor.withValues(alpha: 0.5),
              theme.disabledColor.withValues(alpha: 0.3)
            ]),
            boxShadow: [
              if (_isComposing || _listening)
                BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.55),
                    blurRadius: 10,
                    offset: const Offset(0, 4)),
            ],
          ),
          child: SizedBox(
            width: 52,
            height: 52,
            child: IconButton(
              icon: Icon(
                _isComposing ? Icons.send_rounded : (_listening
                    ? Icons.mic
                    : Icons.mic_none),
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
                        margin: const EdgeInsets.only(bottom: 6),
                        // daha az boşluk
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(18), // küçültüldü
                          border: Border.all(color: theme.dividerColor
                              .withValues(alpha: 0.2)),
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
                                    color: _fade(
                                        theme.colorScheme.onSurface, 0.55),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Translation',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: _fade(
                                          theme.colorScheme.onSurface, 0.78),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (_translating)
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                  IconButton(
                                    splashRadius: 18,
                                    iconSize: 18,
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.close_rounded),
                                    onPressed: () =>
                                        setState(() =>
                                        _showTranslationPanel = false),
                                    tooltip: 'Close',
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            // İçerik ve butonlar: premium değilse etkileşimsiz
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12.0, vertical: 8.0),
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                        maxHeight: 80), // 120 -> 80
                                    child: SingleChildScrollView(
                                      child: Text(
                                        hasPreview
                                            ? _translatedPreview!
                                            : 'Translation will appear here...',
                                        style: TextStyle(
                                          color: onSurface.withValues(
                                              alpha: hasPreview
                                                  ? 0.9
                                                  : 0.5),
                                          fontSize: 13,
                                          height: 1.35,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const Divider(
                                    height: 1, indent: 12, endIndent: 12),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      10, 6, 10, 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment
                                        .spaceBetween,
                                    children: [
                                      Flexible(child: _buildLangToggle(
                                          theme.colorScheme.onSurface)),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        height: 34,
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                            padding: const EdgeInsets
                                                .symmetric(horizontal: 12,
                                                vertical: 6),
                                            shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius
                                                    .circular(14)),
                                          ),
                                          onPressed: hasPreview
                                              ? _applyTranslatedToInput
                                              : null,
                                          icon: const Icon(
                                              Icons.check_circle_outline,
                                              size: 16),
                                          label: const Text('Apply',
                                              style: TextStyle(
                                                  fontSize: 13)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
                        child: Text('Character limit exceeded (${widget
                            .characterLimit})',
                            style: TextStyle(fontSize: 11, color: theme
                                .colorScheme.error)),
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
                  bottomActionBarConfig: const BottomActionBarConfig(
                      enabled: false),
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

  Widget? _buildSuffixIcons(Color iconBase) {
    // Sadece çeviri etkinse (ikon görünürse) menüyü göster
    if (!widget.enableTranslation) return null;

    final translateButton = IconButton(
      icon: Icon(_showTranslationPanel ? Icons.translate_rounded : Icons.g_translate_outlined),
      splashRadius: 20,
      padding: const EdgeInsets.all(0),
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      color: iconBase.withValues(alpha: 0.6),
      onPressed: () => setState(() => _showTranslationPanel = !_showTranslationPanel),
      tooltip: 'Translate',
    );

    // WhatsApp tarzı ataç menüsü
    final attachButton = IconButton(
      icon: const Icon(Icons.attach_file_rounded),
      splashRadius: 20,
      padding: const EdgeInsets.all(0),
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      color: iconBase.withValues(alpha: 0.75),
      onPressed: widget.enabled ? _openAttachMenu : null,
      tooltip: 'Ekle',
    );

    return SizedBox(
      height: 40,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          attachButton,
          const SizedBox(width: 4),
          translateButton,
        ],
      ),
    );
  }

  Future<void> _openAttachMenu() async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withAlpha(245),
                Colors.black.withAlpha(220),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(
              color: Colors.cyanAccent.withAlpha(100),
              width: 1,
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(100),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Options
                _buildAttachOption(
                  ctx,
                  icon: Icons.movie_creation_outlined,
                  title: 'Scenarios',
                  subtitle: 'Practice conversation scenarios',
                  color: Colors.cyanAccent,
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await _openScenarioPicker();
                  },
                ),
                _buildAttachOption(
                  ctx,
                  icon: Icons.auto_stories_outlined,
                  title: 'Grammar',
                  subtitle: 'Grammar lessons and practice',
                  color: Colors.amberAccent,
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await _openGrammarPicker();
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttachOption(
    BuildContext ctx, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withAlpha(60),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withAlpha(200),
                        color.withAlpha(120),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: color.withAlpha(60),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.black,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withAlpha(180),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withAlpha(120),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openScenarioPicker() async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String q = '';
        String? selected = widget.selectedScenario;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final List<String> filtered = _defaultScenarios.where((s) {
              if (q.trim().isEmpty) return true;
              return s.toLowerCase().contains(q.toLowerCase());
            }).toList();
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(245),
                    Colors.black.withAlpha(220),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border.all(
                  color: Colors.cyanAccent.withAlpha(100),
                  width: 1,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle bar
                      Container(
                        margin: const EdgeInsets.only(top: 8, bottom: 16),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(100),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 16, 16),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.cyanAccent.withAlpha(200),
                                    Colors.cyanAccent.withAlpha(120),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.movie_creation_outlined,
                                color: Colors.black,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Choose Scenario',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Search and clear
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(10),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.cyanAccent.withAlpha(60),
                                    width: 1,
                                  ),
                                ),
                                child: TextField(
                                  decoration: const InputDecoration(
                                    hintText: 'Search scenarios...',
                                    hintStyle: TextStyle(color: Colors.white54),
                                    prefixIcon: Icon(Icons.search, color: Colors.cyanAccent, size: 18),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    isDense: true,
                                  ),
                                  style: const TextStyle(color: Colors.white),
                                  onChanged: (v) => setSheetState(() => q = v),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(10),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withAlpha(30),
                                  width: 1,
                                ),
                              ),
                              child: IconButton(
                                onPressed: () {
                                  widget.onScenarioChanged?.call(null);
                                  Navigator.of(ctx).pop();
                                },
                                icon: const Icon(Icons.clear_all, color: Colors.white70),
                                tooltip: 'Clear selection',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // List
                      Flexible(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          itemCount: filtered.length,
                          itemBuilder: (ctx, i) {
                            final s = filtered[i];
                            final bool isSel = selected == s;
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSel
                                  ? Colors.cyanAccent.withAlpha(20)
                                  : Colors.white.withAlpha(5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSel
                                    ? Colors.cyanAccent.withAlpha(80)
                                    : Colors.white.withAlpha(20),
                                  width: 1,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    widget.onScenarioChanged?.call(s);
                                    Navigator.of(ctx).pop();
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: isSel
                                              ? Colors.cyanAccent.withAlpha(150)
                                              : Colors.white.withAlpha(20),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.play_circle_outline,
                                            color: isSel ? Colors.black : Colors.white54,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            s,
                                            style: TextStyle(
                                              color: isSel ? Colors.cyanAccent : Colors.white,
                                              fontSize: 14,
                                              fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                        if (isSel)
                                          Icon(
                                            Icons.check_circle,
                                            color: Colors.cyanAccent,
                                            size: 20,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              );
          },
        );
      },
    );
  }

  Future<void> _openGrammarPicker() async {
    final completed = await GrammarProgressService.instance.getCompleted();
    final List<Lesson> all = List.of(grammarLessons);
    final List<Lesson> done = all.where((l) => completed.contains(l.contentPath)).toList();

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        int tabIndex = 0; // 0=Completed, 1=All
        String q = '';
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            List<Lesson> source = tabIndex == 0 ? done : all;
            List<Lesson> filtered = source.where((l) {
              if (q.trim().isEmpty) return true;
              final s = q.toLowerCase();
              return l.title.toLowerCase().contains(s) || l.level.toLowerCase().contains(s);
            }).toList();
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(245),
                    Colors.black.withAlpha(220),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border.all(
                  color: Colors.amberAccent.withAlpha(100),
                  width: 1,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle bar
                      Container(
                        margin: const EdgeInsets.only(top: 8, bottom: 16),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(100),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 16, 16),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.amberAccent.withAlpha(200),
                                    Colors.amberAccent.withAlpha(120),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.auto_stories_outlined,
                                color: Colors.black,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Choose Grammar Topic',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Filter tabs and search
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(10),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.amberAccent.withAlpha(60),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildGrammarTab('Completed', tabIndex == 0, () => setSheetState(() => tabIndex = 0)),
                                  _buildGrammarTab('All', tabIndex == 1, () => setSheetState(() => tabIndex = 1)),
                                ],
                              ),
                            ),
                            const Spacer(),
                            SizedBox(
                              width: 160,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(10),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.amberAccent.withAlpha(60),
                                    width: 1,
                                  ),
                                ),
                                child: TextField(
                                  decoration: const InputDecoration(
                                    hintText: 'Search...',
                                    hintStyle: TextStyle(color: Colors.white54),
                                    prefixIcon: Icon(Icons.search, color: Colors.amberAccent, size: 18),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    isDense: true,
                                  ),
                                  style: const TextStyle(color: Colors.white),
                                  onChanged: (v) => setSheetState(() => q = v),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // List
                      Flexible(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          itemCount: filtered.length,
                          itemBuilder: (ctx, i) {
                            final l = filtered[i];
                            final doneMark = completed.contains(l.contentPath);
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: doneMark
                                  ? Colors.greenAccent.withAlpha(15)
                                  : Colors.white.withAlpha(5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: doneMark
                                    ? Colors.greenAccent.withAlpha(80)
                                    : Colors.white.withAlpha(20),
                                  width: 1,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    Navigator.of(ctx).pop();
                                    widget.onGrammarPractice?.call(l);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: l.color.withAlpha(20),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: l.color.withAlpha(100),
                                              width: 1,
                                            ),
                                          ),
                                          child: Icon(
                                            l.icon,
                                            color: l.color,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                l.title,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                l.level,
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (doneMark)
                                          Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color: Colors.greenAccent,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Icon(
                                              Icons.check,
                                              color: Colors.black,
                                              size: 16,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              );
          },
        );
      },
    );
  }

  Widget _buildGrammarTab(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amberAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  static const List<String> _defaultScenarios = [
    // Günlük yaşam
    'Restoranda',
    'Kafede',
    'Yemek siparişi',
    'Restoran rezervasyonu',
    'Otelde (check-in)',
    'Otelde şikayet',
    'Havalimanında',
    'Uçakta',
    'Pasaport kontrolü',
    'Gümrükte',
    'Turist bilgi ofisi',
    'Otobüste',
    'Trende',
    'Taksiciyle',
    'Araç kiralama',
    'Benzin istasyonu',
    'Oto yıkamada',
    'Tamircide',
    'Kargo teslimi',
    'Postanede',
    'Banka işlemleri',
    'Hastanede',
    'Eczanede',
    'Doktor randevusu',
    'Dişçide',
    'Acil serviste',
    'Market alışverişi',
    'Alışveriş merkezinde',
    'Kıyafet denemesi',
    'İade ve değişim',
    'Kütüphanede',
    'Okulda',
    'Sınıfta',
    'Ödev danışma',
    'İş görüşmesi',
    'Ofiste',
    'Toplantıda',
    'Sunum yapma',
    'Telefonla müşteri hizmetleri',
    'Randevu ayarlama',
    'Yön tarifi sorma',
    'Adres tarif etme',
    'Müze ziyareti',
    'Parkta',
    'Spor salonunda',
    'Sinema',
    'Tiyatro',
    'Konserde',
    'Ev kiralama',
    'Ev gösterimi',
    'Komşuyla sohbet',
    'Şikayet bildirme',
  ];
}
