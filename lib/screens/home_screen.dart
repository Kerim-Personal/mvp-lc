import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lingua_chat/screens/rooms_screen.dart';
import 'package:lingua_chat/widgets/home_screen/home_header.dart';
import 'package:lingua_chat/widgets/home_screen/stats_row.dart';
import 'package:lingua_chat/widgets/home_screen/partner_finder_section.dart';
import 'package:lingua_chat/widgets/home_screen/home_cards_section.dart';
import 'package:lingua_chat/widgets/common/safety_help_button.dart';
import 'package:lingua_chat/widgets/common/ai_partner_button.dart';
import 'package:lingua_chat/widgets/home_screen/profile_summary_content.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onSearchingChanged});
  final ValueChanged<bool>? onSearchingChanged;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _currentUser = FirebaseAuth.instance.currentUser;
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _userStream;

  bool _isProUser = false;

  late AnimationController _entryAnimationController;
  late AnimationController _pulseAnimationController;
  late PageController _pageController;
  double _pageOffset = 1000;
  Timer? _cardScrollTimer;

  // PageController listener'ını doğru şekilde kaldırabilmek için saklıyoruz
  VoidCallback? _pageControllerListener;

  @override
  void initState() {
    super.initState();
    // Alan tanıtımı yerine yerel değişken ile null-safety uyumlu erişim
    final user = _currentUser;
    if (user != null) {
      _userStream = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots();
    }

    _pageController = PageController(viewportFraction: 0.85, initialPage: 1000);
    _pageControllerListener = () {
      final page = _pageController.page;
      if (mounted && page != null) {
        setState(() {
          _pageOffset = page;
        });
      }
    };
    _pageController.addListener(_pageControllerListener!);

    _setupAnimations();
    _startCardScrollTimer();
    _entryAnimationController.forward();
  }

  void _startCardScrollTimer() {
    _cardScrollTimer?.cancel(); // Mevcut zamanlayıcıyı iptal et
    _cardScrollTimer = Timer.periodic(const Duration(seconds: 7), (timer) {
      if (!mounted) return;
      final page = _pageController.page;
      if (page != null) {
        _pageController.animateToPage(
          page.round() + 1,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _setupAnimations() {
    _entryAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _pulseAnimationController =
    AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _cardScrollTimer?.cancel();
    _entryAnimationController.dispose();
    _pulseAnimationController.dispose();
    if (_pageControllerListener != null) {
      _pageController.removeListener(_pageControllerListener!);
    }
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _findPracticePartner() async {
    if (!mounted) return;
    // RoomsScreen'i aç
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RoomsScreen(),
      ),
    );
  }

  void _navigateToStatsAndBadges() {
    if (!mounted) return;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'profile-summary',
      barrierColor: Colors.black.withValues(alpha: 0.35),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, sec, __) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
        return Opacity(
          opacity: anim.value,
          child: Center(
            child: Transform.scale(
              scale: 0.98 + 0.02 * curved.value,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxW = (constraints.maxWidth - 32).clamp(320.0, 560.0);
                  final maxH = (constraints.maxHeight * 0.88).clamp(420.0, 760.0);
                  return ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxW, maxHeight: maxH),
                    child: Material(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      elevation: 12,
                      borderRadius: BorderRadius.circular(16),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: const [
                          // İçerik kendi içinde scrollable
                          Expanded(child: ProfileSummaryContent()),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double safeBottom = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: Colors.transparent,
      // floatingActionButton kaldırıldı; ikisini de Stack içinde konumlandıracağız
      body: Stack(
        children: [
          _buildHomeUI(),
          // Solda AI Partner Button (yukarıya taşındı)
          Positioned(
            left: 16,
            bottom: safeBottom + 20,
            child: AiPartnerButton(),
          ),
          // Sağda Digital Safety Button (yukarıya taşındı)
          Positioned(
            right: 16,
            bottom: safeBottom + 20,
            child: SafetyHelpButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(DocumentSnapshot<Map<String, dynamic>>? snap) {
    if (_currentUser == null) {
      return HomeHeader(
          userName: 'Traveler',
          avatarUrl: null,
          diamonds: 0,
          isPremium: false,
          currentUser: _currentUser,
          role: 'user',
          onTap: _navigateToStatsAndBadges); // onTap eklendi
    }
    if (snap == null || !snap.exists || snap.data() == null) {
      return HomeHeader(
          userName: 'Loading...',
          avatarUrl: null,
          diamonds: 0,
          isPremium: false,
          currentUser: _currentUser,
          role: 'user',
          onTap: _navigateToStatsAndBadges); // onTap eklendi
    }
    final userData = snap.data()!;
    final userName = userData['displayName'] ?? 'Traveler';
    final avatarUrl = userData['avatarUrl'] as String?;
    final isPremium = userData['isPremium'] as bool? ?? false;
    final diamonds = userData['diamonds'] as int? ?? 0;
    final role = (userData['role'] as String?) ?? 'user';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _isProUser != isPremium) {
        setState(() => _isProUser = isPremium);
      }
    });

    return HomeHeader(
      userName: userName,
      avatarUrl: avatarUrl,
      isPremium: isPremium,
      diamonds: diamonds,
      currentUser: _currentUser,
      role: role,
      onTap: _navigateToStatsAndBadges, // onTap eklendi
    );
  }

  Widget _buildStatsSection(DocumentSnapshot<Map<String, dynamic>>? snap) {
    if (_currentUser == null) {
      return const StatsRow(streak: 0, totalTime: 0);
    }
    if (snap == null || !snap.exists || snap.data() == null) {
      return const StatsRow(streak: 0, totalTime: 0);
    }
    final data = snap.data()!;
    final int streak = data['streak'] ?? 0;
    final int totalTime = data['totalPracticeTime'] ?? 0;
    return StatsRow(
      streak: streak,
      totalTime: totalTime,
    );
  }

  Widget _buildHomeUI() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _userStream,
      builder: (context, snapshot) {
        final userSnap = snapshot.data;
        return SafeArea(
          child: SingleChildScrollView( // Column'u SingleChildScrollView ile sarmaladım
            physics: const NeverScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: _buildAnimatedUI(
                      interval: const Interval(0.0, 0.6),
                      child: _buildHeaderSection(userSnap),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: _buildAnimatedUI(
                      interval: const Interval(0.1, 0.7),
                      child: _buildStatsSection(userSnap),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildAnimatedUI(
                    interval: const Interval(0.2, 0.8),
                    child: PartnerFinderSection(
                      onFindPartner: _findPracticePartner,
                      pulseAnimationController: _pulseAnimationController,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // HomeCardsSection için sabit yükseklik belirledim
                  SizedBox(
                    height: 400, // Sabit yükseklik
                    child: Listener(
                      onPointerDown: (_) => _cardScrollTimer?.cancel(),
                      onPointerUp: (_) => _startCardScrollTimer(),
                      child: HomeCardsSection(
                        pageController: _pageController,
                        pageOffset: _pageOffset,
                      ),
                    ),
                  ),
                  const SizedBox(height: 100), // Alt boşluk artırıldı
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedUI(
      {required Widget child, required Interval interval}) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _entryAnimationController,
        curve: interval,
      ),
      child: child,
    );
  }
}