// lib/services/notification_service.dart
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Match Found Event Stream
// A simple stream to broadcast match events from FCM handlers to the UI.
final _matchFoundController = StreamController<String>.broadcast();
Stream<String> get onMatchFound => _matchFoundController.stream;


/// Uygulama genel push bildirimi yönetimi.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  StreamSubscription<String>? _tokenSub;
  StreamSubscription<User?>? _authSub; // yeni: auth değişimini dinle
  bool _initialized = false;
  final Set<String> _allowedRoutes = {'/help','/support','/store','/profile','/practice-listening','/practice-reading','/practice-speaking','/practice-writing'};

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      // iOS foreground görünürlüğü (Android etkilenmez)
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      final settings = await _fcm.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        if (kDebugMode) debugPrint('FCM izin verilmedi');
      }

      // Uygulama açılışında mevcut kullanıcı varsa token kaydet
      _fcm.getToken().then(_storeToken);
      _tokenSub = _fcm.onTokenRefresh.listen(_storeToken);

      // Kullanıcı sonradan login olursa token yeniden kaydet (önceden kaçmış olabilir)
      _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
        if (user != null) {
          _fcm.getToken().then(_storeToken);
        }
      });

      // App foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage msg) {
        debugPrint('FCM onMessage: ${msg.data}');
        if (_handleMatchFound(msg)) return; // eşleşme ise snackbar gösterme

        final ctx = notificationNavigatorKey.currentContext;
        if (ctx != null && msg.notification != null) {
          final route = (msg.data['targetRoute'] ?? '').toString();
          if (!ctx.mounted) return; // güvenlik
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

      // Background -> kullanıcı tıklayınca
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

      // Terminated state
      _fcm.getInitialMessage().then((msg) {
        if (msg != null) _handleMessage(msg);
      });
    } catch (e) {
      if (kDebugMode) debugPrint('NotificationService init error: $e');
    }
  }

  // Returns true if the message was a match notification
  bool _handleMatchFound(RemoteMessage msg) {
    if (msg.data['type'] == 'MATCH_FOUND' && msg.data['chatId'] is String) {
      _matchFoundController.add(msg.data['chatId']);
      return true;
    }
    return false;
  }

  void _handleMessage(RemoteMessage msg) {
    if (_handleMatchFound(msg)) return;

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
    final nav = notificationNavigatorKey.currentState;
    if (nav == null) return;
    try {
      nav.pushNamed(route);
    } catch (e) {
      if (kDebugMode) debugPrint('Navigation error: $e');
    }
  }

  Future<void> _storeToken(String? token) async {
    if (token == null) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final ref = FirebaseFirestore.instance.collection('users').doc(uid);

    // Doküman yokken create denemesi yapmayın; sadece update deneyin.
    // Update doküman yoksa client tarafında not-found ile düşer ve kuralları ihlal etmez.
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        await ref.update({
          'fcmTokens': [token], // tek tokenı sakla
        });
        return; // başarı
      } catch (e) {
        // Doküman henüz oluşmadıysa kısa bir gecikmeden sonra tekrar dene
        await Future.delayed(Duration(milliseconds: 200 * (attempt + 1)));
      }
    }
    // Son denemede de başarısızsa sessizce bırak (doküman daha sonra oluştuğunda auth değişiminde tekrar denenecek)
  }

  Future<void> dispose() async {
    await _tokenSub?.cancel();
    await _authSub?.cancel();
    // Broadcast controller kapatılmıyor (uygulama yaşam döngüsü boyunca kullanılacak)
  }
}

final GlobalKey<NavigatorState> notificationNavigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
  // For this app, background messages are handled when the user opens the app.
  // The Firestore listener is the source of truth for matches when the app was terminated.
  // The FCM is a "fast path" for foreground/background states.
}
