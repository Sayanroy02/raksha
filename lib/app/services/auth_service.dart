// ─────────────────────────────────────────────
//  auth_service.dart
//  Handles all authentication API calls:
//  register, login, and token refresh.
// ─────────────────────────────────────────────
import 'package:dio/dio.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api;

  AuthService(this._api);

  /// Register a new user account
  /// POST /auth/register
  Future<Response> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) {
    return _api.dio.post('/auth/register', data: {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
    });
  }

  /// Login with email + password — returns {access_token, refresh_token}
  /// POST /auth/login
  Future<Response> login({
    required String email,
    required String password,
  }) {
    return _api.dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
  }

  /// Get the current user's profile
  /// GET /auth/me
  Future<Response> getMe() {
    return _api.dio.get('/auth/me');
  }

  /// Update the current user's profile and personal info
  /// PATCH /auth/me
  Future<Response> updateProfile(Map<String, dynamic> data) {
    return _api.dio.patch('/auth/me', data: data);
  }

  /// Refresh access token using refresh token
  /// POST /auth/refresh  (Authorization: Bearer `<refresh_token>`)
  Future<Response> refresh(String refreshToken) {
    return _api.dio.post(
      '/auth/refresh',
      options: Options(headers: {'Authorization': 'Bearer $refreshToken'}),
    );
  }
}
