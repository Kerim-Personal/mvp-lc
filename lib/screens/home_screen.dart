import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lingua_chat/screens/chat_screen.dart';
import 'package:lingua_chat/screens/login_screen.dart';
import 'package:lingua_chat/services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final _currentUser = FirebaseAuth.instance.currentUser;
  bool _isSearching = false;
  StreamSubscription? _matchListener;

  @override
  void dispose() {
    _matchListener?.cancel();
    super.dispose();
  }

  Future<void> _findPracticePartner() async {
    if (_currentUser == null) return;
    setState(() {
      _isSearching = true;
    });

    final String myId = _currentUser!.uid;
    final waitingPoolRef = FirebaseFirestore.instance.collection('waiting_pool');

    try {
      // Bu sorgu BİR INDEX gerektirir. Hata mesajındaki link ile oluşturulacak.
      final query = waitingPoolRef
          .where('userId', isNotEqualTo: myId)
          .orderBy('waitingSince');

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
            });
            transaction.update(otherUserDoc.reference, {'matchedChatRoomId': newChatRoomRef.id});
            return newChatRoomRef.id;
          }
          return null;
        });

        if (chatRoomId != null) {
          _navigateToChat(chatRoomId);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Partner başkasıyla eşleşti, yeniden aranıyor...'), duration: Duration(seconds: 2),));
            _findPracticePartner();
          }
        }
      } else {
        await waitingPoolRef.doc(myId).set({
          'userId': myId,
          'waitingSince': FieldValue.serverTimestamp(),
        });
        _listenForMatch();
      }
    } catch (e) {
      // HATA BURADA YAKALANIYOR! KONSOLU KONTROL ET!
      print("!!!!!!!!! ÖNEMLİ HATA !!!!!!!!!");
      print("Firestore Index'i oluşturmanız gerekiyor. Lütfen aşağıdaki hata mesajındaki linki kopyalayıp tarayıcıda açın.");
      print(e.toString());
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
      try {
        await FirebaseFirestore.instance.collection('waiting_pool').doc(_currentUser!.uid).delete();
      } catch (e) {}
    }
    if (mounted) {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _navigateToChat(String chatRoomId) {
    if (mounted) {
      _matchListener?.cancel();
      setState(() {
        _isSearching = false;
      });
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ChatScreen(chatRoomId: chatRoomId)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _cancelSearch();
              await _authService.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                );
              }
            },
          )
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: _isSearching
              ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              const Text('Partner Aranıyor...', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 40),
              TextButton(
                onPressed: _cancelSearch,
                child: const Text('Aramayı İptal Et', style: TextStyle(color: Colors.red)),
              )
            ],
          )
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Welcome!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text('Pratik yapmaya hazır mısın?', textAlign: TextAlign.center),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                onPressed: _findPracticePartner,
                child: const Text('Pratik Partneri Bul'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}