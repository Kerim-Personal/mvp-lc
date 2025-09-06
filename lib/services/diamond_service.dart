// Minimal DiamondService stub'u
// Gerçek uygulamada backend / firestore dinlemeleri ile değiştirilmelidir.

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DiamondService {
  static final DiamondService _instance = DiamondService._internal();
  factory DiamondService() => _instance;
  DiamondService._internal();

  final _controller = StreamController<int?>.broadcast();
  StreamSubscription? _firestoreSub;

  Stream<int?> diamondsStream() {
    _ensureListener();
    return _controller.stream;
  }

  Future<int?> currentDiamonds({bool refresh = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final val = (snap.data()?['diamonds'] as int?) ?? 0;
    if (refresh) _controller.add(val);
    return val;
  }

  void notifyRefresh() async {
    final val = await currentDiamonds();
    _controller.add(val);
  }

  void _ensureListener() {
    if (_firestoreSub != null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _firestoreSub = FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots().listen((snap) {
      final val = (snap.data()?['diamonds'] as int?) ?? 0;
      _controller.add(val);
    });
  }

  void dispose() {
    _firestoreSub?.cancel();
    _controller.close();
  }
}
