import 'dart:async';
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

  AnimationController? _pulseAnimationController;
  Animation<double>? _scaleAnimation;
  AnimationController? _searchAnimationController;

  @override
  void initState() {
    super.initState();
    if (_currentUser != null) {
      _userNameFuture = _getUserName(_currentUser!.uid);
    }

    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseAnimationController!,
        curve: Curves.easeInOut,
      ),
    );

    _searchAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  Future<String?> _getUserName(String uid) async {
    try {
      final doc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return doc.data()?['displayName'] as String?;
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _matchListener?.cancel();
    _pulseAnimationController?.dispose();
    _searchAnimationController?.dispose();
    super.dispose();
  }

  Future<void> _findPracticePartner() async {
    if (_currentUser == null) return;
    setState(() {
      _isSearching = true;
    });

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final String myId = _currentUser!.uid;
    final waitingPoolRef =
    FirebaseFirestore.instance.collection('waiting_pool');

    try {
      await waitingPoolRef.doc(myId).delete();
    } catch (e) {
      // Sorun değil, doküman zaten olmayabilir.
    }

    try {
      final query = waitingPoolRef
          .where('userId', isNotEqualTo: myId)
          .orderBy('waitingSince');

      final potentialMatches = await query.get();

      if (potentialMatches.docs.isNotEmpty) {
        final otherUserDoc = potentialMatches.docs.first;
        final otherUserId = otherUserDoc.id;

        final String? chatRoomId =
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
              '${otherUserId}_lastActive': FieldValue.serverTimestamp(),
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
      await _cancelSearch();
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
      MaterialPageRoute(
          builder: (context) => ChatScreen(chatRoomId: chatRoomId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('LinguaChat',
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 24)),
        actions: [
          IconButton(
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
          )
        ],
      ),
      body: _isSearching ? _buildSearchingBody() : _buildHomeBody(),
    );
  }

  Widget _buildHomeBody() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            FutureBuilder<String?>(
              future: _userNameFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                final userName = snapshot.data ?? 'Gezgin';
                return Column(
                  children: [
                    Text(
                      'Tekrar Hoş Geldin,',
                      style: TextStyle(
                          fontSize: 26,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w300),
                    ),
                    Text(
                      userName,
                      style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                  ],
                );
              },
            ),
            ScaleTransition(
              scale: _scaleAnimation!,
              child: _buildFindPartnerButton(),
            ),
            _buildMotivationCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildFindPartnerButton() {
    return GestureDetector(
      onTap: _findPracticePartner,
      child: Container(
        width: 240,
        height: 240,
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
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_alt, color: Colors.white, size: 70),
            SizedBox(height: 10),
            Text(
              'Partner Bul',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMotivationCard() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const GoalsScreen()),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.flag_circle, color: Colors.amber, size: 40),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Bugünkü Hedefin",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    "15 dakika pratik yapmak!",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16)
          ],
        ),
      ),
    );
  }

  Widget _buildSearchingBody() {
    const tips = [
      "Yeni bir kelime öğrendiğinde, onu 3 farklı cümlede kullanmaya çalış.",
      "Hata yapmaktan korkma! Hatalar öğrenme sürecinin bir parçasıdır.",
      "Kendine küçük ve ulaşılabilir hedefler koy.",
    ];
    final randomTip = (List.of(tips)..shuffle()).first;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.teal.withAlpha(13),
                  ),
                ),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.teal.withAlpha(26),
                  ),
                ),
                RotationTransition(
                  turns: _searchAnimationController!,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        center: Alignment.center,
                        colors: [Colors.transparent, Colors.teal],
                        stops: [0.7, 1.0],
                      ),
                    ),
                  ),
                ),
                const Icon(Icons.person_search_rounded,
                    color: Colors.teal, size: 60),
              ],
            ),
            const SizedBox(height: 40),
            const Text('Partner Aranıyor...',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'İpucu: $randomTip',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ),
            const SizedBox(height: 50),
            TextButton.icon(
              style: TextButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
              onPressed: _cancelSearch,
              icon: const Icon(Icons.cancel),
              label:
              const Text('Aramayı İptal Et', style: TextStyle(fontSize: 16)),
            )
          ],
        ),
      ),
    );
  }
}