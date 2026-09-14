// ─────────────────────────────────────────────
//  auth_controller.dart
//  Manages authentication state for the app.
//
//  Responsibilities:
//  • Login / Register / Logout
//  • Persist + load user data from secure storage
//  • Expose current user to all views via GetX
// ─────────────────────────────────────────────
import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../models/user_model.dart';
import '../routes/app_routes.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AuthController extends GetxController {
  final AuthService    _authService;
  final StorageService _storage;

  AuthController(this._authService, this._storage);

  // ── Observable state ─────────────────────────
  final Rx<UserModel?> user        = Rx(null);
  final RxBool         isLoading   = false.obs;
  final RxString       errorMsg    = ''.obs;

  // Form field values (bound from TextEditingControllers in views)
  final RxString nameInput     = ''.obs;
  final RxString emailInput    = ''.obs;
  final RxString phoneInput    = ''.obs;
  final RxString passwordInput = ''.obs;

  // ── Lifecycle ────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    // Try to load saved user data so we can show the greeting immediately
    _loadSavedUser();
  }

  Future<void> _loadSavedUser() async {
    final json = await _storage.getUserData();
    if (json != null) {
      user.value = UserModel.fromJsonString(json);
    }
  }

  // ── Public methods ───────────────────────────

  /// Login with email + password
  Future<void> login() async {
    if (emailInput.isEmpty || passwordInput.isEmpty) {
      errorMsg.value = 'Email and password are required';
      return;
    }
    isLoading.value = true;
    errorMsg.value  = '';
    try {
      final resp = await _authService.login(
        email:    emailInput.value.trim(),
        password: passwordInput.value,
      );
      await _handleTokenResponse(resp.data as Map<String, dynamic>);
      Get.offAllNamed(AppRoutes.home);
    } on DioException catch (e) {
      errorMsg.value = _parseError(e);
    } finally {
      isLoading.value = false;
    }
  }

  /// Register a new account
  Future<void> register() async {
    if (nameInput.isEmpty || emailInput.isEmpty ||
        phoneInput.isEmpty || passwordInput.isEmpty) {
      errorMsg.value = 'All fields are required';
      return;
    }
    isLoading.value = true;
    errorMsg.value  = '';
    try {
      final resp = await _authService.register(
        name:     nameInput.value.trim(),
        email:    emailInput.value.trim(),
        phone:    phoneInput.value.trim(),
        password: passwordInput.value,
      );
      await _handleTokenResponse(resp.data as Map<String, dynamic>);
      Get.offAllNamed(AppRoutes.home);
    } on DioException catch (e) {
      errorMsg.value = _parseError(e);
    } finally {
      isLoading.value = false;
    }
  }

  /// Clear all auth data and go to login screen
  Future<void> logout() async {
    await _storage.clearAll();
    user.value = null;
    Get.offAllNamed(AppRoutes.login);
  }

  // ── Private helpers ──────────────────────────

  /// Saves tokens + fetches /auth/me to populate user data
  Future<void> _handleTokenResponse(Map<String, dynamic> data) async {
    await _storage.saveAccessToken(data['access_token'] as String);
    if (data['refresh_token'] != null) {
      await _storage.saveRefreshToken(data['refresh_token'] as String);
    }
    // Fetch full user profile
    try {
      final me = await _authService.getMe();
      final u  = UserModel.fromJson(me.data as Map<String, dynamic>);
      user.value = u;
      await _storage.saveUserData(u.toJsonString());
    } catch (_) {/* non-fatal */}
  }

  /// Extracts a readable error message from a Dio exception
  String _parseError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['detail'] != null) return data['detail'].toString();
    return e.message ?? 'Something went wrong';
  }
}
