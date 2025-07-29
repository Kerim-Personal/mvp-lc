import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioService {
  static final AudioService instance = AudioService._();

  final AudioPlayer _audioPlayer = AudioPlayer();
  static const _musicEnabledKey = 'music_enabled';

  bool isMusicEnabled = true;

  AudioService._();

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    isMusicEnabled = prefs.getBool(_musicEnabledKey) ?? true;

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

  void dispose() {
    _audioPlayer.dispose();
  }
}