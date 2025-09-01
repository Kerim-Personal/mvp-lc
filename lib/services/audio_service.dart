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

  bool isMusicEnabled = false; // Varsayılan artık kapalı
  bool isClickSoundEnabled = false; // Varsayılan kapalı

  AudioService._();

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    // Varsayılanları false yaptık
    isMusicEnabled = prefs.getBool(_musicEnabledKey) ?? false;
    isClickSoundEnabled = prefs.getBool(_clickSoundEnabledKey) ?? false;

    if (isMusicEnabled) {
      playMusic();
    }
  }

  void playMusic() {
    try {
      _audioPlayer.setReleaseMode(ReleaseMode.loop);
      _audioPlayer.play(AssetSource('tatli-muzik.mp3'));
    } catch (e) {
      debugPrint("Müzik çalınamadı: $e");
    }
  }

  void pauseMusic() {
    _audioPlayer.pause();
  }

  Future<void> toggleMusic(bool enable) async {
    isMusicEnabled = enable;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_musicEnabledKey, enable);

    if (enable) {
      playMusic();
    } else {
      pauseMusic();
    }
  }

  Future<void> toggleClickSound(bool enable) async {
    isClickSoundEnabled = enable;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_clickSoundEnabledKey, enable);
  }

  /// Uygulama genelinde tuş / buton etkileşimlerinde çağrılabilir.
  /// assets/ klasörüne koyacağınız kısa bir ses dosyasını (ör: click.mp3) çalar.
  Future<void> playClick() async {
    if (!isClickSoundEnabled) return;
    try {
      await _sfxPlayer.stop(); // Hızlı ardışık tıklamalarda üst üste binmesin
      await _sfxPlayer.play(AssetSource('click.mp3'));
    } catch (e) {
      debugPrint('Click ses çalınamadı: $e');
    }
  }

  void dispose() {
    _audioPlayer.dispose();
    _sfxPlayer.dispose();
  }
}