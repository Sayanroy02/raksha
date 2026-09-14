// ─────────────────────────────────────────────
//  storage_service.dart
//  Wraps flutter_secure_storage to safely store
//  JWT tokens and basic user data.
//  Registered as a permanent GetX service so it
//  is available across the entire app lifecycle.
// ─────────────────────────────────────────────
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class StorageService {
  // flutter_secure_storage uses the OS keychain / keystore
  final _secure = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ── Token helpers ────────────────────────────

  Future<void> saveAccessToken(String token) =>
      _secure.write(key: AppConstants.kAccessToken, value: token);

  Future<String?> getAccessToken() =>
      _secure.read(key: AppConstants.kAccessToken);

  Future<void> saveRefreshToken(String token) =>
      _secure.write(key: AppConstants.kRefreshToken, value: token);

  Future<String?> getRefreshToken() =>
      _secure.read(key: AppConstants.kRefreshToken);

  Future<void> saveUserData(String json) =>
      _secure.write(key: AppConstants.kUserData, value: json);

  Future<String?> getUserData() =>
      _secure.read(key: AppConstants.kUserData);

  /// Clears all tokens — called on logout
  Future<void> clearAll() => _secure.deleteAll();

  // ── SharedPreferences (non-sensitive) ───────

  Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.kFirstLaunch) ?? true;
  }

  Future<void> setFirstLaunchDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.kFirstLaunch, false);
  }
}
