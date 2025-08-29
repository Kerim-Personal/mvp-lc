// lib/utils/password_strength.dart
import 'dart:math';

class PasswordStrengthResult {
  final int score; // 0-100
  final String label; // "Çok Zayıf" ... "Çok Güçlü"
  final List<String> unmetCriteria; // Türkçe açıklamalar
  final bool allSatisfied;

  const PasswordStrengthResult({
    required this.score,
    required this.label,
    required this.unmetCriteria,
    required this.allSatisfied,
  });
}

class PasswordStrength {
  // Kriterler için açıklamalar (UI'da göstermek için)
  static const String minLengthMsg = 'En az 10 karakter';
  static const String upperMsg = 'Bir büyük harf';
  static const String lowerMsg = 'Bir küçük harf';
  static const String digitMsg = 'Bir rakam';
  static const String specialMsg = 'Bir özel karakter (!@#...)';
  static const String noSpaceMsg = 'Boşluk içermez';
  static const String notCommonMsg = '"password" veya email içeriği yok';
  static const String notSameAsOldMsg = 'Eski şifre ile aynı değil';

  static final RegExp _upper = RegExp(r'[A-ZĞÜŞİÖÇ]');
  static final RegExp _lower = RegExp(r'[a-zğüşıöç]');
  static final RegExp _digit = RegExp(r'[0-9]');
  static final RegExp _special = RegExp(r'[!@#$%^&*(),.?":{}|<>_\-\[\]\\/;+=]');

  /// Şifreyi değerlendirir ve skor + eksik kriterleri döner.
  /// [emailLocalPart] opsiyonel: şifre email'in local part'ını ( @ öncesi ) içeriyorsa zayıflatılır.
  /// [oldPassword] opsiyonel: aynıysa kriter eksik sayılır.
  static PasswordStrengthResult evaluate(String password,{String? emailLocalPart, String? oldPassword}) {
    final unmet = <String>[];

    final lengthOk = password.length >= 10;
    if (!lengthOk) unmet.add(minLengthMsg);
    final upperOk = _upper.hasMatch(password);
    if (!upperOk) unmet.add(upperMsg);
    final lowerOk = _lower.hasMatch(password);
    if (!lowerOk) unmet.add(lowerMsg);
    final digitOk = _digit.hasMatch(password);
    if (!digitOk) unmet.add(digitMsg);
    final specialOk = _special.hasMatch(password);
    if (!specialOk) unmet.add(specialMsg);
    final noSpaceOk = !password.contains(' ');
    if (!noSpaceOk) unmet.add(noSpaceMsg);

    bool commonOk = true;
    final lowerPwd = password.toLowerCase();
    if (lowerPwd.contains('password')) commonOk = false; // klasik
    if (emailLocalPart != null && emailLocalPart.isNotEmpty) {
      final lp = emailLocalPart.toLowerCase();
      if (lp.length >= 3 && lowerPwd.contains(lp)) commonOk = false;
    }
    if (!commonOk) unmet.add(notCommonMsg);

    bool sameAsOldOk = true;
    if (oldPassword != null && oldPassword.isNotEmpty && password == oldPassword) {
      sameAsOldOk = false;
      unmet.add(notSameAsOldMsg);
    }

    // Skor hesaplama (her ana kriter ~12 puan, uzunluk fazlası bonus)
    int baseScore = 0;
    if (lengthOk) baseScore += 12;
    if (upperOk) baseScore += 12;
    if (lowerOk) baseScore += 12;
    if (digitOk) baseScore += 12;
    if (specialOk) baseScore += 12;
    if (noSpaceOk) baseScore += 8;
    if (commonOk) baseScore += 12;
    if (sameAsOldOk) baseScore += 10;
    // Ek uzunluk bonusu: 10'dan sonraki her karakter 2 puan (max +20)
    if (password.length > 10) {
      baseScore += min(20, (password.length - 10) * 2);
    }
    if (baseScore > 100) baseScore = 100;

    String label;
    if (baseScore < 30) label = 'Çok Zayıf';
    else if (baseScore < 50) label = 'Zayıf';
    else if (baseScore < 70) label = 'Orta';
    else if (baseScore < 85) label = 'Güçlü';
    else label = 'Çok Güçlü';

    return PasswordStrengthResult(
      score: baseScore,
      label: label,
      unmetCriteria: unmet,
      allSatisfied: unmet.isEmpty,
    );
  }
}
