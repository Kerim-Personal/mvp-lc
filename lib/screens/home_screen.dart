// lib/screens/home_screen.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lingua_chat/screens/chat_screen.dart';
import 'package:lingua_chat/screens/goals_screen.dart';
import 'package:lingua_chat/screens/login_screen.dart';
import 'package:lingua_chat/services/auth_service.dart';

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

  late Animation<double> _headerFade, _statsFade, _buttonFade, _cardFade;
  late Animation<Offset> _headerSlide, _statsSlide, _buttonSlide, _cardSlide;

  @override
  void initState() {
    super.initState();
    if (_currentUser != null) {
      _userNameFuture = _getUserName(_currentUser!.uid);
    }
    _setupAnimations();
    _entryAnimationController.forward();
  }

  void _setupAnimations() {
    _entryAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _searchAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _headerFade = _createFadeAnimation(begin: 0.0, end: 0.6);
    _headerSlide = _createSlideAnimation(begin: 0.0, end: 0.6);

    _statsFade = _createFadeAnimation(begin: 0.2, end: 0.8);
    _statsSlide = _createSlideAnimation(begin: 0.2, end: 0.8);

    _buttonFade = _createFadeAnimation(begin: 0.4, end: 1.0);
    _buttonSlide = _createSlideAnimation(begin: 0.4, end: 1.0, yOffset: 0.5);

    _cardFade = _createFadeAnimation(begin: 0.6, end: 1.0);
    _cardSlide = _createSlideAnimation(begin: 0.6, end: 1.0);
  }

  Animation<double> _createFadeAnimation({required double begin, required double end}) {
    return Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _entryAnimationController,
      curve: Interval(begin, end, curve: Curves.easeOut),
    ));
  }

  Animation<Offset> _createSlideAnimation({required double begin, required double end, double yOffset = 0.2}) {
    return Tween<Offset>(begin: Offset(0, yOffset), end: Offset.zero).animate(CurvedAnimation(
      parent: _entryAnimationController,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    ));
  }

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
    setState(() {
      _isSearching = true;
    });

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final String myId = _currentUser!.uid;
    final waitingPoolRef = FirebaseFirestore.instance.collection('waiting_pool');

    try {
      await waitingPoolRef.doc(myId).delete();
    } catch (e) {
      // Sorun değil, devam et.
    }

    try {
      final query = waitingPoolRef.where('userId', isNotEqualTo: myId).orderBy('waitingSince');
      final potentialMatches = await query.get();

      if (potentialMatches.docs.isNotEmpty) {
        final otherUserDoc = potentialMatches.docs.first;
        final otherUserId = otherUserDoc.id;

        final String? chatRoomId = await FirebaseFirestore.instance.runTransaction((transaction) async {
          final otherUserSnapshot = await transaction.get(otherUserDoc.reference);
          if (otherUserSnapshot.exists) {
            final newChatRoomRef = FirebaseFirestore.instance.collection('chats').doc();
            transaction.set(newChatRoomRef, {
              'users': [myId, otherUserId],
              'createdAt': FieldValue.serverTimestamp(),
              'status': 'active',
              '${myId}_lastActive': FieldValue.serverTimestamp(),
              '${otherUserId}_lastActive': FieldValue.serverTimestamp(),
            });
            transaction.update(otherUserDoc.reference, {'matchedChatRoomId': newChatRoomRef.id});
            return newChatRoomRef.id;
          }
          return null;
        });

        if (chatRoomId != null) {
          _navigateToChat(chatRoomId);
        } else {
          scaffoldMessenger.showSnackBar(const SnackBar(
            content: Text('Partner başkasıyla eşleşti, yeniden aranıyor...'),
            duration: Duration(seconds: 2),
          ));
          _findPracticePartner();
        }
      } else {
        await waitingPoolRef.doc(myId).set({
          'userId': myId,
          'waitingSince': FieldValue.serverTimestamp(),
        });
        _listenForMatch();
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(SnackBar(
          content: Text('Arama sırasında bir hata oluştu: ${e.toString()}'),
          backgroundColor: Colors.red,
        ));
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
    if (mounted) {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _navigateToChat(String chatRoomId) {
    if (!mounted) return;
    _matchListener?.cancel();
    setState(() {
      _isSearching = false;
    });
    Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => ChatScreen(chatRoomId: chatRoomId),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        )
    );
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
          child: const Text('LinguaChat', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24)),
        ),
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
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                );
              },
            ),
          )
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          _buildHomeUI(),
          _buildSearchingUI(),
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
                _buildHeader(),
                const SizedBox(height: 32),
                _buildStatsRow(),
                const SizedBox(height: 32),
                Center(child: _buildFindPartnerButton()),
                const SizedBox(height: 32),
                _buildChallengeCard(),
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
                // Nefes alma efekti için ölçeği ayarlıyoruz.
                // Animasyon değeri 0.0 ile 1.0 arasında gidip geldikçe,
                // ölçek 1.0 ile 0.95 arasında değişecek.
                final scale = 1.0 - (_pulseAnimationController.value * 0.05);
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Colors.teal, Colors.cyan],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withAlpha(102),
                      blurRadius: 30,
                      spreadRadius: 5,
                      offset: const Offset(0, 15),
                    )
                  ],
                ),
                child: const Material(
                  color: Colors.transparent,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.language_sharp, color: Colors.white, size: 90),
                      SizedBox(height: 10),
                      Text(
                        'Partner Bul',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
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

  Widget _buildSearchingUI() {
    const tips = [
      "Yeni bir kelime öğrendiğinde, onu 3 farklı cümlede kullanmaya çalış.",
      "Hata yapmaktan korkma! Hatalar öğrenme sürecinin bir parçasıdır.",
      "Anlamadığın bir şey olduğunda tekrar sormaktan çekinme."
    ];
    final randomTip = (List.of(tips)..shuffle()).first;

    return IgnorePointer(
      ignoring: !_isSearching,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 500),
        opacity: _isSearching ? 1 : 0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Hero(
              tag: 'find-partner-hero',
              child: Stack(
                alignment: Alignment.center,
                children: [
                  RotationTransition(
                    turns: _searchAnimationController,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          center: Alignment.center,
                          colors: [Colors.transparent, Colors.cyan],
                          stops: [0.7, 1.0],
                        ),
                      ),
                    ),
                  ),
                  const Material(
                    color: Colors.transparent,
                    child: Icon(Icons.person_search_rounded, color: Colors.teal, size: 60),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const Text('Partner Aranıyor...', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.teal.withAlpha(26), borderRadius: BorderRadius.circular(12)),
              child: Text('İpucu: $randomTip', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.black54)),
            ),
            const SizedBox(height: 50),
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
              onPressed: _cancelSearch,
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Aramayı İptal Et', style: TextStyle(fontSize: 16)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _headerFade,
      child: SlideTransition(
        position: _headerSlide,
        child: FutureBuilder<String?>(
          future: _userNameFuture,
          builder: (context, snapshot) {
            final userName = snapshot.data ?? 'Gezgin';
            return Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.teal.withAlpha(26),
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : "G",
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Hoş Geldin,", style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w400)),
                    Text(userName, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black)),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return FadeTransition(
      opacity: _statsFade,
      child: SlideTransition(
        position: _statsSlide,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(Icons.local_fire_department_rounded, "3 Gün", "Seri", Colors.orange),
            _buildStatItem(Icons.timer_rounded, "45 dk", "Toplam Süre", Colors.teal),
            _buildStatItem(Icons.people_alt_rounded, "7", "Partner", Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        CircleAvatar(
            radius: 28,
            backgroundColor: color.withAlpha(38),
            child: Icon(icon, color: color, size: 28)
        ),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  Widget _buildChallengeCard() {
    const challenges = [
      "Bugün tanıştığın partnere en sevdiğin filmi anlat.",
      "Sohbetinde 5 yeni kelime kullanmayı dene.",
      "Partnerine 'Nasılsın?' demenin 3 farklı yolunu sor.",
      "Dün ne yaptığını 1 dakika boyunca anlatmaya çalış.",
      "Gelecek tatil planların hakkında konuş."
    ];
    final randomChallenge = (List.of(challenges)..shuffle()).first;

    return FadeTransition(
      opacity: _cardFade,
      child: SlideTransition(
        position: _cardSlide,
        child: InkWell(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const GoalsScreen()));
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 10, offset: const Offset(0, 5))]
            ),
            child: Row(
              children: [
                const Icon(Icons.flag_circle_outlined, color: Colors.amber, size: 40),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Günün Görevi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(randomChallenge, style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16)
              ],
            ),
          ),
        ),
      ),
    );
  }
}