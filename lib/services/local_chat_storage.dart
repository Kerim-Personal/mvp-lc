// lib/services/local_chat_storage.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocachat/models/message_unit.dart';

class LocalChatStorage {
  LocalChatStorage._();
  static final LocalChatStorage instance = LocalChatStorage._();

  // Kullanıcıya ve dile göre anahtar oluştur
  String _key(String uid, String langCode) => 'vocabot_chat_${uid}_${langCode.toLowerCase()}';

  // Eski sürümlerde kullanılan anahtar (sadece dil bazlı)
  String _legacyKey(String langCode) => 'vocabot_chat_${langCode.toLowerCase()}';

  Future<List<MessageUnit>> load(String uid, String langCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? raw = prefs.getString(_key(uid, langCode));

      // Yeni anahtar yoksa: legacy varsa gizlilik için temizle ve boş dön
      if (raw == null || raw.isEmpty) {
        final legacyKey = _legacyKey(langCode);
        if (prefs.containsKey(legacyKey)) {
          try { await prefs.remove(legacyKey); } catch (_) {}
        }
      }

      if (raw == null || raw.isEmpty) return <MessageUnit>[];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <MessageUnit>[];
      final List<MessageUnit> list = [];
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          list.add(MessageUnit.fromPersistedMap(item));
        } else if (item is Map) {
          list.add(MessageUnit.fromPersistedMap(item.cast<String, dynamic>()));
        }
      }
      // Güvenlik: sadece son 20'yi tarih sırasına göre tut
      list.sort((a,b) => a.timestamp.compareTo(b.timestamp));
      return list.length <= 20 ? list : list.sublist(list.length - 20);
    } catch (_) {
      return <MessageUnit>[];
    }
  }

  Future<void> save(String uid, String langCode, List<MessageUnit> messages) async {
    try {
      // Son 20'yi al (eski->yeni sırası)
      final List<MessageUnit> sorted = List.of(messages)..sort((a,b)=> a.timestamp.compareTo(b.timestamp));
      final List<MessageUnit> last20 = sorted.length <= 20 ? sorted : sorted.sublist(sorted.length - 20);
      final data = last20.map((m) => m.toPersistedMap()).toList();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key(uid, langCode), jsonEncode(data));
    } catch (_) {
      // sessizce geç
    }
  }
}
