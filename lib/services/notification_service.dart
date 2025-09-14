// lib/services/notification_service.dart
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Uygulama genel push bildirimi yönetimi.
/// - İzin ister
/// - Token'i user doc'una ekler (fcmTokens array)
/// - Token yenilenince günceller
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  StreamSubscription<String>? _tokenSub;
  bool _initialized = false;
  final Set<String> _allowedRoutes = {'/help','/support','/store','/profile','/practice-listening','/practice-reading','/practice-speaking','/practice-writing'}; // extend as needed

  Future<void> init() async {
    if (_initialized) return; // idempotent
    _initialized = true;

    try {
      // iOS izin
      await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      // Web'de permission flow farklı olabilir.
      final token = await _fcm.getToken();
      if (token != null) {
        await _storeToken(token);
      }
      _tokenSub = _fcm.onTokenRefresh.listen((t) async {
        await _storeToken(t);
      });

      FirebaseMessaging.onMessage.listen((RemoteMessage msg) {
        if (kDebugMode) debugPrint('FCM onMessage: ${msg.notification?.title}');
        final ctx = _NotificationOverlay.navigatorKey.currentContext;
        if (ctx != null && msg.notification != null) {
          final route = (msg.data['targetRoute'] ?? '').toString();
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text('${msg.notification!.title ?? ''}\n${msg.notification!.body ?? ''}'.trim()),
              action: (route.isNotEmpty && _allowedRoutes.contains(route)) ? SnackBarAction(
                label: 'Open',
                onPressed: () => _navigateToRoute(route),
              ) : null,
            ),
          );
        }
      });

      // Bildirime tıklayarak açılan (background->foreground) durum
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage msg) {
        _handleRouteFromMessage(msg);
      });

      // Uygulama kapalıyken bildirime tıklayıp açma durumu
      _checkInitialMessage();
    } catch (e) {
      if (kDebugMode) debugPrint('NotificationService init error: $e');
    }
  }

  Future<void> _checkInitialMessage() async {
    try {
      final initial = await _fcm.getInitialMessage();
      if (initial != null) {
        _handleRouteFromMessage(initial);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('getInitialMessage error: $e');
    }
  }

  void _handleRouteFromMessage(RemoteMessage msg) {
    try {
      if (msg.data['kind'] == 'admin_broadcast') {
        final route = (msg.data['targetRoute'] ?? '').toString();
        if (route.isNotEmpty) {
          _navigateToRoute(route);
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('handleRouteFromMessage error: $e');
    }
  }

  void _navigateToRoute(String route) {
    if (!_allowedRoutes.contains(route)) {
      if (kDebugMode) debugPrint('Route not allowed: $route');
      return;
    }
    final nav = _NotificationOverlay.navigatorKey.currentState;
    if (nav == null) return;
    // Aynı route üstüne eklemeden push
    try {
      nav.pushNamed(route);
    } catch (e) {
      if (kDebugMode) debugPrint('Navigation error: $e');
    }
  }

  Future<void> _storeToken(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return; // giriş yok
    final ref = FirebaseFirestore.instance.collection('users').doc(uid);
    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final data = snap.data() ?? {};
        List list = (data['fcmTokens'] is List) ? (data['fcmTokens'] as List) : [];
        list = list.whereType<String>().toList();
        if (!list.contains(token)) {
          list.add(token);
          // Son 10 token ile sınırla
          if (list.length > 10) {
            list = list.sublist(list.length - 10);
          }
          tx.set(ref, {'fcmTokens': list}, SetOptions(merge: true));
        }
      });
    } catch (_) {
      // yut
    }
  }

  Future<void> dispose() async {
    await _tokenSub?.cancel();
  }
}

/// Aktif uygulamada foreground mesajlar için navigator context tutacak küçük navigator wrapper
class _NotificationOverlay {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}

GlobalKey<NavigatorState> get notificationNavigatorKey => _NotificationOverlay.navigatorKey;

/// Background mesaj handler (top-level zorunlu)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Burada heavy işlem yapmayın. Gerekirse isolate / local notification.
  debugPrint('Background FCM: ${message.messageId}');
}
