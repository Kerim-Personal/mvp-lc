import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioService {
  static final AudioService instance = AudioService._();

  final AudioPlayer _audioPlayer = AudioPlayer();
  // Kısa efekt sesleri için ayrı player (müzik ile çakışmasın)
  final AudioPlayer _sfxPlayer = AudioPlayer();
  static const _musicEnabledKey = 'music_enabled';
  static const _clickSoundEnabledKey = 'click_sound_enabled';
  static const _musicVolumeKey = 'music_volume';
  // Arka plan müziği için varsayılan düşük seviye (0.0 - 1.0)
  static const double _defaultMusicVolume = 0.18;
  double _musicVolume = _defaultMusicVolume;
  double get musicVolume => _musicVolume;

  bool isMusicEnabled = false; // Volume'a bağlı türetilir
  bool isClickSoundEnabled = false; // Varsayılan kapalı

  AudioService._();

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    // Eski anahtar okunsa da volume tabanlı mantık kullanılacak
    isClickSoundEnabled = prefs.getBool(_clickSoundEnabledKey) ?? false;

    // Kalıcı müzik ses seviyesini yükle
    final storedVol = prefs.getDouble(_musicVolumeKey);
    if (storedVol != null) {
      _musicVolume = storedVol.clamp(0.0, 1.0);
    }

    // Volume'a göre etkinlik türet
    isMusicEnabled = _musicVolume > 0.0;

    // Başlangıçta volume uygula
    try {
      await _audioPlayer.setVolume(_musicVolume);
    } catch (_) {}

    if (isMusicEnabled) {
      playMusic();
    } else {
      // Güvenlik: açık gelmişse bile durdur
      try { await _audioPlayer.stop(); } catch (_) {}
    }

    // Eski anahtarı senkronize et (opsiyonel)
    try { await prefs.setBool(_musicEnabledKey, isMusicEnabled); } catch (_) {}
  }

  void playMusic() {
    try {
      _audioPlayer.setReleaseMode(ReleaseMode.loop);
      // Çalmadan önce ses seviyesini uygula
      _audioPlayer.setVolume(_musicVolume);
      _audioPlayer.play(AssetSource('tatli-muzik.mp3'));
    } catch (e) {
      debugPrint("Müzik çalınamadı: $e");
    }
  }

  void pauseMusic() {
    _audioPlayer.pause();
  }

  // YENİ: Duraklatılmış müziği kaldığı yerden devam ettirir
  void resumeMusic() {
    try {
      if (isMusicEnabled && _musicVolume > 0) {
        _audioPlayer.resume();
      }
    } catch (e) {
      debugPrint('Müzik devam ettirilemedi: $e');
    }
  }

  Future<void> toggleMusic(bool enable) async {
    // Geriye dönük: enable true ise mevcut volume ile çal, false ise durdur; volume'u değiştirme
    final prefs = await SharedPreferences.getInstance();
    if (enable) {
      if (_musicVolume <= 0) {
        // Sessizlikten açılırsa, makul bir varsayılan uygula
        _musicVolume = _defaultMusicVolume;
        try { await _audioPlayer.setVolume(_musicVolume); } catch (_) {}
        try { await prefs.setDouble(_musicVolumeKey, _musicVolume); } catch (_) {}
      }
      isMusicEnabled = true;
      playMusic();
    } else {
      isMusicEnabled = false;
      pauseMusic();
    }
    try { await prefs.setBool(_musicEnabledKey, isMusicEnabled); } catch (_) {}
  }

  // Aralık dışı değerler sınırlandırılır ve kalıcı kaydedilir.
  // 0.0 -> müzik durur, >0 -> gerekirse başlatılır.
  Future<void> setMusicVolume(double volume) async {
    final v = volume.clamp(0.0, 1.0);
    final wasEnabled = isMusicEnabled;
    _musicVolume = v;
    try {
      await _audioPlayer.setVolume(v);
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_musicVolumeKey, v);
    } catch (_) {}

    // Durum değişimini yönet
    if (v <= 0.0) {
      isMusicEnabled = false;
      try { await _audioPlayer.pause(); } catch (_) {}
      // Eski anahtarı da güncelle
      try { final prefs = await SharedPreferences.getInstance(); await prefs.setBool(_musicEnabledKey, false); } catch (_) {}
    } else {
      isMusicEnabled = true;
      // Önceden kapalıysa başlat
      if (!wasEnabled) {
        playMusic();
      }
      try { final prefs = await SharedPreferences.getInstance(); await prefs.setBool(_musicEnabledKey, true); } catch (_) {}
    }
  }

  Future<void> toggleClickSound(bool enable) async {
    isClickSoundEnabled = enable;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_clickSoundEnabledKey, enable);
  }

  Future<void> playClick() async {

    return;
  }

  void dispose() {
    _audioPlayer.dispose();
    _sfxPlayer.dispose();
  }
}