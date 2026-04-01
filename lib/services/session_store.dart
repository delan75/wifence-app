import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class SessionStore {
  static const _tokenKey = 'wifence_access_token';
  static const _deviceIdKey = 'wifence_device_id';

  Future<String?> readToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<String> getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_deviceIdKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    final deviceId = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    await prefs.setString(_deviceIdKey, deviceId);
    return deviceId;
  }
}
