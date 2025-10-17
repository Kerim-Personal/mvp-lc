// lib/services/revenuecat_service.dart
// RevenueCat abonelik entegrasyonu ve Firestore senkronizasyonu

import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier, kIsWeb, debugPrint, kReleaseMode;
import 'package:flutter/services.dart' show PlatformException;
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatService with ChangeNotifier {
  RevenueCatService._();
  static final RevenueCatService instance = RevenueCatService._();

  final _auth = FirebaseAuth.instance;

  Offerings? _offerings;
  CustomerInfo? _customerInfo;

  bool _initialized = false;

  Offerings? get offerings => _offerings;
  CustomerInfo? get customerInfo => _customerInfo;
  bool get isSupportedPlatform => !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);
  bool get initialized => _initialized;

  // Aktif herhangi bir entitlement varsa premium kabul ederiz
  bool get isPremiumActive => _customerInfo?.entitlements.active.isNotEmpty == true;

  Future<void> init() async {
    if (_initialized) return;
    if (!isSupportedPlatform) {
      debugPrint('RevenueCat: Web veya desteklenmeyen platform, init atlandı');
      _initialized = true;
      return;
    }

    try {
      // Anahtarları dart-define üzerinden almayı deneyin
      const androidKey = String.fromEnvironment('RC_ANDROID_API_KEY', defaultValue: '');
      const iosKey = String.fromEnvironment('RC_IOS_API_KEY', defaultValue: '');

      final publicSdkKey = Platform.isAndroid
          ? (androidKey.isNotEmpty ? androidKey : 'goog_daVXmcqDsGismJmYxOQIowInbbZ')
          : (iosKey.isNotEmpty ? iosKey : 'REPLACE_WITH_RC_IOS_PUBLIC_SDK_KEY');

      await Purchases.setLogLevel(kReleaseMode ? LogLevel.warn : LogLevel.debug);

      final configuration = PurchasesConfiguration(publicSdkKey)
      // observerMode kaldırıldı / desteklenmiyor
        ..appUserID = null;

      await Purchases.configure(configuration);

      // Akışı dinle ve Firestore ile senkronize et
      Purchases.addCustomerInfoUpdateListener((info) {
        _customerInfo = info;
        _syncEntitlementsToFirestore();
        notifyListeners();
      });

      // İlk değerleri çek
      _customerInfo = await Purchases.getCustomerInfo();
      _offerings = await Purchases.getOfferings();
      _initialized = true;
    } catch (e) {
      debugPrint('RevenueCat init error: $e');
    }
  }

  Future<void> refreshOfferings() async {
    if (!_initialized) return;
    try {
      _offerings = await Purchases.getOfferings();
      notifyListeners();
    } catch (e) {
      debugPrint('RevenueCat offerings error: $e');
    }
  }

  Future<void> onLogin(String uid) async {
    if (!_initialized) return;
    try {
      final result = await Purchases.logIn(uid);
      _customerInfo = result.customerInfo;
      await _syncEntitlementsToFirestore();
      notifyListeners();
    } catch (e) {
      debugPrint('RevenueCat logIn error: $e');
    }
  }

  Future<void> onLogout() async {
    if (!_initialized) return;
    try {
      await Purchases.logOut();
      _customerInfo = await Purchases.getCustomerInfo();
      await _syncEntitlementsToFirestore();
      notifyListeners();
    } catch (e) {
      debugPrint('RevenueCat logOut error: $e');
    }
  }

  // Satın alma yardımcıları
  Future<PurchaseOutcome> purchaseMonthly() async {
    if (!initialized) {
      await init();
    }
    if (_offerings == null) {
      await refreshOfferings();
    }
    // Android'de kimlikler productId:basePlanId olabilir
    final androidFullId = 'premium_monthly:monthly-normal';
    final pkg = _findPackageByFullOrProductId(androidFullId, 'premium_monthly')
        ?? _findPackageByType(PackageType.monthly)
        ?? _findPackageByIdentifier('monthly');
    if (pkg == null) {
      return PurchaseOutcome(success: false, message: 'Monthly package not found in offerings');
    }
    return _purchasePackage(pkg);
  }

  Future<PurchaseOutcome> purchaseAnnual() async {
    if (!initialized) {
      await init();
    }
    if (_offerings == null) {
      await refreshOfferings();
    }
    final androidFullId = 'premium_yearly:yearly-normal';
    final pkg = _findPackageByFullOrProductId(androidFullId, 'premium_yearly')
        ?? _findPackageByType(PackageType.annual)
        ?? _findPackageByIdentifier('yearly')
        ?? _findPackageByIdentifier('annual');
    if (pkg == null) {
      return PurchaseOutcome(success: false, message: 'Annual package not found in offerings');
    }
    return _purchasePackage(pkg);
  }

  Future<PurchaseOutcome> _purchasePackage(Package pkg) async {
    if (_auth.currentUser == null) {
      // Güvenlik: anonim satın almayı engelliyoruz, kimlik birleşimi sorun çıkarabilir
      return PurchaseOutcome(success: false, message: 'Lütfen önce giriş yapın.');
    }
    try {
      final result = await Purchases.purchasePackage(pkg);
      _customerInfo = result.customerInfo;
      await _syncEntitlementsToFirestore();
      notifyListeners();
      return PurchaseOutcome(success: true);
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      final cancelled = code == PurchasesErrorCode.purchaseCancelledError;
      return PurchaseOutcome(success: false, userCancelled: cancelled, message: code.name);
    } catch (e) {
      debugPrint('Purchase error: $e');
      return PurchaseOutcome(success: false, message: e.toString());
    }
  }

  Future<bool> restorePurchases() async {
    try {
      final info = await Purchases.restorePurchases();
      _customerInfo = info;
      await _syncEntitlementsToFirestore();
      notifyListeners();
      return isPremiumActive;
    } catch (e) {
      debugPrint('Restore error: $e');
      return false;
    }
  }

  Package? _findPackageByType(PackageType type) {
    final current = _offerings?.current;
    if (current != null) {
      try {
        return current.availablePackages.firstWhere((p) => p.packageType == type);
      } catch (_) {/* fallthrough */}
    }
    // Fallback: tüm offeringler içinde ara
    final all = _offerings?.all.values;
    if (all != null) {
      for (final off in all) {
        try {
          final found = off.availablePackages.firstWhere((p) => p.packageType == type);
          return found;
        } catch (_) {/* continue */}
      }
    }
    return null;
  }

  Package? _findPackageByIdentifier(String identifier) {
    final id = identifier.toLowerCase();
    final current = _offerings?.current;
    if (current != null) {
      try {
        return current.availablePackages.firstWhere((p) => p.identifier.toLowerCase() == id);
      } catch (_) {/* fallthrough */}
    }
    // Fallback: tüm offeringler içinde ara
    final all = _offerings?.all.values;
    if (all != null) {
      for (final off in all) {
        try {
          final found = off.availablePackages.firstWhere((p) => p.identifier.toLowerCase() == id);
          return found;
        } catch (_) {/* continue */}
      }
    }
    return null;
  }

  // Android productId:basePlanId ya da sade productId için arama
  Package? _findPackageByFullOrProductId(String fullId, String productId) {
    final full = fullId.toLowerCase();
    final pid = productId.toLowerCase();

    Package? searchInOffering(Offering off) {
      // Tam eşleşme
      try {
        return off.availablePackages.firstWhere((p) => p.storeProduct.identifier.toLowerCase() == full);
      } catch (_) {/* fallthrough */}
      // Sade productId eşleşmesi
      try {
        return off.availablePackages.firstWhere((p) => p.storeProduct.identifier.toLowerCase() == pid);
      } catch (_) {/* fallthrough */}
      // productId ile başlayan (productId:basePlanId) eşleşmesi
      try {
        return off.availablePackages.firstWhere((p) => p.storeProduct.identifier.toLowerCase().startsWith('$pid:'));
      } catch (_) {/* fallthrough */}
      return null;
    }

    final current = _offerings?.current;
    if (current != null) {
      final found = searchInOffering(current);
      if (found != null) return found;
    }

    final all = _offerings?.all.values;
    if (all != null) {
      for (final off in all) {
        final found = searchInOffering(off);
        if (found != null) return found;
      }
    }
    return null;
  }

  String? get monthlyPriceString {
    final androidFullId = 'premium_monthly:monthly-normal';
    final pkg = _findPackageByFullOrProductId(androidFullId, 'premium_monthly')
        ?? _findPackageByType(PackageType.monthly)
        ?? _findPackageByIdentifier('monthly');
    return pkg?.storeProduct.priceString;
  }

  String? get annualPriceString {
    final androidFullId = 'premium_yearly:yearly-normal';
    final pkg = _findPackageByFullOrProductId(androidFullId, 'premium_yearly')
        ?? _findPackageByType(PackageType.annual)
        ?? _findPackageByIdentifier('yearly')
        ?? _findPackageByIdentifier('annual');
    return pkg?.storeProduct.priceString;
  }

  Future<void> _syncEntitlementsToFirestore() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return; // yalnızca oturum açıkken senkronize

    // Her zaman en güncel müşteri bilgisini al (özellikle satın alma hemen ardından gecikmeler için)
    try {
      _customerInfo = await Purchases.getCustomerInfo();
    } catch (_) {
      // sessizce devam
    }

    // Not: Premium durumu artık yalnızca sunucu tarafındaki RevenueCat webhook’u ile Firestore’a işlenir.
    // İstemci tarafından herhangi bir yazım yapılmaz.
  }

  Future<void> disposeService() async {
    // Dinleyici kaldırma gerekmiyor; plugin global dinleyiciyi yönetiyor.
  }
}

class PurchaseOutcome {
  final bool success;
  final bool userCancelled;
  final String? message;
  PurchaseOutcome({required this.success, this.userCancelled = false, this.message});
}
