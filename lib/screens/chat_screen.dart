// lib/screens/chat_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:lingua_chat/screens/report_user_screen.dart';
import 'package:lingua_chat/screens/root_screen.dart';
import 'package:lingua_chat/services/admin_service.dart';
import 'package:lingua_chat/screens/ban_user_screen.dart';
import 'package:lingua_chat/services/block_service.dart';
import 'package:lingua_chat/services/translation_service.dart';
import 'package:lingua_chat/services/linguabot_service.dart';
import 'package:lingua_chat/models/grammar_analysis.dart';
import 'package:speech_to_text/speech_to_text.dart';

class ChatScreen extends StatefulWidget {
  final String chatRoomId;
  const ChatScreen({super.key, required this.chatRoomId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final _currentUser = FirebaseAuth.instance.currentUser;
  final ScrollController _scrollController = ScrollController();

  StreamSubscription? _chatSubscription;
  Timer? _heartbeatTimer;
  String? _partnerId;
  Future<DocumentSnapshot>? _partnerFuture;
  bool _isPartnerPremium = false;
  bool _isCurrentUserPremium = false;
  String _currentUserNativeLanguage = 'en';
  bool _canBan = false;
  StreamSubscription<DocumentSnapshot>? _userPrefSub; // mevcut kullanıcı tercihleri
  StreamSubscription<DocumentSnapshot>? _partnerUserSub; // partner doc dinleyici
  // Engelleme durum dinleyicileri
  StreamSubscription<DocumentSnapshot>? _myBlockDocSub;
  StreamSubscription<DocumentSnapshot>? _theirBlockDocSub;

  // yeni: engelleme durum state'i
  bool _interactionAllowed = true;
  bool _blockedByMe = false;
  bool _blockedMe = false;

  late DateTime _chatStartTime;
  bool _isSaving = false;

  late AnimationController _shimmerController;

  final LinguaBotService _grammarService = LinguaBotService(); // premium analiz
  final Map<String, GrammarAnalysis> _grammarCache = {}; // lokal analiz cache (yalnız kendi mesajlarım)
  final Set<String> _analyzing = {}; // analiz devam eden mesaj id'leri

  int _messageLimit = 30; // sayfalama başlangıç limiti
  final int _messageIncrement = 30; // artış miktarı
  bool _isLoadingMore = false; // tekrar tetiklemeyi engelle
  bool _hasMore = true; // daha fazla veri var mı

  @override
  void initState() {
    super.initState();
    _chatStartTime = DateTime.now();
    _setupPartnerInfoAndStartHeartbeat();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _shimmerController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Timer(const Duration(seconds: 1), () {
          if (mounted) {
            _shimmerController.forward(from: 0.0);
          }
        });
      }
    });

    _scrollController.addListener(_onScrollLoadMore);
  }

  void _onScrollLoadMore() {
    if (!_hasMore || _isLoadingMore) return;
    if (!_scrollController.hasClients) return;
    // reverse:true olduğundan eski mesajlara yaklaşmak = maxScrollExtent'e yaklaşmak
    final pos = _scrollController.position;
    if (pos.pixels >= (pos.maxScrollExtent - 150)) {
      setState(() {
        _isLoadingMore = true;
        _messageLimit += _messageIncrement;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _chatSubscription?.cancel();
    _heartbeatTimer?.cancel();
    _shimmerController.dispose();
    _userPrefSub?.cancel();
    _partnerUserSub?.cancel();
    _myBlockDocSub?.cancel();
    _theirBlockDocSub?.cancel();
    _scrollController.removeListener(_onScrollLoadMore);
    super.dispose();
  }

  void _updateBlockStateFromCaches() {
    final allowed = !(_blockedByMe || _blockedMe);
    if (allowed != _interactionAllowed) {
      if (mounted) {
        setState(() {
          _interactionAllowed = allowed;
        });
      }
    }
  }

  Future<void> _refreshBlockState(String currentUserId, String partnerId) async {
    try {
      final usersColl = FirebaseFirestore.instance.collection('users');
      final results = await Future.wait([
        usersColl.doc(currentUserId).collection('blockedUsers').doc(partnerId).get(),
        usersColl.doc(partnerId).collection('blockedUsers').doc(currentUserId).get(),
      ]);
      _blockedByMe = results[0].exists;
      _blockedMe = results[1].exists;
      _updateBlockStateFromCaches();
    } catch (_) {
      if (mounted) {
        setState(() {
          _blockedByMe = false;
          _blockedMe = false;
          _interactionAllowed = true;
        });
      }
    }
  }

  Future<void> _setupPartnerInfoAndStartHeartbeat() async {
    final currentUser = _currentUser;
    if (currentUser == null) return;

    try {
      final chatDoc = await FirebaseFirestore.instance.collection('chats').doc(widget.chatRoomId).get();
      if (!mounted || !chatDoc.exists) return;

      final List<dynamic> users = chatDoc.data()?['users'];
      final partnerId = users.firstWhere((id) => id != currentUser.uid, orElse: () => null);
      _partnerId = partnerId;

      if (partnerId != null) {
        // Ban yetkisi kontrolü
        try {
          final allowed = await AdminService().canBanUser(partnerId);
          if (mounted) setState(() => _canBan = allowed);
        } catch (_) {
          if (mounted) setState(() => _canBan = false);
        }

        final partnerDocFuture = FirebaseFirestore.instance.collection('users').doc(partnerId).get();
        final currentUserDocFuture = FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();

        final results = await Future.wait([partnerDocFuture, currentUserDocFuture]);

        final partnerData = results[0].data();
        final currentUserData = results[1].data();

        if (mounted) {
          final isPremium = (partnerData?['isPremium'] as bool?) ?? false;
          _currentUserNativeLanguage = (currentUserData?['nativeLanguage'] as String?) ?? 'en';
          setState(() {
            _partnerFuture = Future.value(results[0]);
            _isPartnerPremium = isPremium;
            _isCurrentUserPremium = (currentUserData?['isPremium'] as bool?) ?? false;
          });
          if (isPremium) {
            _shimmerController.forward();
          }
        }

        // Kullanıcı tercihlerini dinle (dil vb.)
        _userPrefSub = FirebaseFirestore.instance.collection('users').doc(currentUser.uid).snapshots().listen((snap) {
          final data = snap.data();
          if (data == null) return;
          final nl = (data['nativeLanguage'] as String?) ?? 'en';
          if (mounted) {
            setState(() {
              _currentUserNativeLanguage = nl;
            });
          }
        });

        _partnerUserSub = FirebaseFirestore.instance.collection('users').doc(partnerId).snapshots().listen((snap) {
          final data = snap.data();
          if (data == null) return;
          final isPremium = (data['isPremium'] as bool?) ?? false;
          if (mounted) setState(() => _isPartnerPremium = isPremium);
        });

        // Engelleme durumunu dinle
        _myBlockDocSub = FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('blockedUsers')
            .doc(partnerId)
            .snapshots()
            .listen((doc) {
          _blockedByMe = doc.exists;
          _updateBlockStateFromCaches();
        });
        _theirBlockDocSub = FirebaseFirestore.instance
            .collection('users')
            .doc(partnerId)
            .collection('blockedUsers')
            .doc(currentUser.uid)
            .snapshots()
            .listen((doc) {
          _blockedMe = doc.exists;
          _updateBlockStateFromCaches();
        });

        // İlk kez engelleme durumunu getir
        await _refreshBlockState(currentUser.uid, partnerId);

        _listenToChatChanges();
        _startHeartbeat();
      }
    } catch (e) {
      // Hata yönetimi
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      final currentUser = _currentUser;
      if (currentUser != null) {
        FirebaseFirestore.instance
            .collection('chats')
            .doc(widget.chatRoomId)
            .update({'${currentUser.uid}_lastActive': FieldValue.serverTimestamp()});
      } else {
        timer.cancel();
      }
    });
  }

  void _listenToChatChanges() {
    final partnerId = _partnerId;
    if (partnerId == null) return;

    _chatSubscription = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatRoomId)
        .snapshots()
        .listen((snapshot) async {
      if (!mounted || !snapshot.exists) return;

      final data = snapshot.data()!;

      if (data['status'] == 'ended' && data['leftBy'] == partnerId) {
        await _endChatAndSaveChanges("Partneriniz sohbetten ayrıldı.");
        return;
      }

      final partnerLastActive = data['${partnerId}_lastActive'] as Timestamp?;
      if (partnerLastActive != null) {
        final difference = Timestamp.now().seconds - partnerLastActive.seconds;
        if (difference > 30) {
          await _endChatAndSaveChanges("Partnerinizin bağlantısı koptu.");
        }
      }
    });
  }

  Future<void> _savePracticeTime() async {
    final currentUser = _currentUser;
    if (currentUser == null) return;

    final chatDuration = DateTime.now().difference(_chatStartTime);
    final durationInMinutes = chatDuration.inMinutes;

    if (durationInMinutes > 0) {
      final userRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);
        if (!userDoc.exists) return;

        final userData = userDoc.data() as Map<String, dynamic>;

        int currentStreak = userData['streak'] ?? 0;
        Timestamp lastActivityTimestamp = userData['lastActivityDate'] ?? Timestamp.now();
        DateTime lastActivityDate = lastActivityTimestamp.toDate();
        DateTime now = DateTime.now();
        DateTime today = DateTime(now.year, now.month, now.day);
        DateTime lastActivityDay = DateTime(lastActivityDate.year, lastActivityDate.month, lastActivityDate.day);
        DateTime yesterday = today.subtract(const Duration(days: 1));

        int newStreak = 1;
        if (lastActivityDay.isAtSameMomentAs(today)) {
          newStreak = currentStreak;
        } else if (lastActivityDay.isAtSameMomentAs(yesterday)) {
          newStreak = currentStreak + 1;
        }

        transaction.update(userRef, {
          'totalPracticeTime': FieldValue.increment(durationInMinutes),
          'streak': newStreak,
          'lastActivityDate': Timestamp.now(),
        });
      });
    }
  }


  Future<void> _endChatAndSaveChanges(String message) async {
    if (_isSaving) return;
    _isSaving = true;

    _chatSubscription?.cancel();
    _heartbeatTimer?.cancel();
    _savePracticeTime();

    if (mounted) {
      _showPartnerLeftDialog(message);
    }
  }

  Future<void> _leaveChat() async {
    final currentUser = _currentUser;
    if (currentUser == null || _isSaving) return;
    _isSaving = true;

    _heartbeatTimer?.cancel();
    _chatSubscription?.cancel();
    await _savePracticeTime();

    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatRoomId)
          .update({
        'status': 'ended',
        'leftBy': currentUser.uid,
      });
    } catch (e) {
      // Hata yönetimi
    } finally {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const RootScreen()),
              (route) => false,
        );
      }
    }
  }

  Future<void> _blockOrUnblock() async {
    final partnerId = _partnerId;
    final currentUser = _currentUser;
    if (partnerId == null || currentUser == null) return;
    try {
      if (_blockedByMe) {
        // Engeli kaldır özelliği menüden kaldırıldığı için burada işlem yapılmıyor.
        return;
      } else {
        await BlockService().blockUser(currentUserId: currentUser.uid, targetUserId: partnerId);
        await _refreshBlockState(currentUser.uid, partnerId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kullanıcı engellendi.')),
          );
          // Sohbetten çık
          await _leaveChat();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: ${e.toString()}')),
        );
      }
    }
  }

  void _showPartnerLeftDialog(String message) {
    if (!mounted) return;
    final theme = Theme.of(context);
    final navigator = Navigator.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) {
        final Color surface = theme.colorScheme.surface;
        final Color onSurface = theme.colorScheme.onSurface.withValues(alpha: 0.85);
        final Color accent = theme.colorScheme.primary;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: surface,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.20), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(Icons.info_rounded, color: accent, size: 28),
                    ),
                    const SizedBox(height: 14),
                    Text('Sohbet Sona Erdi',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      style: theme.textTheme.bodyMedium?.copyWith(color: onSurface.withValues(alpha: 0.85)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.home_rounded),
                        label: const Text('Ana Sayfa'),
                        onPressed: () {
                          navigator.pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => const RootScreen()),
                                (route) => false,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleLeaveAttempt() {
    _showLeaveBottomSheet();
  }

  void _showLeaveBottomSheet() {
    if (!mounted) return;
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final Color surface = theme.colorScheme.surface;
        final Color onSurface = theme.colorScheme.onSurface.withValues(alpha: 0.85);
        final Color danger = Colors.red.shade600;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: surface,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.20), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: danger.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(Icons.logout_rounded, color: danger, size: 28),
                    ),
                    const SizedBox(height: 14),
                    Text('Sohbetten Ayrıl',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(
                      'Bu sohbeti sonlandırmak istediğinizden emin misiniz?',
                      style: theme.textTheme.bodyMedium?.copyWith(color: onSurface.withValues(alpha: 0.8)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: onSurface,
                              side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.4)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('İptal'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: danger,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            icon: const Icon(Icons.exit_to_app_rounded),
                            label: const Text('Ayrıl'),
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              _leaveChat();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleLeaveAttempt();
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE0F2F1), Color(0xFFB2DFDB)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          title: FutureBuilder<DocumentSnapshot>(
            future: _partnerFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Text('Yükleniyor...');
              }
              final partnerData = snapshot.data!.data() as Map<String, dynamic>;
              final avatarUrl = partnerData['avatarUrl'] as String?;
              final partnerName = partnerData['displayName'] ?? 'Bilinmeyen Kullanıcı';
              final role = partnerData['role'] as String?;
              final isPremium = (partnerData['isPremium'] as bool?) ?? false;

              Color baseColor;
              switch (role) {
                case 'admin':
                  baseColor = Colors.red;
                  break;
                case 'moderator':
                  baseColor = Colors.orange;
                  break;
                default:
                  baseColor = Colors.black87;
              }

              if (isPremium && !_shimmerController.isAnimating) {
                _shimmerController.forward(from: 0);
              }

              Widget nameWidget = isPremium
                  ? AnimatedBuilder(
                      animation: _shimmerController,
                      builder: (context, child) {
                        final value = _shimmerController.value;
                        final start = value * 1.5 - 0.5;
                        final end = value * 1.5;
                        final bool isSpecialRole = (role == 'admin' || role == 'moderator');
                        final Color shimmerBase = isSpecialRole ? baseColor : const Color(0xFFE5B53A);
                        return ShaderMask(
                          blendMode: BlendMode.srcIn,
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [shimmerBase, Colors.white, shimmerBase],
                            stops: [start, (start + end) / 2, end]
                                .map((e) => e.clamp(0.0, 1.0))
                                .toList(),
                          ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                          child: child,
                        );
                      },
                      child: Text(
                        partnerName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: (role == 'admin' || role == 'moderator') ? baseColor : const Color(0xFFE5B53A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  : Text(
                      partnerName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: baseColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    );

              return Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.teal.shade100,
                    child: avatarUrl != null
                        ? ClipOval(
                            child: SvgPicture.network(
                              avatarUrl,
                              placeholderBuilder: (context) => const SizedBox(
                                  width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2,)
                              ),
                              width: 36,
                              height: 36,
                            ),
                          )
                        : const Icon(Icons.person, color: Colors.teal),
                  ),
                  const SizedBox(width: 12),
                  Flexible(child: nameWidget),
                ],
              );
            },
          ),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'report') {
                  final partnerId = _partnerId;
                  if (partnerId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReportUserScreen(reportedUserId: partnerId),
                      ),
                    );
                  }
                } else if (value == 'ban') {
                  final partnerId = _partnerId;
                  if (partnerId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BanUserScreen(targetUserId: partnerId),
                      ),
                    );
                  }
                } else if (value == 'block') {
                  await _blockOrUnblock();
                }
              },
              itemBuilder: (BuildContext context) {
                final List<PopupMenuEntry<String>> items = [
                  if (!_blockedByMe)
                    const PopupMenuItem<String>(
                      value: 'block',
                      child: Row(
                        children: [
                          Icon(Icons.block, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Kullanıcıyı Engelle'),
                        ],
                      ),
                    ),
                  const PopupMenuItem<String>(
                    value: 'report',
                    child: Row(
                      children: [
                        Icon(Icons.report, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Kullanıcıyı Bildir'),
                      ],
                    ),
                  ),
                ];
                if (_canBan) {
                  items.add(
                    const PopupMenuItem<String>(
                      value: 'ban',
                      child: Row(
                        children: [
                          Icon(Icons.block, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Hesabı Banla'),
                        ],
                      ),
                    ),
                  );
                }
                return items;
              },
            ),
            IconButton(
              icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
              onPressed: _handleLeaveAttempt,
            )
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF7F9FC), Color(0xFFEFF3F6)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: <Widget>[
              if (!_interactionAllowed)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(28),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _blockedByMe
                        ? 'Bu kullanıcıyı engellediniz. Mesaj göndermek için engeli kaldırın.'
                        : 'Bu kullanıcı sizi engellemiş. Mesaj gönderemezsiniz.',
                    style: const TextStyle(color: Colors.black87),
                  ),
                ),
              // Çeviri modeli indirme durumu chip'i
              ValueListenableBuilder(
                valueListenable: TranslationService.instance.downloadState,
                builder: (context, state, _) {
                  if (state.inProgress && state.targetCode == _currentUserNativeLanguage) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.teal.withAlpha(18),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.teal.withAlpha(60)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 10),
                            Text('Çeviri modeli indiriliyor: ${state.downloaded}/${state.total}'),
                          ],
                        ),
                      ),
                    );
                  }
                  if (state.error != null && state.targetCode == _currentUserNativeLanguage) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.withAlpha(18),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.redAccent.withAlpha(80)),
                        ),
                        child: Text('Çeviri modeli indirilemedi: ${state.error}', style: const TextStyle(color: Colors.redAccent)),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('chats')
                      .doc(widget.chatRoomId)
                      .collection('messages')
                      .orderBy('createdAt', descending: true)
                      .limit(_messageLimit)
                      .snapshots(),
                  builder: (context, snapshot) {
                    // Spinner sadece ilk veri yokken gosterilsin; sonraki anlik gecikmelerde flicker olmasin
                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                          child: Text('Konuşmayı başlatmak için selam ver!'));
                    }
                    final chatDocs = snapshot.data!.docs;
                    // sayfalama durum güncelle
                    final reachedFullPage = chatDocs.length >= _messageLimit;
                    // Eğer isLoadingMore ve yeni snapshot geldi ise loadingMore false'a dön
                    if (_isLoadingMore) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) setState(() => _isLoadingMore = false);
                      });
                    }
                    // Daha fazla veri var mı: snapshot boyutu limitten küçüksa artık yok
                    final newHasMore = reachedFullPage; // limit doluysa muhtemelen devamı var
                    if (newHasMore != _hasMore) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) setState(() => _hasMore = newHasMore);
                      });
                    }
                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
                      itemCount: chatDocs.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (_hasMore && index == chatDocs.length) {
                          // üst tarafta (eski mesajlara) loader göstergesi
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Center(
                              child: SizedBox(
                                height: 20,
                                width: 20,
                                child: _isLoadingMore
                                    ? const CircularProgressIndicator(strokeWidth: 2)
                                    : const SizedBox.shrink(),
                              ),
                            ),
                          );
                        }
                        final doc = chatDocs[index];
                        final message = doc.data() as Map<String, dynamic>;
                        final isMe = message['userId'] == _currentUser?.uid;
                        final isPremium = isMe ? _isCurrentUserPremium : _isPartnerPremium;
                        final GrammarAnalysis? ga = isMe ? _grammarCache[doc.id] : null;
                        final bool analyzing = isMe && _analyzing.contains(doc.id);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                            children: [
                              if (!isMe)
                                Container(
                                  margin: const EdgeInsets.only(right: 8, top: 4),
                                  width: 28,
                                  height: 28,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFFB2DFDB),
                                  ),
                                  child: const Icon(Icons.person, size: 16, color: Color(0xFF00695C)),
                                ),
                              Flexible(
                                child: MessageBubble(
                                  key: ValueKey(doc.id),
                                  message: message['text'],
                                  timestamp: message['createdAt'],
                                  isMe: isMe,
                                  isPremium: isPremium,
                                  canTranslate: _isCurrentUserPremium && !isMe && _currentUserNativeLanguage != 'en',
                                  targetLanguageCode: _currentUserNativeLanguage,
                                  grammarAnalysis: ga,
                                  analyzing: analyzing,
                                  onRequestAnalysis: () async {
                                    if (!_isCurrentUserPremium) return;
                                    if (analyzing) return;
                                    setState(() => _analyzing.add(doc.id));
                                    final a = await _grammarService.analyzeGrammar(message['text']);
                                    if (!mounted) return;
                                    setState(() {
                                      _analyzing.remove(doc.id);
                                      if (a != null) _grammarCache[doc.id] = a;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              _MessageComposer(
                chatRoomId: widget.chatRoomId,
                currentUser: _currentUser,
                enabled: _interactionAllowed,
                isPremium: _isCurrentUserPremium,
                onAfterSend: (text, ref) async {
                  if (_isCurrentUserPremium) {
                    setState(() => _analyzing.add(ref.id));
                    final analysis = await _grammarService.analyzeGrammar(text);
                    if (!mounted) return;
                    setState(() {
                      _analyzing.remove(ref.id);
                      if (analysis != null) {
                        _grammarCache[ref.id] = analysis;
                      }
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ... (_MessageComposer widget'ı aynı kalır)
class _MessageComposer extends StatefulWidget {
  final String chatRoomId;
  final User? currentUser;
  final bool enabled;
  final bool isPremium; // premium flag
  final Future<void> Function(String text, DocumentReference ref)? onAfterSend; // analiz callback

  const _MessageComposer({required this.chatRoomId, required this.currentUser, this.enabled = true, this.isPremium = false, this.onAfterSend});

  @override
  State<_MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<_MessageComposer> {
  final _messageController = TextEditingController();
  bool _isComposing = false;
  bool _showEmoticons = false;

  // STT geri eklendi
  final SpeechToText _speech = SpeechToText();
  bool _speechReady = false;
  bool _listening = false;
  String _speechBaseText = '';

  final List<String> _textEmoticons = const [
    ':)', ':(', ';)', ':D', ':P', ':O', ':/', ':|', 'XD', 'T_T', '^^', '^^;', '>_<', '^_^', 'o_O', 'O_o', '-_-', '=_=',
    ':3', '>:(', ':-)', ':-(', ':-D', ':-P', ':-O', ':-|', ':-/', ';-)', '(^_^)', '(>_<)', '(T_T)', '(._.)', '(o_O)',
    '(^o^)/', '(¬_¬)', '(•_•)', '(•‿•)', '(☞ﾟ∀ﾟ)☞', '(づ｡◕‿‿◕｡)づ', '(╯°□°）��︵ ┻━┻', '┬─��� ノ( ゜-゜ノ)', '(ಥ﹏ಥ)', '(づ￣ ³￣)づ',
    '¯\\_(ツ)_/¯', '(ง •̀_•́)ง', '(*_*)', '(✿◠‿◠)', '(◕‿◕)', '(ᵔᴥᵔ)', '（＾ｖ＾）', '(ʘ‿ʘ)', '(ง’̀-’́)ง', '(✧ω✧)', '(◔_◔)', '(◕‿↼)',
    '(≧▽≦)', '(￣ー￣)', '(>‿◠)', '(✿╹◡╹)', '(��ᴗ◕✿)', '(*≧ω≦)', '(｡◕‿‿◕｡)', '(｀・ω・´)', '(；一_一)', '(●´ω｀●)', '(ノಠ益ಠ)ノ彡┻━┻',
    '(☞ ͡° ͜ʖ ͡°)☞', '( ͡° ͜ʖ ͡°)', '(⌐■_■)', '(●__●)', '(>_<)', '(^人^)', '(◡‿◡*)', '(✿´‿`)', '(●´∀｀●)', '(•̀ᴗ•́)و ̑̑',
    '(ᕗ ͠° ਊ ͠° )ᕗ', '(ノ´∀`)ノ', '(๑˃̵ᴗ˂̵)و', '(๑•̀ㅂ•́)و✧', '(´･_･`)', '(´；ω；`)', '(￣^￣)ゞ', '(-‿◦☀)', '(｡•̀ᴗ-)✧', '(~_^)', '(*￣▽￣)b',
    '(づᴗ_ᴗ)づ', 'ヽ(•‿•)ノ', '(งツ)���', 'ヽ(´ー｀)ノ', 'ಠ_ಠ', 'ʕ•ᴥ•ʔ', '(•ө•)♡', '(ง •̀ω•́)ง✧', '(✿◕‿◕)', '(~˘▾˘)~', '(•̀▁•́ )', '(*￣3￣)╭',
    'ヾ(＾-＾)ノ', '(〃＾▽＾〃)', '(￣ω￣;)', '(๑•́ ₃ •̀๑)', '(๑˘︶˘๑)', '(๑ᵕ⌓ᵕ๑)', '(´∀｀)♡', '(*^▽^*)', '(￣▽￣)ノ', 'ヽ(〃＾▽＾〃)ﾉ',
  ];

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      final isComposing = _messageController.text.isNotEmpty;
      if (_isComposing != isComposing) {
        setState(() {
          _isComposing = isComposing;
        });
      }
    });
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechReady = await _speech.initialize(onStatus: (s) {
      if (s == 'done' || s == 'notListening') {
        if (mounted) setState(() => _listening = false);
      }
    }, onError: (e) {
      if (mounted) setState(() => _listening = false);
    });
    if (mounted) setState(() {});
  }

  void _toggleEmoticons() {
    setState(() => _showEmoticons = !_showEmoticons);
  }

  Future<void> _toggleListening() async {
    if (!_speechReady) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cihaz konuşmayı tanımayı desteklemiyor veya izin verilmedi.')));
      return;
    }
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }
    _speechBaseText = _messageController.text;
    setState(() => _listening = true);
    await _speech.listen(onResult: (res) {
      final recognized = res.recognizedWords;
      final newText = (_speechBaseText.isEmpty ? recognized : (_speechBaseText + (recognized.isEmpty ? '' : ' ' + recognized)));
      _messageController.value = TextEditingValue(text: newText, selection: TextSelection.collapsed(offset: newText.length));
    });
  }

  void _insertEmoticon(String emo) {
    final text = _messageController.text;
    final sel = _messageController.selection;
    final start = sel.start >= 0 ? sel.start : text.length;
    final end = sel.end >= 0 ? sel.end : text.length;
    final newText = text.replaceRange(start, end, emo);
    _messageController.value = TextEditingValue(text: newText, selection: TextSelection.collapsed(offset: start + emo.length));
  }

  @override
  void dispose() {
    _messageController.dispose();
    if (_listening) {
      _speech.stop();
    }
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (!widget.enabled) return;
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || widget.currentUser == null) {
      return;
    }

    _messageController.clear();

    final ref = await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatRoomId)
        .collection('messages')
        .add({
      'text': messageText,
      'createdAt': Timestamp.now(),
      'userId': widget.currentUser!.uid,
      'serverAuth': true, // security rule gereği
    });

    FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatRoomId)
        .update({'${widget.currentUser!.uid}_lastActive': FieldValue.serverTimestamp()});

    if (widget.onAfterSend != null) {
      widget.onAfterSend!(messageText, ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canType = widget.enabled && widget.currentUser != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          decoration: const BoxDecoration(
            color: Colors.transparent,
          ),
          child: SafeArea(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28.0),
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.emoji_emotions_outlined),
                          color: _showEmoticons ? Colors.teal : Colors.grey[600],
                          onPressed: canType ? _toggleEmoticons : null,
                        ),
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            enabled: canType,
                            textCapitalization: TextCapitalization.sentences,
                            minLines: 1,
                            maxLines: 5,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Mesajını yaz...',
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(_listening ? Icons.mic : Icons.mic_none),
                          color: _listening ? Colors.teal : Colors.grey[600],
                          onPressed: canType ? _toggleListening : null,
                        ),
                        const SizedBox(width: 4),
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: (_isComposing && canType) ? Colors.teal : Colors.grey[400],
                          child: IconButton(
                            icon: const Icon(Icons.send_rounded, color: Colors.white),
                            onPressed: (_isComposing && canType) ? _sendMessage : null,
                          ),
                        ),
                        const SizedBox(width: 2),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_showEmoticons)
          Container(
            height: 180,
            margin: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: GridView.builder(
              itemCount: _textEmoticons.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 2.6,
              ),
              itemBuilder: (context, i) {
                final emo = _textEmoticons[i];
                return OutlinedButton(
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), side: BorderSide(color: Colors.grey.withAlpha(120)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () => _insertEmoticon(emo),
                  child: Text(emo, style: const TextStyle(fontSize: 12)),
                );
              },
            ),
          ),
      ],
    );
  }
}

class MessageBubble extends StatefulWidget {
  final String message;
  final Timestamp timestamp;
  final bool isMe;
  final bool isPremium;
  final bool canTranslate;
  final String targetLanguageCode;
  final GrammarAnalysis? grammarAnalysis; // premium kendi mesajı analizi
  final bool analyzing;
  final Future<void> Function()? onRequestAnalysis; // manuel yeniden dene

  const MessageBubble({super.key, required this.message, required this.timestamp, required this.isMe, this.isPremium = false, this.canTranslate = false, this.targetLanguageCode = 'en', this.grammarAnalysis, this.analyzing = false, this.onRequestAnalysis});

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  String? _translated;
  bool _translating = false;
  bool _showTranslation = true;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final isMe = widget.isMe;
    final formattedTime = DateFormat('HH:mm').format(widget.timestamp.toDate());
    final baseTextColor = isMe ? Colors.white : Colors.black87;

    Widget content;
    if (widget.canTranslate && _translated != null && _showTranslation) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.message, style: TextStyle(color: baseTextColor.withValues(alpha: 0.70), fontSize: 14, fontStyle: FontStyle.italic)),
          const SizedBox(height: 6),
          Text(_translated!, style: TextStyle(color: baseTextColor, fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      );
    } else {
      content = Text(widget.message, style: TextStyle(color: baseTextColor, fontSize: 16, height: 1.3));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Balon kutusu
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: widget.isPremium
                  ? LinearGradient(
                      colors: isMe
                          ? [const Color(0xFF26A69A), const Color(0xFF2BBBAD)]
                          : [Colors.white, Colors.white],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : (isMe
                      ? const LinearGradient(
                          colors: [Color(0xFF26A69A), Color(0xFF2BBBAD)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null),
              color: (!widget.isPremium && !isMe) ? Colors.white : null,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: !isMe ? const Radius.circular(6) : const Radius.circular(16),
                bottomRight: isMe ? const Radius.circular(6) : const Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: content,
          ),
          // Balon altı aksiyon satırı (çeviri butonu ve hatalar)
          if (widget.canTranslate)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4, right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(minimumSize: const Size(10, 32), padding: const EdgeInsets.symmetric(horizontal: 10)),
                    onPressed: _translating
                        ? null
                        : () async {
                            if (_translated != null) {
                              setState(() => _showTranslation = !_showTranslation);
                              return;
                            }
                            setState(() { _translating = true; _error = null; });
                            try {
                              await TranslationService.instance.ensureReady(widget.targetLanguageCode);
                              final tr = await TranslationService.instance.translateFromEnglish(widget.message, widget.targetLanguageCode);
                              setState(() { _translated = tr; _showTranslation = true; });
                            } catch (e) {
                              setState(() { _error = 'Çeviri başarısız: ${e.toString()}'; });
                            } finally {
                              if (mounted) setState(() { _translating = false; });
                            }
                          },
                    icon: _translating
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(_translated == null ? Icons.translate_outlined : (_showTranslation ? Icons.visibility_off : Icons.visibility), size: 16),
                    label: Text(_translated == null ? 'Çevir' : (_showTranslation ? 'Gizle' : 'Göster')),
                  ),
                ],
              ),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 8, right: 8),
              child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 11)),
            ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: Text(formattedTime, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
