// lib/widgets/community_screen/feed_post_card.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lingua_chat/screens/community_screen.dart';
import 'package:intl/intl.dart';
import 'package:lingua_chat/screens/comment_screen.dart';
import 'package:lingua_chat/screens/report_user_screen.dart';
import 'package:lingua_chat/screens/ban_user_screen.dart';
import 'package:lingua_chat/services/block_service.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';


class FeedPostCard extends StatefulWidget {
  final FeedPost post;
  final bool isPrivileged; // parent tanımlı (admin/moderator?)
  final bool canBanAccount; // parent tanımlı (ban menü ögesi gösterilsin mi)
  const FeedPostCard({super.key, required this.post, required this.isPrivileged, required this.canBanAccount});

  @override
  State<FeedPostCard> createState() => _FeedPostCardState();
}

class _FeedPostCardState extends State<FeedPostCard> with TickerProviderStateMixin {
  final currentUser = FirebaseAuth.instance.currentUser;
  late bool isLiked;
  late int likeCount;
  AnimationController? _shimmerController; // sadece premium için
  bool _isUserPremium = false;

  static final Map<String, Map<String, dynamic>> _userCache = {}; // userId -> {displayName, avatarUrl, role, isPremium}

  String? _displayNameOverride;
  String? _avatarOverride;
  String? _roleOverride;

  OnDeviceTranslator? _translator;
  static final Map<String, OnDeviceTranslator> _translatorCache = {}; // key: src>tgt
  static final Map<String, String?> _translationCache = {}; // key: postId|targetLang -> translated (null=fail)
  bool _translationSheetOpen = false;

  @override
  void initState() {
    super.initState();
    isLiked = widget.post.likes.contains(currentUser?.uid);
    likeCount = widget.post.likes.length;
    _hydrateFromCacheOrFetch();
  }

  Future<void> _hydrateFromCacheOrFetch() async {
    final uid = widget.post.userId;
    final cached = _userCache[uid];
    if (cached != null) {
      _applyUserData(cached);
      return;
    }
    try {
      final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!snap.exists) return;
      final data = snap.data() ?? {};
      final map = {
        'displayName': (data['displayName'] as String?)?.trim().isNotEmpty == true ? data['displayName'] : widget.post.userName,
        'avatarUrl': (data['avatarUrl'] as String?)?.trim().isNotEmpty == true ? data['avatarUrl'] : widget.post.userAvatarUrl,
        'role': data['role'],
        'isPremium': data['isPremium'] == true,
      };
      _userCache[uid] = map;
      if (mounted) _applyUserData(map);
    } catch (_) {
      // network hatası sessiz geç
    }
  }

  void _applyUserData(Map<String, dynamic> map) {
    setState(() {
      _displayNameOverride = map['displayName'] as String?;
      _avatarOverride = map['avatarUrl'] as String?;
      _roleOverride = map['role'] as String?;
      _isUserPremium = map['isPremium'] == true;
      if (_isUserPremium && _shimmerController == null) {
        _shimmerController = AnimationController(vsync: this, duration: const Duration(seconds: 4));
        _shimmerController!.addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            Timer(const Duration(seconds: 1), () {
              if (mounted) _shimmerController!.forward(from: 0.0);
            });
          }
        });
        _shimmerController!.forward();
      }
    });
  }

  @override
  void dispose() {
    _shimmerController?.dispose();
    _translator?.close();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    if (currentUser == null) return;

    final prevLiked = isLiked;
    final prevCount = likeCount;

    setState(() {
      isLiked = !isLiked;
      likeCount = isLiked ? likeCount + 1 : likeCount - 1;
    });

    final postRef = FirebaseFirestore.instance.collection('posts').doc(widget.post.id);
    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(postRef);
        if (!snap.exists) throw Exception('Post not found');
        final data = snap.data() as Map<String, dynamic>;
        final List<dynamic> raw = (data['likes'] as List<dynamic>? ) ?? [];
        final likes = raw.map((e) => e.toString()).toList();
        final uid = currentUser!.uid;
        if (isLiked) {
          if (!likes.contains(uid)) {
            likes.add(uid);
          }
        } else {
          likes.remove(uid);
        }
        tx.update(postRef, {'likes': likes});
      });
    } catch (e) {
      // Geri al
      if (mounted) {
        setState(() {
          isLiked = prevLiked;
          likeCount = prevCount;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update like: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _deletePost() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.post.id)
          .delete();
    }
  }

  Future<void> _blockUser() async {
    final me = currentUser;
    if (me == null) return;
    try {
      await BlockService().blockUser(currentUserId: me.uid, targetUserId: widget.post.userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User blocked.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  String _timeAgo(Timestamp timestamp) {
    final difference = DateTime.now().difference(timestamp.toDate());
    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('dd MMM yyyy', 'en_US').format(timestamp.toDate());
    }
  }

  // Basit heuristik dil tespiti (sınırlı)
  String _guessLangCode(String text) {
    final lower = text.toLowerCase();
    if (RegExp(r'[ğüşıçö]').hasMatch(lower)) return 'tr';
    if (RegExp(r'[àâçéèêëîïôûùüÿœ]').hasMatch(lower)) return 'fr';
    if (RegExp(r'[áéíñóúü]').hasMatch(lower)) return 'es';
    if (RegExp(r'[äöüß]').hasMatch(lower)) return 'de';
    if (RegExp(r'[àèéìíîòóùú]').hasMatch(lower) && lower.contains(' il ')) return 'it';
    if (RegExp(r'[ãõáâàéêíóôúç]').hasMatch(lower)) return 'pt';
    if (RegExp(r'[а-яё]').hasMatch(lower)) return 'ru';
    return 'en';
  }

  TranslateLanguage? _mapCode(String code) {
    switch (code) {
      case 'en': return TranslateLanguage.english;
      case 'tr': return TranslateLanguage.turkish;
      case 'es': return TranslateLanguage.spanish;
      case 'fr': return TranslateLanguage.french;
      case 'de': return TranslateLanguage.german;
      case 'it': return TranslateLanguage.italian;
      case 'pt': return TranslateLanguage.portuguese;
      case 'ru': return TranslateLanguage.russian;
      default: return null;
    }
  }

  Future<void> _ensureTranslator(String srcCode, String tgtCode) async {
    final key = '$srcCode>$tgtCode';
    if (_translatorCache.containsKey(key)) {
      _translator = _translatorCache[key];
      return;
    }
    final src = _mapCode(srcCode);
    final tgt = _mapCode(tgtCode);
    if (src == null || tgt == null) throw Exception('Unsupported language');
    final manager = OnDeviceTranslatorModelManager();
    // Hedef modeli indir (kaynak genelde device tarafından gerekirse indiriliyor)
    if (!await manager.isModelDownloaded(tgt.bcpCode)) {
      await manager.downloadModel(tgt.bcpCode);
    }
    if (!await manager.isModelDownloaded(src.bcpCode)) {
      await manager.downloadModel(src.bcpCode);
    }
    _translator = OnDeviceTranslator(sourceLanguage: src, targetLanguage: tgt);
    _translatorCache[key] = _translator!;
  }

  Future<String?> _getOrTranslateCached(String text) async {
    String targetCode = 'en';
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final data = snap.data();
        targetCode = (data?['nativeLanguage'] as String?)?.toLowerCase() ?? WidgetsBinding.instance.platformDispatcher.locale.languageCode.toLowerCase();
      }
    } catch (_) {}
    final srcCode = _guessLangCode(text);
    final cacheKey = '${widget.post.id}|$targetCode';
    // Aynı dil ise direkt orijinali döndür (cache de set edelim)
    if (srcCode == targetCode) {
      _translationCache[cacheKey] = text;
      return text;
    }
    if (_translationCache.containsKey(cacheKey)) {
      return _translationCache[cacheKey];
    }
    try {
      await _ensureTranslator(srcCode, targetCode);
      final translated = await _translator!.translateText(text);
      _translationCache[cacheKey] = translated;
      return translated;
    } catch (e) {
      _translationCache[cacheKey] = null; // başarısızlık işareti
      return null;
    }
  }

  void _openTranslationSheet() {
    if (_translationSheetOpen) return; // zaten açık
    _translationSheetOpen = true;
    final original = widget.post.postText.trim();
    final future = _getOrTranslateCached(original); // tek future
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16,12,16,16),
            child: FutureBuilder<String?>(
              future: future,
              builder: (c, snap) {
                final theme = Theme.of(c);
                Widget body;
                if (snap.connectionState == ConnectionState.waiting) {
                  body = Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Translating...', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(minHeight: 4),
                      const SizedBox(height: 16),
                      Text('Original', style: theme.textTheme.labelMedium),
                      const SizedBox(height: 4),
                      SelectableText(original),
                    ],
                  );
                } else {
                  final translated = snap.data;
                  final failed = !snap.hasData;
                  body = Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Translation', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Copy original',
                            icon: const Icon(Icons.copy_outlined),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: original));
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Original copied')));
                            },
                          ),
                          if (translated != null && translated != original)
                            IconButton(
                              tooltip: 'Copy translation',
                              icon: const Icon(Icons.translate),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: translated));
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Translation copied')));
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Original', style: theme.textTheme.labelMedium),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SelectableText(original),
                      ),
                      const SizedBox(height: 16),
                      if (!failed && translated != null && translated != original) ...[
                        Text('Translated', style: theme.textTheme.labelMedium),
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: SelectableText(translated),
                        ),
                      ] else if (failed) ...[
                        Text('Translation failed', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
                      ] else ...[
                        Text('No translation needed (already target language).', style: theme.textTheme.bodySmall),
                      ],
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Close'),
                        ),
                      )
                    ],
                  );
                }
                return SingleChildScrollView(child: body);
              },
            ),
          ),
        );
      },
    ).whenComplete(() {
      _translationSheetOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAuthor = currentUser?.uid == widget.post.userId;
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    Color roleColor(String? role) {
      switch (role) {
        case 'admin':
          return Colors.red;
        case 'moderator':
          return Colors.orange;
        default:
          return onSurface.withValues(alpha: 0.87);
      }
    }

    final displayName = _displayNameOverride ?? widget.post.userName;
    final avatarUrl = _avatarOverride ?? widget.post.userAvatarUrl;
    final role = _roleOverride; // null olabilir

    return Card(
      elevation: 2,
      shadowColor: Colors.grey.withValues(alpha: 0.2),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.grey.shade200,
                  child: ClipOval(
                    child: avatarUrl.isNotEmpty
                        ? SvgPicture.network(
                            avatarUrl,
                            placeholderBuilder: (context) => const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : const Icon(Icons.person, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: _isUserPremium && _shimmerController != null
                                ? AnimatedBuilder(
                                    animation: _shimmerController!,
                                    builder: (context, child) {
                                      final highlightColor = Colors.white;
                                      final value = _shimmerController!.value;
                                      final start = value * 1.5 - 0.5;
                                      final end = value * 1.5;
                                      final bool isSpecialRole = (role == 'admin' || role == 'moderator');
                                      final Color shimmerBase = isSpecialRole ? roleColor(role) : const Color(0xFFE5B53A);
                                      return ShaderMask(
                                        blendMode: BlendMode.srcIn,
                                        shaderCallback: (bounds) => LinearGradient(
                                          colors: [shimmerBase, highlightColor, shimmerBase],
                                          stops: [start, (start + end) / 2, end]
                                              .map((e) => e.clamp(0.0, 1.0))
                                              .toList(),
                                        ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                                        child: child!,
                                      );
                                    },
                                    child: Text(
                                      displayName,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: (role == 'admin' || role == 'moderator')
                                              ? roleColor(role)
                                              : const Color(0xFFE5B53A)),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  )
                                : Text(
                                    displayName,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: roleColor(role)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                          ),
                        ],
                      ),
                      Text(_timeAgo(widget.post.timestamp),
                          style: TextStyle(fontSize: 10, color: onSurface.withValues(alpha: 0.55))),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deletePost();
                    } else if (value == 'report') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReportUserScreen(
                            reportedUserId: widget.post.userId,
                            reportedContent: widget.post.postText,
                            reportedContentId: widget.post.id,
                          ),
                        ),
                      );
                    } else if (value == 'ban') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BanUserScreen(targetUserId: widget.post.userId),
                        ),
                      );
                    } else if (value == 'block') {
                      _blockUser();
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    List<PopupMenuEntry<String>> items = [];
                    if (isAuthor || widget.isPrivileged) {
                      items.add(
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete'),
                            ],
                          ),
                        ),
                      );
                    }
                    if (!isAuthor) {
                      items.add(
                        const PopupMenuItem<String>(
                          value: 'report',
                          child: Row(
                            children: [
                              Icon(Icons.report, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Report User'),
                            ],
                          ),
                        ),
                      );
                      items.add(
                        const PopupMenuItem<String>(
                          value: 'block',
                          child: Row(
                            children: [
                              Icon(Icons.block, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Block User'),
                            ],
                          ),
                        ),
                      );
                      if (widget.canBanAccount) {
                        items.add(
                          const PopupMenuItem<String>(
                            value: 'ban',
                            child: Row(
                              children: [
                                Icon(Icons.gavel, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Ban Account'),
                              ],
                            ),
                          ),
                        );
                      }
                    }
                    return items;
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onLongPress: _openTranslationSheet,
              child: Text(
                widget.post.postText,
                style: const TextStyle(fontSize: 15, height: 1.4),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildActionButton(
                  icon: isLiked ? Icons.favorite : Icons.favorite_border_outlined,
                  text: '$likeCount Likes',
                  color: isLiked ? Colors.red : null,
                  onTap: _toggleLike,
                ),
                _buildActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  text: '${widget.post.commentCount} Comments',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CommentScreen(postId: widget.post.id),
                      ),
                    );
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
      {required IconData icon,
        required String text,
        Color? color,
        required VoidCallback onTap}) {
    final theme = Theme.of(context);
    // Otomatik renk: koyu modda daha açık (onSurface yüksek opaklık), açık modda mevcut gri tonu
    final Color effectiveColor = color ?? (
      theme.brightness == Brightness.dark
          ? theme.colorScheme.onSurface.withValues(alpha: 0.85)
          : Colors.grey.shade800
    );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Row(
          children: [
            Icon(icon, size: 20, color: effectiveColor),
            const SizedBox(width: 6),
            Text(text,
                style: TextStyle(
                    color: effectiveColor,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
