import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  ThemeService._();
  static final ThemeService instance = ThemeService._();

  static const _themeModeKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.light; // varsayılan aydınlık
  ThemeMode get themeMode => _themeMode;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_themeModeKey);
    switch (stored) {
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      case 'system':
        _themeMode = ThemeMode.system;
        break;
      default:
        _themeMode = ThemeMode.light;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    final value = switch (mode) { ThemeMode.dark => 'dark', ThemeMode.system => 'system', _ => 'light' };
    await prefs.setString(_themeModeKey, value);
    notifyListeners();
  }

  ThemeData get lightTheme => ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 4,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );

  // Karanlık + Glassmorphism teması
  ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    // Önceki cam efekt çok saydamdı; opaklığı artırıyoruz
    const scaffold = Color(0xFF0E0F13);      // Ana arka plan
    const surface = Color(0xFF1A1D21);       // Sheet / dialog yüzeyi
    const card = Color(0xFF22262B);          // Kart yüzeyi
    const elevated = Color(0xFF272C31);      // Hafif yükseltilmiş alan
    final highlight = Colors.tealAccent.shade400;

    return base.copyWith(
      scaffoldBackgroundColor: scaffold,
      colorScheme: base.colorScheme.copyWith(
        surface: surface,
        // background deprecated uyarısını kaldırmak için set etmiyoruz
        primary: highlight,
        secondary: Colors.tealAccent.shade200,
        onSurface: Colors.white.withValues(alpha: 0.92),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        foregroundColor: Colors.white.withValues(alpha: 0.95),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.45),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: elevated,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerColor: Colors.white.withValues(alpha: 0.10),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: elevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.tealAccent, width: 1.2),
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: Colors.white.withValues(alpha: 0.92),
        displayColor: Colors.white.withValues(alpha: 0.92),
      ),
      iconTheme: IconThemeData(color: Colors.white.withValues(alpha: 0.9)),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? highlight : Colors.grey.shade500),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected)
            ? highlight.withValues(alpha: 0.35)
            : Colors.white.withValues(alpha: 0.15)),
      ),
    );
  }
}
