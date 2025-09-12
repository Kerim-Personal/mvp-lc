// lib/screens/home_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:lingua_chat/screens/partner_found_screen.dart';
import 'package:lingua_chat/widgets/home_screen/filter_bottom_sheet.dart';
import 'package:lingua_chat/widgets/home_screen/home_header.dart';
import 'package:lingua_chat/widgets/home_screen/searching_ui.dart';
import 'package:lingua_chat/widgets/home_screen/stats_row.dart';
import 'package:lingua_chat/widgets/home_screen/premium_upsell_dialog.dart';
import 'package:lingua_chat/widgets/home_screen/partner_finder_section.dart';
import 'package:lingua_chat/widgets/home_screen/home_cards_section.dart';
import 'package:lingua_chat/widgets/common/safety_help_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onSearchingChanged});
  final ValueChanged<bool>? onSearchingChanged;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _currentUser = FirebaseAuth.instance.currentUser;
  bool _isSearching = false;
  StreamSubscription? _matchListener;
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _userStream;

  String? _selectedGenderFilter;
  String? _selectedLevelGroupFilter;
  bool _isProUser = false;

  late AnimationController _entryAnimationController;
  late AnimationController _pulseAnimationController;
  // late AnimationController _searchAnimationController; // <-- HATA DÜZELTME 1: Bu satır kaldırıldı.
  late PageController _pageController;
  double _pageOffset = 1000;
  Timer? _cardScrollTimer;

  @override
  void initState() {
    super.initState();
    if (_currentUser != null) {
      _userStream = FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser.uid)
          .snapshots();
    }

    _pageController = PageController(viewportFraction: 0.85, initialPage: 1000)
      ..addListener(() {
        final page = _pageController.page;
        if (mounted && page != null) {
          setState(() {
            _pageOffset = page;
          });
        }
      });

    _setupAnimations();
    _startCardScrollTimer();
    _entryAnimationController.forward();
  }

  void _startCardScrollTimer() {
    _cardScrollTimer?.cancel(); // Mevcut zamanlayıcıyı iptal et
    _cardScrollTimer = Timer.periodic(const Duration(seconds: 7), (timer) {
      if (_isSearching || !mounted) return;
      _pageController.animateToPage(
        _pageController.page!.round() + 1,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    });
  }

  void _setupAnimations() {
    _entryAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500)); // Hızlandırıldı (1000 -> 500)
    _pulseAnimationController =
    AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    // _searchAnimationController = // <-- HATA DÜZELTME 2: Bu blok kaldırıldı.
    // AnimationController(vsync: this, duration: const Duration(seconds: 2))
    //   ..repeat();
  }

  @override
  void dispose() {
    _matchListener?.cancel();
    _cardScrollTimer?.cancel();
    _entryAnimationController.dispose();
    _pulseAnimationController.dispose();
    // _searchAnimationController.dispose(); // <-- HATA DÜZELTME 3: Bu satır kaldırıldı.
    _pageController.removeListener(() {});
    _pageController.dispose();
    super.dispose();
  }

  void _listenForMatch() {
    if (_currentUser == null) return;
    _matchListener?.cancel();
    _matchListener = FirebaseFirestore.instance
        .collection('waiting_pool')
        .doc(_currentUser.uid)
        .snapshots()
        .listen((snapshot) async {
      if (mounted && snapshot.exists && snapshot.data()?['matchedChatRoomId'] != null) {
        final chatRoomId = snapshot.data()!['matchedChatRoomId'] as String;
        _matchListener?.cancel();
        await snapshot.reference.delete();
        _navigateToChat(chatRoomId);
      }
    });
  }

  Future<void> _findPracticePartner() async {
    if (_currentUser == null || !mounted) return;

    setState(() => _isSearching = true);
    widget.onSearchingChanged?.call(true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final HttpsCallable callable =
          FirebaseFunctions.instance.httpsCallable('findMatch');
      final response = await callable.call(<String, dynamic>{
        'selectedGenderFilter': _selectedGenderFilter,
        'selectedLevelGroupFilter': _selectedLevelGroupFilter,
      });

      final status = response.data['status'];

      if (status == 'MATCH_FOUND') {
        final chatId = response.data['chatId'];
        _navigateToChat(chatId);
      } else if (status == 'ADDED_TO_POOL') {
        // User is in the waiting pool, start listening for a match
        _listenForMatch();
      } else {
        // Handle other statuses or errors
        throw Exception(response.data['message'] ?? 'Unknown error');
      }
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(SnackBar(
          content: Text(e.message ?? 'An error occurred.'),
          backgroundColor: Colors.red,
        ));
        await _cancelSearch();
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(SnackBar(
          content: Text('An unexpected error occurred: ${e.toString()}'),
          backgroundColor: Colors.red,
        ));
        await _cancelSearch();
      }
    }
  }

  Future<void> _cancelSearch() async {
    _matchListener?.cancel();
    if (_currentUser != null) {
      FirebaseFirestore.instance
          .collection('waiting_pool')
          .doc(_currentUser.uid)
          .delete()
          .catchError((_) {});
    }
    if (mounted) {
      setState(() => _isSearching = false);
      widget.onSearchingChanged?.call(false);
    }
  }

  void _navigateToChat(String chatRoomId) {
    if (!mounted) return;
    _matchListener?.cancel();
    setState(() => _isSearching = false);
    widget.onSearchingChanged?.call(false);
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => PartnerFoundScreen(chatRoomId: chatRoomId),
        transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  void _showGenderFilter() {
    showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        title: 'Filter by Gender',
        options: const ['Male', 'Female'],
        selectedOption: _selectedGenderFilter,
        displayLabels: const {'Male': 'Male', 'Female': 'Female'},
      ),
    ).then((selectedValue) {
      if (!mounted) return;
      if (selectedValue != null) {
        if (_isProUser) {
          setState(() {
            _selectedGenderFilter = selectedValue;
          });
        } else {
          showDialog(
            context: context,
            builder: (context) => const PremiumUpsellDialog(),
          );
        }
      } else {
        setState(() {
          _selectedGenderFilter = null;
        });
      }
    });
  }

  void _showLevelGroupFilter() {
    showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        title: 'Filter by Level Group',
        options: const ['Beginner', 'Intermediate', 'Advanced'],
        selectedOption: _selectedLevelGroupFilter,
      ),
    ).then((selectedValue) {
      if (!mounted) return;
      if (selectedValue != null) {
        if (_isProUser) {
          setState(() {
            _selectedLevelGroupFilter = selectedValue;
          });
        } else {
          showDialog(
            context: context,
            builder: (context) => const PremiumUpsellDialog(),
          );
        }
      } else {
        setState(() {
          _selectedLevelGroupFilter = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: const SafetyHelpButton(),
      body: Stack(
        alignment: Alignment.center,
        children: [
          _buildHomeUI(),
          SearchingUI(
            isSearching: _isSearching,
            // searchAnimationController: _searchAnimationController, // <-- HATA DÜZELTME 4: Bu parametre kaldırıldı.
            onCancelSearch: _cancelSearch,
            isPremium: _isProUser,
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
          role: 'user');
    }
    if (snap == null || !snap.exists || snap.data() == null) {
      return HomeHeader(
          userName: 'Loading...',
          avatarUrl: null,
          diamonds: 0,
          isPremium: false,
          currentUser: _currentUser,
          role: 'user');
    }
    final userData = snap.data()!;
    final userName = userData['displayName'] ?? 'Traveler';
    final avatarUrl = userData['avatarUrl'] as String?;
    final isPremium = userData['isPremium'] as bool? ?? false;
    final diamonds = userData['diamonds'] as int? ?? 0; // streak yerine diamonds
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
    );
  }

  Widget _buildStatsSection(DocumentSnapshot<Map<String, dynamic>>? snap) {
    if (_currentUser == null) {
      return const StatsRow(streak: 0, totalTime: 0, partnerCount: 0);
    }
    if (snap == null || !snap.exists || snap.data() == null) {
      return const StatsRow(streak: 0, totalTime: 0, partnerCount: 0);
    }
    final data = snap.data()!;
    final int streak = data['streak'] ?? 0;
    final int totalTime = data['totalPracticeTime'] ?? 0;
    final int partnerCount = data['partnerCount'] ?? 0;
    return StatsRow(streak: streak, totalTime: totalTime, partnerCount: partnerCount);
  }

  Widget _buildHomeUI() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _userStream,
      builder: (context, snapshot) {
        final userSnap = snapshot.data;
        return AnimatedOpacity(
          duration: const Duration(milliseconds: 400),
            opacity: _isSearching ? 0 : 1,
          child: IgnorePointer(
            ignoring: _isSearching,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: _buildAnimatedUI(
                      interval: const Interval(0.0, 0.6),
                      child: _buildHeaderSection(userSnap),
                    ),
                  ),
                  // Premium panel home ekranından kaldırıldı
                  // if (_isProUser) ...[
                  //   const SizedBox(height: 20),
                  //   Padding(
                  //     padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  //     child: _buildAnimatedUI(
                  //       interval: const Interval(0.05, 0.7),
                  //       child: const PremiumStatusPanel(),
                  //     ),
                  //   ),
                  // ],
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: _buildAnimatedUI(
                      interval: const Interval(0.1, 0.7),
                      child: _buildStatsSection(userSnap),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildAnimatedUI(
                    interval: const Interval(0.2, 0.8),
                    child: PartnerFinderSection(
                      onFindPartner: _findPracticePartner,
                      onShowGenderFilter: _showGenderFilter,
                      onShowLevelFilter: _showLevelGroupFilter,
                      selectedGenderFilter: _selectedGenderFilter,
                      selectedLevelGroupFilter: _selectedLevelGroupFilter,
                      pulseAnimationController: _pulseAnimationController,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Listener(
                    onPointerDown: (_) => _cardScrollTimer?.cancel(),
                    onPointerUp: (_) => _startCardScrollTimer(),
                    child: HomeCardsSection(
                      pageController: _pageController,
                      pageOffset: _pageOffset,
                    ),
                  ),
                  const SizedBox(height: 24),
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
