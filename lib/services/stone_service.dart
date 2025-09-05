import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Taş bakiyesi ve harcama işlemleri
class StoneService {
  StoneService._internal();
  static final StoneService _instance = StoneService._internal();
  factory StoneService() => _instance;

  static const String _fieldName = 'stones';

  /// Anlık kullanıcı taş bakiyesi stream (int?)
  Stream<int?> stonesStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((snap) => (snap.data()?[_fieldName] as num?)?.toInt());
  }

  /// Firestore'dan mevcut bakiyeyi tek seferlik alır.
  Future<int> getCurrentStones() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;
    final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    return (snap.data()?[_fieldName] as num?)?.toInt() ?? 0;
  }

  /// Belirtilen miktarda taş harcar. Yeterli değilse false döner.
  Future<bool> spend(int amount) async {
    if (amount <= 0) return true; // 0 harcama her zaman başarılı
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);

    return FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final current = (snap.data()?[_fieldName] as num?)?.toInt() ?? 0;
      if (current < amount) return false;
      tx.update(ref, {
        _fieldName: current - amount,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    });
  }

  /// Manuel bakiye artırma (debug / promosyon için)
  Future<void> add(int amount) async {
    if (amount == 0) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
    await ref.set({
      _fieldName: FieldValue.increment(amount),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

