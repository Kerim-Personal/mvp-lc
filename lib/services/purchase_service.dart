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

  // Elmas paketleri devre dışı: boş liste
  static const List<String> diamondProductIds = [];

  static int? diamondAmountFor(String id) {
    // Diamonds satışları kapalı, miktar dönmüyoruz
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
    // Diamonds ürünleri eklenmiyor.
    _products[monthlyProductId] = const StoreProduct(monthlyProductId, '₺59,90');
    _products[yearlyProductId] = const StoreProduct(yearlyProductId, '₺399,90');
  }

  StoreProduct? product(String id) => _products[id];

  Future<bool> buy(String productId) async {
    if (!isAvailable) return false;
    try {
      await Future.delayed(const Duration(milliseconds: 350));
      // Diamonds satın alımı devre dışı
      if (diamondProductIds.contains(productId)) {
        return false;
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
    if (amount <= 0) return false;
    try {
      // Yeni merkezi sistem: sadece optimistik ekle, flush'ı DiamondService yönetecek
      await DiamondService().addOptimisticDiamonds(amount);
      return true;
    } catch (_) {
      return false;
    }
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
