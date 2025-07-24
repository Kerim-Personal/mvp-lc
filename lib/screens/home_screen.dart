import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lingua_chat/screens/chat_screen.dart';
import 'package:lingua_chat/screens/login_screen.dart';
import 'package:lingua_chat/services/auth_service.dart';
import 'package:lingua_chat/widgets/home_screen/challenge_card.dart';
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
  final AuthService _authService = AuthService();
  final _currentUser = FirebaseAuth.instance.currentUser;
  bool _isSearching = false;
  StreamSubscription? _matchListener;
  Future<String?>? _userNameFuture;

  late AnimationController _entryAnimationController;
  late AnimationController _pulseAnimationController;
  late AnimationController _searchAnimationController;

  late Animation<double> _headerFade, _statsFade, _buttonFade, _cardFade, _levelCardFade;
  late Animation<Offset> _headerSlide, _statsSlide, _buttonSlide, _cardSlide, _levelCardSlide;

  @override
  void initState() {
    super.initState();
    if (_currentUser != null) {
      _userNameFuture = _getUserName(_currentUser.uid);
    }
    _setupAnimations();
    _entryAnimationController.forward();
  }

  void _setupAnimations() {
    _entryAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _pulseAnimationController =
    AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _searchAnimationController =
    AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();

    _headerFade = _createFadeAnimation(begin: 0.0, end: 0.6);
    _headerSlide = _createSlideAnimation(begin: 0.0, end: 0.6);
    _statsFade = _createFadeAnimation(begin: 0.2, end: 0.8);
    _statsSlide = _createSlideAnimation(begin: 0.2, end: 0.8);
    _buttonFade = _createFadeAnimation(begin: 0.4, end: 1.0);
    _buttonSlide = _createSlideAnimation(begin: 0.4, end: 1.0, yOffset: 0.5);
    _cardFade = _createFadeAnimation(begin: 0.6, end: 1.0);
    _cardSlide = _createSlideAnimation(begin: 0.6, end: 1.0);
    _levelCardFade = _createFadeAnimation(begin: 0.7, end: 1.0);
    _levelCardSlide = _createSlideAnimation(begin: 0.7, end: 1.0, yOffset: 0.6);
  }

  Animation<double> _createFadeAnimation({required double begin, required double end}) =>
      Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
          parent: _entryAnimationController,
          curve: Interval(begin, end, curve: Curves.easeOut)));

  Animation<Offset> _createSlideAnimation({required double begin, required double end, double yOffset = 0.2}) =>
      Tween<Offset>(begin: Offset(0, yOffset), end: Offset.zero).animate(
          CurvedAnimation(
              parent: _entryAnimationController,
              curve: Interval(begin, end, curve: Curves.easeOutCubic)));

  Future<String?> _getUserName(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
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
    super.dispose();
  }

  Future<void> _findPracticePartner() async {
    if (_currentUser == null) return;
    setState(() => _isSearching = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final myId = _currentUser!.uid;
    final waitingPoolRef = FirebaseFirestore.instance.collection('waiting_pool');
    try {
      await waitingPoolRef.doc(myId).delete();
      final query = waitingPoolRef.where('userId', isNotEqualTo: myId).orderBy('waitingSince');
      final potentialMatches = await query.get();
      if (potentialMatches.docs.isNotEmpty) {
        final otherUserDoc = potentialMatches.docs.first;
        final otherUserId = otherUserDoc.id;
        final chatRoomId = await FirebaseFirestore.instance.runTransaction((transaction) async {
          final otherUserSnapshot = await transaction.get(otherUserDoc.reference);
          if (otherUserSnapshot.exists) {
            final newChatRoomRef = FirebaseFirestore.instance.collection('chats').doc();
            transaction.set(newChatRoomRef, {'users': [myId, otherUserId], 'createdAt': FieldValue.serverTimestamp(), 'status': 'active', '${myId}_lastActive': FieldValue.serverTimestamp(), '${otherUserId}_lastActive': FieldValue.serverTimestamp()});
            transaction.update(otherUserDoc.reference, {'matchedChatRoomId': newChatRoomRef.id});
            return newChatRoomRef.id;
          }
          return null;
        });
        if (chatRoomId != null) {
          _navigateToChat(chatRoomId);
        } else {
          scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Partner başkasıyla eşleşti, yeniden aranıyor...'), duration: Duration(seconds: 2)));
          _findPracticePartner();
        }
      } else {
        await waitingPoolRef.doc(myId).set({'userId': myId, 'waitingSince': FieldValue.serverTimestamp()});
        _listenForMatch();
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('Arama sırasında bir hata oluştu: ${e.toString()}'), backgroundColor: Colors.red));
        await _cancelSearch();
      }
    }
  }

  void _listenForMatch() {
    if (_currentUser == null) return;
    _matchListener?.cancel();
    _matchListener = FirebaseFirestore.instance.collection('waiting_pool').doc(_currentUser!.uid).snapshots().listen((snapshot) async {
      if (!mounted) return;
      if (snapshot.exists && snapshot.data()!.containsKey('matchedChatRoomId')) {
        final chatRoomId = snapshot.data()!['matchedChatRoomId'] as String;
        await snapshot.reference.delete();
        _navigateToChat(chatRoomId);
      }
    });
  }

  Future<void> _cancelSearch() async {
    _matchListener?.cancel();
    if (_currentUser != null) {
      FirebaseFirestore.instance.collection('waiting_pool').doc(_currentUser!.uid).delete().catchError((_) {});
    }
    if (mounted) setState(() => _isSearching = false);
  }

  void _navigateToChat(String chatRoomId) {
    if (!mounted) return;
    _matchListener?.cancel();
    setState(() => _isSearching = false);
    Navigator.pushReplacement(context, PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ChatScreen(chatRoomId: chatRoomId),
        transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        automaticallyImplyLeading: !_isSearching,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _isSearching ? 0 : 1,
            child: const Text('LinguaChat', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24))),
        actions: [
          AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _isSearching ? 0 : 1,
              child: IconButton(
                  icon: const Icon(Icons.logout, color: Colors.black54),
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    await _cancelSearch();
                    await _authService.signOut();
                    navigator.pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
                  }))
        ],
      ),
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                FadeTransition(
                    opacity: _headerFade,
                    child: SlideTransition(
                        position: _headerSlide,
                        child: HomeHeader(userNameFuture: _userNameFuture ?? Future.value('Gezgin'), currentUser: _currentUser))),
                const SizedBox(height: 32),
                FadeTransition(
                    opacity: _statsFade,
                    child: SlideTransition(position: _statsSlide, child: const StatsRow())),
                const SizedBox(height: 32),
                Center(child: _buildFindPartnerButton()),
                const SizedBox(height: 32),
                FadeTransition(
                    opacity: _cardFade,
                    child: SlideTransition(position: _cardSlide, child: const ChallengeCard())),
                const SizedBox(height: 20),
                FadeTransition(
                    opacity: _levelCardFade,
                    child: SlideTransition(position: _levelCardSlide, child: const LevelAssessmentCard())),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFindPartnerButton() {
    return FadeTransition(
      opacity: _buttonFade,
      child: SlideTransition(
        position: _buttonSlide,
        child: GestureDetector(
          onTap: _findPracticePartner,
          child: Hero(
            tag: 'find-partner-hero',
            child: AnimatedBuilder(
              animation: _pulseAnimationController,
              builder: (context, child) {
                final scale = 1.0 - (_pulseAnimationController.value * 0.05);
                return Transform.scale(scale: scale, child: child);
              },
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [Colors.teal, Colors.cyan], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    boxShadow: [BoxShadow(color: Colors.teal.withAlpha(102), blurRadius: 30, spreadRadius: 5, offset: const Offset(0, 15))]),
                child: const Material(
                  color: Colors.transparent,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.language_sharp, color: Colors.white, size: 90),
                      SizedBox(height: 10),
                      Text('Partner Bul', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}