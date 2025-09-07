// Minimal (geçici) PurchaseService stub'u.
// Gerçek uygulamada in_app_purchase entegrasyonu ile değiştirilmelidir.
// Bu sınıf sadece StoreScreen'deki derleme hatalarını gidermek ve temel akışı simüle etmek için yazıldı.
// TODO: Gerçek ürün sorgulama, satın alma ve makbuz doğrulama ekle.

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'diamond_service.dart';

class StoreProduct {
  final String id;
  final String price; // Lokalize fiyat string'i (örnek / dummy)
  const StoreProduct(this.id, this.price);
}

class PurchaseService {
  // --- Statik ürün kimlikleri ---
  static const String monthlyProductId = 'premium_monthly';
  static const String yearlyProductId = 'premium_yearly';

  // Elmas paketleri (örnek kimlikler)
  static const List<String> diamondProductIds = [
    'diamonds_small', // 100
    'diamonds_medium', // 550
    'diamonds_large', // 1200
  ];

  static int? diamondAmountFor(String id) {
    switch (id) {
      case 'diamonds_small':
        return 100;
      case 'diamonds_medium':
        return 550;
      case 'diamonds_large':
        return 1200;
    }
    return null;
  }

  final Map<String, StoreProduct> _products = {};
  bool _inited = false;
  bool isAvailable = false; // Gerçek servis bağlanınca true yapılıyor.

  Future<void> init() async {
    if (_inited) return;
    _inited = true;
    // Normalde mağazadan (Play/App Store) ürün çekilir.
    // Burada dummy fiyatlar atıyoruz.
    _registerDummyProducts();
    isAvailable = true;
  }

  void _registerDummyProducts() {
    // Sahte / örnek fiyatlar. Gerçek uygulamada locale & currency gelir.
    for (final id in diamondProductIds) {
      final amount = diamondAmountFor(id) ?? 0;
      _products[id] = StoreProduct(id, '₺${(amount / 20).toStringAsFixed(2)}');
    }
    _products[monthlyProductId] = const StoreProduct(monthlyProductId, '₺59,90');
    _products[yearlyProductId] = const StoreProduct(yearlyProductId, '₺399,90');
  }

  StoreProduct? product(String id) => _products[id];

  Future<bool> buy(String productId) async {
    if (!isAvailable) return false;
    // Gerçek satın alma entegrasyonu yok; simülasyon.
    await Future.delayed(const Duration(milliseconds: 600));

    if (diamondProductIds.contains(productId)) {
      final add = diamondAmountFor(productId) ?? 0;
      await _addDiamonds(add);
      return true;
    }
    if (productId == monthlyProductId || productId == yearlyProductId) {
      await _activateSubscription(productId);
      return true;
    }
    return false;
  }

  Future<void> restorePurchases() async {
    // Dummy: Gerçek uygulamada mağaza API ile restore çağrısı yapılır.
    await Future.delayed(const Duration(milliseconds: 400));
  }

  Future<void> _addDiamonds(int amount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data() ?? {};
      final current = (data['diamonds'] as int?) ?? 0;
      tx.set(ref, {...data, 'diamonds': current + amount}, SetOptions(merge: true));
    });
    // Yayınla
    DiamondService().notifyRefresh();
  }

  Future<void> _activateSubscription(String productId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    // premiumUntil kullanılmıyor; Google yönetiyor varsayımıyla sadece isPremium=true.
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data() ?? {};
      tx.set(ref, {...data, 'isPremium': true}, SetOptions(merge: true));
    });
  }

  void dispose() {
    // Gerçek dinleyiciler vs varsa kapatılır; stub için yok.
  }
}
