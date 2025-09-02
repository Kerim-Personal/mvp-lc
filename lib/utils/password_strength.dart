// lib/utils/password_strength.dart
import 'dart:math';

class PasswordStrengthResult {
  final int score; // 0-100
  final String label; // "Very Weak" ... "Very Strong"
  final List<String> unmetCriteria; // English descriptions
  final bool allSatisfied;

  const PasswordStrengthResult({
    required this.score,
    required this.label,
    required this.unmetCriteria,
    required this.allSatisfied,
  });
}

class PasswordStrength {
  // Descriptions for criteria (to show in the UI)
  static const String minLengthMsg = 'At least 10 characters';
  static const String upperMsg = 'One uppercase letter';
  static const String lowerMsg = 'One lowercase letter';
  static const String digitMsg = 'One number';
  static const String specialMsg = 'One special character (!@#...)';
  static const String noSpaceMsg = 'No spaces';
  static const String notCommonMsg = 'Not a common password or part of email';
  static const String notSameAsOldMsg = 'Not the same as the old password';

  static final RegExp _upper = RegExp(r'[A-Z]');
  static final RegExp _lower = RegExp(r'[a-z]');
  static final RegExp _digit = RegExp(r'[0-9]');
  static final RegExp _special = RegExp(r'[!@#$%^&*(),.?":{}|<>_\-\[\]\\/;+=]');

  /// Evaluates the password and returns a score + unmet criteria.
  /// [emailLocalPart] optional: the password will be weaker if it contains the local part of the email (before the @).
  /// [oldPassword] optional: if it's the same, the criterion is considered unmet.
  static PasswordStrengthResult evaluate(String password, {String? emailLocalPart, String? oldPassword}) {
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
    if (lowerPwd.contains('password')) commonOk = false; // classic
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

    // Score calculation (each main criterion is ~12 points, extra length is a bonus)
    int baseScore = 0;
    if (lengthOk) baseScore += 12;
    if (upperOk) baseScore += 12;
    if (lowerOk) baseScore += 12;
    if (digitOk) baseScore += 12;
    if (specialOk) baseScore += 12;
    if (noSpaceOk) baseScore += 8;
    if (commonOk) baseScore += 12;
    if (sameAsOldOk) baseScore += 10;
    // Extra length bonus: each character after 10 adds 2 points (max +20)
    if (password.length > 10) {
      baseScore += min(20, (password.length - 10) * 2);
    }
    if (baseScore > 100) baseScore = 100;

    String label;
    if (baseScore < 30) label = 'Very Weak';
    else if (baseScore < 50) label = 'Weak';
    else if (baseScore < 70) label = 'Medium';
    else if (baseScore < 85) label = 'Strong';
    else label = 'Very Strong';

    return PasswordStrengthResult(
      score: baseScore,
      label: label,
      unmetCriteria: unmet,
      allSatisfied: unmet.isEmpty,
    );
  }
}