// lib/screens/home_screen.dart

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lingua_chat/screens/chat_screen.dart';
import 'package:lingua_chat/screens/store_screen.dart';
// DÜZELTME: Hatalı import yolları düzeltildi.
import 'package:lingua_chat/widgets/home_screen/challenge_card.dart';
import 'package:lingua_chat/widgets/home_screen/filter_bottom_sheet.dart';
import 'package:lingua_chat/widgets/home_screen/home_header.dart';
import 'package:lingua_chat/widgets/home_screen/level_assessment_card.dart';
import 'package:lingua_chat/widgets/home_screen/searching_ui.dart';
import 'package:lingua_chat/widgets/home_screen/stats_row.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _currentUser = FirebaseAuth.instance.currentUser;
  bool _isSearching = false;
  StreamSubscription? _matchListener;
  Future<String?>? _userNameFuture;

  String? _selectedGenderFilter;
  String? _selectedLevelGroupFilter;
  bool _isProUser = false;

  late AnimationController _entryAnimationController;
  late AnimationController _pulseAnimationController;
  late AnimationController _searchAnimationController;
  late PageController _pageController;
  double _pageOffset = 0;

  @override
  void initState() {
    super.initState();
    if (_currentUser != null) {
      _userNameFuture = _getUserName(_currentUser!.uid);
      _checkIfProUser();
    }

    _pageController = PageController(viewportFraction: 0.85)
    // DÜZELTME: '!' uyarısı için null kontrolü eklendi.
      ..addListener(() {
        final page = _pageController.page;
        if (mounted && page != null) {
          setState(() {
            _pageOffset = page;
          });
        }
      });

    _setupAnimations();
    _entryAnimationController.forward();
  }

  void _checkIfProUser() async {
    if (mounted) {
      setState(() => _isProUser = true);
    }
  }

  void _setupAnimations() {
    _entryAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _pulseAnimationController =
    AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _searchAnimationController =
    AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
  }

  Future<String?> _getUserName(String uid) async {
    try {
      final doc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return doc.data()?['displayName'] as String?;
    } catch (e) {
      return "Gezgin";
    }
  }

  @override
  void dispose() {
    _matchListener?.cancel();
    _entryAnimationController.dispose();
    _pulseAnimationController.dispose();
    _searchAnimationController.dispose();
    _pageController.removeListener(() {});
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _findPracticePartner() async {
    if (_currentUser == null || !mounted) return;
    setState(() => _isSearching = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final myId = _currentUser!.uid;
    final waitingPoolRef = FirebaseFirestore.instance.collection('waiting_pool');

    try {
      Query query = waitingPoolRef;

      if (_selectedGenderFilter != null) {
        query = query.where('gender', isEqualTo: _selectedGenderFilter);
      }
      if (_selectedLevelGroupFilter != null) {
        List<String> levelsToSearch = [];
        if (_selectedLevelGroupFilter == 'Başlangıç') {
          levelsToSearch = ['A1', 'A2'];
        } else if (_selectedLevelGroupFilter == 'Orta') {
          levelsToSearch = ['B1', 'B2'];
        } else if (_selectedLevelGroupFilter == 'İleri') {
          levelsToSearch = ['C1', 'C2'];
        }
        if (levelsToSearch.isNotEmpty) {
          query = query.where('level', whereIn: levelsToSearch);
        }
      }
      query = query.orderBy('waitingSince');

      final potentialMatches = await query.get();
      final otherUserDocs =
      potentialMatches.docs.where((doc) => doc.id != myId).toList();

      if (otherUserDocs.isNotEmpty) {
        final otherUserDoc = otherUserDocs.first;
        final otherUserId = otherUserDoc.id;
        final chatRoomId =
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final otherUserSnapshot =
          await transaction.get(otherUserDoc.reference);
          if (otherUserSnapshot.exists) {
            final newChatRoomRef =
            FirebaseFirestore.instance.collection('chats').doc();
            transaction.set(newChatRoomRef, {
              'users': [myId, otherUserId],
              'createdAt': FieldValue.serverTimestamp(),
              'status': 'active',
              '${myId}_lastActive': FieldValue.serverTimestamp(),
              '${otherUserId}_lastActive': FieldValue.serverTimestamp()
            });
            transaction.update(
                otherUserDoc.reference, {'matchedChatRoomId': newChatRoomRef.id});
            return newChatRoomRef.id;
          }
          return null;
        });
        if (chatRoomId != null) {
          _navigateToChat(chatRoomId);
        } else {
          scaffoldMessenger.showSnackBar(const SnackBar(
              content: Text('Partner başkasıyla eşleşti, yeniden aranıyor...'),
              duration: Duration(seconds: 2)));
          _findPracticePartner();
        }
      } else {
        final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(myId).get();
        final userData = userDoc.data();
        await waitingPoolRef.doc(myId).set({
          'userId': myId,
          'waitingSince': FieldValue.serverTimestamp(),
          'gender': userData?['gender'],
          'level': userData?['level'],
        });
        _listenForMatch();
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(SnackBar(
            content: Text('Arama sırasında bir hata oluştu: ${e.toString()}'),
            backgroundColor: Colors.red));
        await _cancelSearch();
      }
    }
  }

  void _listenForMatch() {
    if (_currentUser == null) return;
    _matchListener?.cancel();
    _matchListener = FirebaseFirestore.instance
        .collection('waiting_pool')
        .doc(_currentUser!.uid)
        .snapshots()
        .listen((snapshot) async {
      if (!mounted) return;
      if (snapshot.exists &&
          snapshot.data()!.containsKey('matchedChatRoomId')) {
        final chatRoomId = snapshot.data()!['matchedChatRoomId'] as String;
        await snapshot.reference.delete();
        _navigateToChat(chatRoomId);
      }
    });
  }

  Future<void> _cancelSearch() async {
    _matchListener?.cancel();
    if (_currentUser != null) {
      FirebaseFirestore.instance
          .collection('waiting_pool')
          .doc(_currentUser!.uid)
          .delete()
          .catchError((_) {});
    }
    if (mounted) setState(() => _isSearching = false);
  }

  void _navigateToChat(String chatRoomId) {
    if (!mounted) return;
    _matchListener?.cancel();
    setState(() => _isSearching = false);
    Navigator.push(
        context,
        PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                ChatScreen(chatRoomId: chatRoomId),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) =>
                FadeTransition(opacity: animation, child: child)));
  }

  void _showGenderFilter() {
    if (!_isProUser) {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Text('Premium Özellik'),
            content: const Text(
                'Cinsiyete göre partner arama özelliği Lingua Pro üyelerine özeldir.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Kapat')),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8))),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const StoreScreen()));
                  },
                  child: const Text('Pro\'ya Geç')),
            ],
          ));
      return;
    }

    showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        title: 'Cinsiyete Göre Filtrele',
        options: const ['Male', 'Female'],
        selectedOption: _selectedGenderFilter,
        displayLabels: const {'Male': 'Erkek', 'Female': 'Kadın'},
      ),
    ).then((selectedValue) {
      if (mounted) {
        setState(() {
          _selectedGenderFilter = selectedValue;
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
        title: 'Seviyeye Göre Filtrele',
        options: const ['Başlangıç', 'Orta', 'İleri'],
        selectedOption: _selectedLevelGroupFilter,
      ),
    ).then((selectedValue) {
      if (mounted) {
        setState(() {
          _selectedLevelGroupFilter = selectedValue;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        alignment: Alignment.center,
        children: [
          _buildHomeUI(),
          SearchingUI(
            isSearching: _isSearching,
            searchAnimationController: _searchAnimationController,
            onCancelSearch: _cancelSearch,
          ),
        ],
      ),
    );
  }

  Widget _buildHomeUI() {
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
                  interval: const Interval(0.2, 0.8),
                  child: HomeHeader(
                      userNameFuture:
                      _userNameFuture ?? Future.value('Gezgin'),
                      currentUser: _currentUser),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: _buildAnimatedUI(
                    interval: const Interval(0.4, 1.0),
                    child: const StatsRow()),
              ),
              const SizedBox(height: 24),
              _buildAnimatedUI(
                interval: const Interval(0.6, 1.0),
                child: _buildPartnerFinderSection(),
              ),
              const SizedBox(height: 24),
              _buildHorizontallyScrollableCards(),
              const SizedBox(height: 4),
              _buildPageIndicator(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    const int pageCount = 2;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        bool isActive = (_pageOffset.round() == index);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          height: isActive ? 10.0 : 8.0,
          width: isActive ? 10.0 : 8.0,
          decoration: BoxDecoration(
            color: isActive ? Colors.teal : Colors.grey.shade400,
            borderRadius: BorderRadius.circular(5.0),
          ),
        );
      }),
    );
  }

  Widget _buildAnimatedUI(
      {required Widget child, required Interval interval}) {
    return AnimatedBuilder(
      animation: _entryAnimationController,
      builder: (context, snapshot) {
        final animationValue =
        interval.transform(_entryAnimationController.value);
        return Opacity(
          opacity: animationValue,
          child: Transform.translate(
            offset: Offset(0, 50 * (1 - animationValue)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildHorizontallyScrollableCards() {
    return SizedBox(
      height: 150,
      child: PageView(
        controller: _pageController,
        children: [
          _buildCardPageItem(
            index: 0,
            child: const ChallengeCard(),
          ),
          _buildCardPageItem(
            index: 1,
            child: const LevelAssessmentCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildCardPageItem({required int index, required Widget child}) {
    Matrix4 matrix = Matrix4.identity();
    double scale;
    double gauss = 1 - (_pageOffset - index).abs();

    // DÜZELTME: '!' uyarısı için null coalescing operatörü (??) kullanıldı.
    scale = lerpDouble(0.8, 1.0, gauss) ?? 0.8;
    matrix.setEntry(3, 2, 0.001);
    matrix.rotateY((_pageOffset - index) * -0.5);

    return Transform(
      transform: matrix,
      alignment: Alignment.center,
      child: Transform.scale(
        scale: scale,
        child: child,
      ),
    );
  }

  Widget _buildPartnerFinderSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: _findPracticePartner,
          child: Hero(
            tag: 'find-partner-hero',
            child: AnimatedBuilder(
              animation: _pulseAnimationController,
              builder: (context, child) {
                final scale = 1.0 - (_pulseAnimationController.value * 0.05);
                // DÜZELTME: '!' uyarısı için null kontrolü eklendi.
                return Transform.scale(scale: scale, child: child ?? const SizedBox());
              },
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                        colors: [Colors.teal, Colors.cyan],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    boxShadow: [
                      BoxShadow(
                          color: const Color.fromARGB(102, 0, 150, 136),
                          blurRadius: 30,
                          spreadRadius: 5,
                          offset: const Offset(0, 15))
                    ]),
                child: const Material(
                  color: Colors.transparent,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.language_sharp,
                          color: Colors.white, size: 70),
                      SizedBox(height: 8),
                      Text('Partner Bul',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildFilterButton(
              icon: Icons.wc,
              label: 'Cinsiyet',
              onTap: _showGenderFilter,
              value: _selectedGenderFilter == 'Male'
                  ? 'Erkek'
                  : _selectedGenderFilter == 'Female'
                  ? 'Kadın'
                  : null,
            ),
            const SizedBox(width: 20),
            _buildFilterButton(
              icon: Icons.bar_chart_rounded,
              label: 'Seviye',
              onTap: _showLevelGroupFilter,
              value: _selectedLevelGroupFilter,
            ),
          ],
        )
      ],
    );
  }

  Widget _buildFilterButton(
      {required IconData icon,
        required String label,
        required VoidCallback onTap,
        String? value}) {
    final bool isActive = value != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          // DÜZELTME: Deprecated 'withOpacity' yerine 'withAlpha' kullanıldı.
          color: isActive ? Colors.teal.withAlpha(26) : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
              color: isActive ? Colors.teal : Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(20, 0, 0, 0),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.teal, size: 20),
            const SizedBox(width: 8),
            Text(
              isActive ? '$label: $value' : label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color:
                isActive ? Colors.teal.shade800 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}