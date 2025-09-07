// Yeniden tasarlanan elmas servisi.
// Hedefler:
// 1. Optimistik artış (UI anında güncellenir)
// 2. Firestore'a atomik flush (transaction)
// 3. Offline durumda local pending kuyruk; tekrar bağlanınca flush
// 4. Stream tek doğruluk kaynağı: serverDiamonds + pending
// 5. Kalıcılık: pending miktar SharedPreferences ile saklanır

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DiamondService {
  static final DiamondService _instance = DiamondService._internal();
  factory DiamondService() => _instance;
  DiamondService._internal();

  final _controller = StreamController<int>.broadcast();
  Stream<int> get stream => _controller.stream;

  StreamSubscription<DocumentSnapshot<Map<String,dynamic>>>? _firestoreSub;
  StreamSubscription<User?>? _authSub;

  int _serverDiamonds = 0;     // Firestore'dan gelen son değer
  int _pendingDiamonds = 0;    // Henüz Firestore'a yazılmamış toplam artış
  bool _inited = false;
  bool _flushing = false;
  Timer? _retryTimer;
  int _retryAttempt = 0;

  static const _prefsKey = 'pending_diamonds_v1';

  Future<void> _init() async {
    if (_inited) return;
    _inited = true;
    await _loadPending();
    _attachAuthListener();
    await _attachSnapshotListener();
    await refresh();
    _emit();
    // İlk flush denemesi (pending varsa)
    _scheduleFlush(immediate: true);
  }

  Future<void> _loadPending() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _pendingDiamonds = prefs.getInt(_prefsKey) ?? 0;
    } catch (_) {}
  }

  Future<void> _savePending() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefsKey, _pendingDiamonds);
    } catch (_) {}
  }

  void _attachAuthListener() {
    _authSub ??= FirebaseAuth.instance.authStateChanges().listen((u) async {
      if (u != null) {
        await _attachSnapshotListener();
        await refresh();
        _scheduleFlush(immediate: true);
      } else {
        _firestoreSub?.cancel();
        _firestoreSub = null;
        _serverDiamonds = 0;
        _emit();
      }
    });
  }

  Future<void> _attachSnapshotListener() async {
    if (_firestoreSub != null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _firestoreSub = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((snap) {
      final val = (snap.data()?['diamonds'] as int?) ?? 0;
      if (val != _serverDiamonds) {
        _serverDiamonds = val;
        _emit();
      }
    }, onError: (_) {
      // Snapshot hatasını yut - flush tekrar deneyecek
    });
  }

  /// Toplamı yayınla (server + pending)
  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(_serverDiamonds + _pendingDiamonds);
    }
  }

  /// Dışarıya açık akış
  Stream<int> diamondsStream() {
    _init();
    return stream;
  }

  /// Manuel yenileme (Firestore'dan direkt okuma)
  Future<int?> refresh() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    try {
      final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      _serverDiamonds = (snap.data()?['diamonds'] as int?) ?? 0;
      _emit();
      return _serverDiamonds + _pendingDiamonds;
    } catch (_) {
      return _serverDiamonds + _pendingDiamonds;
    }
  }

  /// Eski API uyumluluğu
  Future<int?> currentDiamonds({bool refresh = false}) async {
    _init();
    if (refresh) return await this.refresh();
    return _serverDiamonds + _pendingDiamonds;
  }

  /// Eski API uyumluluğu (artık sadece refresh çağırır)
  void notifyRefresh() {
    refresh();
  }

  /// Optimistik artış ekleme (satın alma sonrası)
  Future<void> addOptimisticDiamonds(int amount) async {
    if (amount <= 0) return;
    _init();
    _pendingDiamonds += amount;
    await _savePending();
    _emit();
    _scheduleFlush(immediate: true);
  }

  void _scheduleFlush({bool immediate = false}) {
    if (immediate) {
      _flush();
      return;
    }
    _retryTimer?.cancel();
    // exponential backoff (max 30 sn)
    final delayMs = (500 * (1 << _retryAttempt)).clamp(500, 30000);
    _retryTimer = Timer(Duration(milliseconds: delayMs), _flush);
  }

  Future<void> _flush() async {
    if (_flushing) return;
    if (_pendingDiamonds <= 0) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _flushing = true;
    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
        final snap = await tx.get(ref);
        final data = snap.data() ?? {};
        final current = (data['diamonds'] as int?) ?? 0;
        final next = current + _pendingDiamonds;
        tx.set(ref, {...data, 'diamonds': next}, SetOptions(merge: true));
        // Transaction içinde success varsayıyoruz
      });
      _serverDiamonds += _pendingDiamonds;
      _pendingDiamonds = 0;
      _retryAttempt = 0;
      await _savePending();
      _emit();
    } catch (_) {
      // Flush başarısız -> backoff ile tekrar dene
      _retryAttempt++;
      _scheduleFlush();
    } finally {
      _flushing = false;
    }
  }

  void dispose() {
    _firestoreSub?.cancel();
    _authSub?.cancel();
    _retryTimer?.cancel();
    _controller.close();
  }
}
