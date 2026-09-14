// ─────────────────────────────────────────────
//  api_service.dart
//  Central Dio HTTP client for all API calls.
//
//  Features:
//  • Auto-attaches Bearer token to every request
//  • Intercepts 401 responses → attempts token
//    refresh once, then logs the user out
//  • Pretty-logs all requests/responses in debug
// ─────────────────────────────────────────────
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../utils/constants.dart';
import '../routes/app_routes.dart';
import 'storage_service.dart';

class ApiService {
  late final Dio _dio;

  // Expose dio so individual services can call specific endpoints
  Dio get dio => _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: Duration(seconds: AppConstants.connectTimeout),
        receiveTimeout: Duration(seconds: AppConstants.receiveTimeout),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // ── Interceptors ──────────────────────────────

    // 1. Auth interceptor — injects token + handles 401
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Attach stored access token to every outgoing request
          final storage = Get.find<StorageService>();
          final token = await storage.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },

        onError: (DioException error, handler) async {
          // If 401 Unauthorized, try refreshing the access token once
          if (error.response?.statusCode == 401) {
            final refreshed = await _tryRefreshToken();
            if (refreshed) {
              // Retry original request with new token
              final opts = error.requestOptions;
              final storage = Get.find<StorageService>();
              opts.headers['Authorization'] =
                  'Bearer ${await storage.getAccessToken()}';
              try {
                final retryResp = await _dio.fetch(opts);
                return handler.resolve(retryResp);
              } catch (_) {}
            }
            // Refresh failed — force logout
            await Get.find<StorageService>().clearAll();
            Get.offAllNamed(AppRoutes.login);
          }
          handler.next(error);
        },
      ),
    );

    // 2. Pretty logger — prints readable request/response in debug mode
    _dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        compact: false,
      ),
    );
  }

  // ── Private helpers ──────────────────────────

  /// Calls /auth/refresh and stores new access token.
  /// Returns true on success, false on failure.
  Future<bool> _tryRefreshToken() async {
    try {
      final storage = Get.find<StorageService>();
      final refresh = await storage.getRefreshToken();
      if (refresh == null) return false;

      final resp = await Dio().post(
        '${AppConstants.apiBaseUrl}/auth/refresh',
        options: Options(headers: {'Authorization': 'Bearer $refresh'}),
      );
      await storage.saveAccessToken(resp.data['access_token']);
      return true;
    } catch (_) {
      return false;
    }
  }
}
