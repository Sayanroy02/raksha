// ─────────────────────────────────────────────
//  storage_service.dart
//  Wraps flutter_secure_storage with SharedPreferences fallback.
//  Safe against Android Keystore decryption corruption & resets.
// ─────────────────────────────────────────────
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class StorageService {
  final _secure = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
  );

  // ── Token helpers ────────────────────────────

  Future<void> saveAccessToken(String token) async {
    try {
      await _secure.write(key: AppConstants.kAccessToken, value: token);
    } catch (e) {
      debugPrint('[StorageService] Error writing access token: $e');
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.kAccessToken, token);
    } catch (_) {}
  }

  Future<String?> getAccessToken() async {
    try {
      final token = await _secure.read(key: AppConstants.kAccessToken);
      if (token != null && token.isNotEmpty) return token;
    } catch (e) {
      debugPrint('[StorageService] Error reading access token: $e');
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(AppConstants.kAccessToken);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveRefreshToken(String token) async {
    try {
      await _secure.write(key: AppConstants.kRefreshToken, value: token);
    } catch (e) {
      debugPrint('[StorageService] Error writing refresh token: $e');
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.kRefreshToken, token);
    } catch (_) {}
  }

  Future<String?> getRefreshToken() async {
    try {
      final token = await _secure.read(key: AppConstants.kRefreshToken);
      if (token != null && token.isNotEmpty) return token;
    } catch (e) {
      debugPrint('[StorageService] Error reading refresh token: $e');
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(AppConstants.kRefreshToken);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveUserData(String json) async {
    try {
      await _secure.write(key: AppConstants.kUserData, value: json);
    } catch (e) {
      debugPrint('[StorageService] Error writing user data: $e');
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.kUserData, json);
    } catch (_) {}
  }

  Future<String?> getUserData() async {
    try {
      final data = await _secure.read(key: AppConstants.kUserData);
      if (data != null && data.isNotEmpty) return data;
    } catch (e) {
      debugPrint('[StorageService] Error reading user data: $e');
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(AppConstants.kUserData);
    } catch (_) {
      return null;
    }
  }

  /// Clears all tokens — called on logout
  Future<void> clearAll() async {
    try {
      await _secure.deleteAll();
    } catch (e) {
      debugPrint('[StorageService] Error clearing secure storage: $e');
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.kAccessToken);
      await prefs.remove(AppConstants.kRefreshToken);
      await prefs.remove(AppConstants.kUserData);
    } catch (_) {}
  }

  // ── SharedPreferences (non-sensitive) ───────

  Future<bool> isFirstLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(AppConstants.kFirstLaunch) ?? true;
    } catch (e) {
      debugPrint('[StorageService] Error checking first launch: $e');
      return true;
    }
  }

  Future<void> setFirstLaunchDone() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.kFirstLaunch, false);
    } catch (e) {
      debugPrint('[StorageService] Error setting first launch done: $e');
    }
  }
}
