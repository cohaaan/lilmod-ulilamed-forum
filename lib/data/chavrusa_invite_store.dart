import 'package:shared_preferences/shared_preferences.dart';

/// Holds a validated invite code between OAuth redirect and redemption.
class ChavrusaInviteStore {
  static const _pendingKey = 'chavrusa_pending_invite_code';

  static Future<void> savePendingCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingKey, code.trim());
  }

  static Future<String?> peekPendingCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pendingKey);
  }

  static Future<String?> takePendingCode() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_pendingKey);
    if (code != null) await prefs.remove(_pendingKey);
    return code;
  }

  static Future<void> clearPendingCode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingKey);
  }
}
