// Minimal (geçici) PurchaseService stub'u.
// Gerçek uygulamada in_app_purchase entegrasyonu ile değiştirilmelidir.
// Bu sınıf sadece StoreScreen'deki derleme hatalarını gidermek ve temel akışı simüle etmek için yazıldı.
// TODO: Gerçek ürün sorgulama, satın alma ve makbuz doğrulama ekle.

import 'dart:async';
import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'diamond_service.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

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
  final Map<String, ProductDetails> _productDetails = {};
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  // Hata geri bildirimi için yayıncı
  final StreamController<String> _errorController = StreamController<String>.broadcast();
  Stream<String> get errors => _errorController.stream;

  bool _inited = false;
  bool isAvailable = false; // Gerçek servis bağlanınca true yapılıyor.

  Future<void> init() async {
    if (_inited) return;
    _inited = true;

    // Mağaza kullanılabilir mi?
    try {
      isAvailable = await _iap.isAvailable();
    } catch (e) {
      isAvailable = false;
      try { _errorController.add('Billing check failed: $e'); } catch (_) {}
    }

    if (!isAvailable) {
      // Kullanıcı yine de ekranı görebilsin diye boş state ile devam.
      try {
        _errorController.add(
          'Google Play Billing kullanılamıyor. Uygulamayı Play Store iç test kanalından yüklediğinizden, doğru paket adını (com.codenzi.vocachat) kullandığınızdan ve test hesabınızın yetkili olduğundan emin olun.'
        );
      } catch (_) {}
      _listenPurchaseUpdates();
      return;
    }

    // Ürün ayrıntılarını sorgula
    await _queryProducts();

    // Satın alma güncellemelerini dinle
    _listenPurchaseUpdates();
  }

  Future<void> _queryProducts() async {
    final ids = {monthlyProductId, yearlyProductId};
    try {
      final resp = await _iap.queryProductDetails(ids);
      // Bulunamayan ürün kimlikleri için uyarı ver
      if (resp.notFoundIDs.isNotEmpty) {
        try {
          _errorController.add(
            'Play Console’da bulunamayan ürün kimlikleri: ${resp.notFoundIDs.join(', ')}. Kodda tanımlı ID’lerle (premium_monthly, premium_yearly) birebir eşleştiğinden, ürünlerin Yayında olduğundan ve yayılımın tamamlandığından emin olun.'
          );
        } catch (_) {}
      }
      // Bulunanları kaydet.
      for (final d in resp.productDetails) {
        _productDetails[d.id] = d;
        _products[d.id] = StoreProduct(d.id, d.price);
      }
    } catch (e) {
      try { _errorController.add('Product query failed: $e'); } catch (_) {}
      // Sessizce başarısız ol ve UI'ye boş dön.
    }
  }

  void _listenPurchaseUpdates() {
    _purchaseSub ??= _iap.purchaseStream.listen(
      (purchases) async {
        for (final p in purchases) {
          await _handlePurchase(p);
        }
      },
      onError: (e) {
        // Hata bilgisini UI'ye ilet
        try { _errorController.add('Purchase stream error: $e'); } catch (_) {}
      },
      onDone: () {},
    );
  }

  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    try {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored: // iOS için restore akışı
          // Basit istemci tarafı onay: ürün ID premium ise premium aç.
          if (purchase.productID == monthlyProductId || purchase.productID == yearlyProductId) {
            await _activateSubscription(purchase.productID);
          }
          break;
        case PurchaseStatus.pending:
          // Beklemede: UI zaten "purchasing" set'i ile spinner gösteriyor.
          break;
        case PurchaseStatus.canceled:
          // Kullanıcı iptal etti.
          break;
        case PurchaseStatus.error:
          // Hata mesajını ilet
          final msg = () {
            try {
              final dynamic err = purchase.error;
              if (err != null) {
                final code = (err as dynamic).code?.toString();
                final message = (err as dynamic).message?.toString();
                return 'Purchase failed${code != null ? ' ($code)' : ''}${message != null ? ': $message' : ''}';
              }
            } catch (_) {}
            return 'Purchase failed.';
          }();
          try { _errorController.add(msg); } catch (_) {}
          break;
      }
    } finally {
      // Google Play'de tüm satın almaları işledikten sonra tamamlamak gerekir.
      if (purchase.pendingCompletePurchase) {
        try {
          await _iap.completePurchase(purchase);
        } catch (_) {}
      }
    }
  }

  void _registerDummyProducts() {
    // Diamonds ürünleri eklenmiyor.
    _products[monthlyProductId] = const StoreProduct(monthlyProductId, '₺59,90');
    _products[yearlyProductId] = const StoreProduct(yearlyProductId, '₺399,90');
  }

  StoreProduct? product(String id) => _products[id];

  Future<bool> buy(String productId) async {
    if (!isAvailable) {
      // Yine de kullanıcıya bir şeyler göstermek için init sonrası dummy kayıtlı olabilir
      // ama satın alma başlatmayız.
      return false;
    }
    try {
      final details = _productDetails[productId];
      if (details == null) return false;

      // Android: GooglePlayPurchaseParam ile ilerle (offer seçimi yoksa varsayılana düşer)
      if (Platform.isAndroid && details is GooglePlayProductDetails) {
        final param = GooglePlayPurchaseParam(
          productDetails: details,
        );
        final launched = await _iap.buyNonConsumable(purchaseParam: param);
        return launched;
      }

      // iOS veya diğer platformlar
      final param = PurchaseParam(productDetails: details);
      final launched = await _iap.buyNonConsumable(purchaseParam: param);
      return launched;
    } catch (e) {
      try { _errorController.add('Failed to start purchase: $e'); } catch (_) {}
      return false;
    }
  }

  Future<void> restorePurchases() async {
    try {
      // iOS ve Android için birleşik API; geçmiş satın alımlar purchaseStream ile gelir.
      await _iap.restorePurchases();
    } catch (e) {
      try { _errorController.add('Restore failed: $e'); } catch (_) {}
      // Sessiz geç.
    }
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
    _purchaseSub?.cancel();
    try { _errorController.close(); } catch (_) {}
  }
}
