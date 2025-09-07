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
    'diamonds_mega', // 3000 (yeni)
  ];

  static int? diamondAmountFor(String id) {
    switch (id) {
      case 'diamonds_small':
        return 100;
      case 'diamonds_medium':
        return 550;
      case 'diamonds_large':
        return 1200;
      case 'diamonds_mega':
        return 3000;
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
      // Basit fiyatlama: amount / 20, mega için küçük indirim uygula
      double base = amount / 20;
      if (id == 'diamonds_mega') base *= 0.92; // indirim
      _products[id] = StoreProduct(id, '₺${base.toStringAsFixed(2)}');
    }
    _products[monthlyProductId] = const StoreProduct(monthlyProductId, '₺59,90');
    _products[yearlyProductId] = const StoreProduct(yearlyProductId, '₺399,90');
  }

  StoreProduct? product(String id) => _products[id];

  Future<bool> buy(String productId) async {
    if (!isAvailable) return false;
    try {
      await Future.delayed(const Duration(milliseconds: 350));
      if (diamondProductIds.contains(productId)) {
        final add = diamondAmountFor(productId) ?? 0;
        final added = await _addDiamonds(add);
        return added; // Firestore yazımı başarısız ise false döner
      }
      if (productId == monthlyProductId || productId == yearlyProductId) {
        await _activateSubscription(productId);
        return true;
      }
      return false; // tanınmayan ürün
    } catch (e) {
      // Genel hata
      return false;
    }
  }

  Future<void> restorePurchases() async {
    // Dummy: Gerçek uygulamada mağaza API ile restore çağrısı yapılır.
    await Future.delayed(const Duration(milliseconds: 400));
  }

  Future<bool> _addDiamonds(int amount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);

    const int maxRetries = 3;
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        await FirebaseFirestore.instance.runTransaction((tx) async {
          final snap = await tx.get(ref);
          final data = snap.data() ?? {};
          final current = (data['diamonds'] as int?) ?? 0;
          final next = current + amount;
          tx.set(ref, {...data, 'diamonds': next}, SetOptions(merge: true));
        });
        DiamondService().notifyRefresh();
        return true;
      } catch (e) {
        if (attempt == maxRetries - 1) {
          return false;
        }
        await Future.delayed(const Duration(milliseconds: 120));
      }
    }
    return false;
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
