import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Uygulama içi satın alma yönetimi
/// NOT: Gerçek yayında mutlaka sunucu tarafı makbuz doğrulaması ekleyin.
class PurchaseService {
  PurchaseService._internal();
  static final PurchaseService _instance = PurchaseService._internal();
  factory PurchaseService() => _instance;

  // Ürün kimlikleri (App Store / Play Console ile birebir aynı olmalı)
  static const String monthlyProductId = 'lingua_pro_monthly';
  static const String yearlyProductId = 'lingua_pro_yearly';
  static const String lifetimeProductId = 'lingua_pro_lifetime';
  static const String tokenPackSmallId = 'lingua_grammar_pack_small'; // mikro paket örneği

  // Yeni: Taş paket ürün kimlikleri
  static const String stonePackSmallId = 'lingua_stone_pack_small';
  static const String stonePackMediumId = 'lingua_stone_pack_medium';
  static const String stonePackLargeId = 'lingua_stone_pack_large';

  // Taş paket miktarları
  static const Map<String, int> _stonePackAmounts = {
    stonePackSmallId: 50,
    stonePackMediumId: 120,
    stonePackLargeId: 300,
  };

  static List<String> get stoneProductIds => _stonePackAmounts.keys.toList(growable: false);
  static int? stoneAmountFor(String productId) => _stonePackAmounts[productId];

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  bool _available = false;
  bool get isAvailable => _available;

  final Map<String, ProductDetails> _products = {};
  Map<String, ProductDetails> get products => _products;

  final StreamController<PurchaseStateUpdate> _stateController = StreamController.broadcast();
  Stream<PurchaseStateUpdate> get stateStream => _stateController.stream;

  Future<void> init() async {
    _available = await _iap.isAvailable();
    // Init sonrası erişilebilirlik bilgisini yayınla
    _stateController.add(PurchaseStateUpdate(isAvailable: _available));
    _purchaseSub ??= _iap.purchaseStream.listen(_onPurchaseUpdate, onError: (e, st) {
      _stateController.add(PurchaseStateUpdate(error: e.toString()));
    });
  }

  Future<void> dispose() async {
    await _purchaseSub?.cancel();
    await _stateController.close();
  }

  Future<void> loadProducts() async {
    if (!_available) {
      _stateController.add(PurchaseStateUpdate(error: 'Store kullanılamıyor', isAvailable: _available));
      return;
    }
    final ids = <String>{
      // Abonelik/lifetime (ileride tekrar kullanılabilir diye tutuluyor)
      monthlyProductId,
      yearlyProductId,
      lifetimeProductId,
      // Eski tokenPackSmallId yerine taş paketleri
      stonePackSmallId,
      stonePackMediumId,
      stonePackLargeId,
    };
    final response = await _iap.queryProductDetails(ids);
    if (response.error != null) {
      _stateController.add(PurchaseStateUpdate(error: response.error!.message));
    }
    _products.clear();
    for (final p in response.productDetails) {
      _products[p.id] = p;
    }
    _stateController.add(PurchaseStateUpdate(productsLoaded: true));
  }

  // Yardımcı: ID üzerinden doğru satın alma tipi
  Future<void> startPurchase(String productId) async {
    final product = _products[productId];
    if (product == null) {
      _stateController.add(PurchaseStateUpdate(error: 'Ürün bulunamadı: $productId'));
      return;
    }
    try {
      if (_stonePackAmounts.containsKey(productId) || productId == tokenPackSmallId) {
        // tokenPackSmallId geçiş sürecinde backward compatibility
        await buyConsumable(product);
      } else if (productId == lifetimeProductId) {
        await buyNonConsumableSafe(product);
      } else if (productId == monthlyProductId || productId == yearlyProductId) {
        // Abonelik (örn. Play Billing v6: in_app_purchase bunu unified olarak yönetiyor)
        await buyNonConsumableSafe(product);
      } else {
        await buyNonConsumableSafe(product);
      }
    } catch (e) {
      _stateController.add(PurchaseStateUpdate(error: 'Satın alma başlatılamadı: $e'));
    }
  }

  Future<void> buyNonConsumableSafe(ProductDetails product) async {
    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> buy(ProductDetails product) async {
    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> buyConsumable(ProductDetails product) async {
    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyConsumable(purchaseParam: purchaseParam, autoConsume: true);
  }

  Future<void> restore() async {
    await _iap.restorePurchases();
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _stateController.add(PurchaseStateUpdate(pending: true));
          break;
        case PurchaseStatus.error:
          _stateController.add(PurchaseStateUpdate(error: purchase.error?.message ?? 'Satın alma hatası'));
          break;
        case PurchaseStatus.canceled:
          _stateController.add(PurchaseStateUpdate(error: 'İptal edildi'));
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final verified = await _verifyPurchase(purchase);
            if (verified) {
              try {
                await _applyEntitlement(purchase.productID);
                _stateController.add(PurchaseStateUpdate(successProductId: purchase.productID, entitlementApplied: true));
              } catch (e) {
                _stateController.add(PurchaseStateUpdate(error: 'Entitlement uygulanamadı: $e'));
              }
            } else {
              _stateController.add(PurchaseStateUpdate(error: 'Doğrulama başarısız'));
            }
          break;
      }
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchase) async {
    // TODO: Sunucu tarafı makbuz doğrulaması ekleyin.
    return true; // Şimdilik optimistik
  }

  Future<void> _applyEntitlement(String productId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);

    // Taş paketleri
    if (_stonePackAmounts.containsKey(productId)) {
      final inc = _stonePackAmounts[productId] ?? 0;
      await ref.set({
        'stones': FieldValue.increment(inc),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return;
    }

    // Eski token pack (geçici)
    if (productId == tokenPackSmallId) {
      await ref.set({
        'stones': FieldValue.increment(50),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return;
    }

    // Abonelik / lifetime (opsiyonel - eğer pay-as-you-go modeline tamamen geçilecekse kaldırılabilir)
    final now = DateTime.now();
    DateTime? premiumUntil;
    DateTime base = now;
    try {
      final snap = await ref.get();
      if (snap.exists) {
        final data = snap.data();
        final dynamic raw = data?["premiumUntil"];
        DateTime? existing;
        if (raw is String) existing = DateTime.tryParse(raw);
        if (raw is Timestamp) existing = raw.toDate();
        if (existing != null && existing.isAfter(now)) base = existing;
      }
    } catch (_) {}

    if (productId == monthlyProductId) {
      premiumUntil = base.add(const Duration(days: 30));
    } else if (productId == yearlyProductId) {
      premiumUntil = base.add(const Duration(days: 365));
    } else if (productId == lifetimeProductId) {
      premiumUntil = DateTime(2099, 1, 1);
    }

    if (premiumUntil != null) {
      await ref.set({
        'isPremium': true,
        'premiumUntil': premiumUntil.toIso8601String(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }
}

class PurchaseStateUpdate {
  final bool pending;
  final bool productsLoaded;
  final String? error;
  final String? successProductId;
  final bool entitlementApplied;
  final bool? isAvailable;
  PurchaseStateUpdate({
    this.pending = false,
    this.productsLoaded = false,
    this.error,
    this.successProductId,
    this.entitlementApplied = false,
    this.isAvailable,
  });
}
