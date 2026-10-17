// ─────────────────────────────────────────────
//  constants.dart
//  App-wide constants: API URLs, keys, timeouts.
//  Switch between prod and local by toggling
//  the `_useProduction` flag below.
// ─────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  AppConstants._();

  // ── API Configuration ────────────────────────
  /// Set USE_PRODUCTION in .env to false during local development
  static bool get _useProduction =>
      (dotenv.env['USE_PRODUCTION'] ?? 'true').toLowerCase() == 'true';

  /// Production backend deployed on Render
  static String get _prodBase =>
      dotenv.env['PROD_API_BASE_URL'] ?? 'https://raksha-plus.onrender.com/api/v1';

  /// Local backend
  static String get _localBase {
    final customLocal = dotenv.env['LOCAL_API_BASE_URL'];
    if (customLocal != null && customLocal.isNotEmpty) return customLocal;
    return kIsWeb ? 'http://localhost:8000/api/v1' : 'http://10.0.2.2:8000/api/v1';
  }

  /// Active base URL
  static String get apiBaseUrl => _useProduction ? _prodBase : _localBase;

  // ── Maps & Geolocation ────────────────────────
  static String get googleMapsApiKey =>
      dotenv.env['GOOGLE_MAPS_API_KEY'] ??
      'AIzaSyAu4M-9XYXvSJ-cS-1rdT1ckbGSuHgKhwQ';

  static String get geoapifyApiKey =>
      dotenv.env['GEOAPIFY_API_KEY_GEOLOCATOR'] ?? '';

  static String get resendApiKey =>
      dotenv.env['RESEND_API_KEY'] ?? '';

  // ── Token Storage Keys ───────────────────────
  static const String kAccessToken  = 'access_token';
  static const String kRefreshToken = 'refresh_token';
  static const String kUserData     = 'user_data';
  static const String kFirstLaunch  = 'first_launch';

  // ── SOS ─────────────────────────────────────
  /// Duration the user must hold the SOS button before it triggers (seconds)
  static const int sosHoldDuration = 3;

  // ── Timeouts ────────────────────────────────
  static const int connectTimeout = 30; // seconds
  static const int receiveTimeout = 30; // seconds

  // ── Location ────────────────────────────────
  /// How often to broadcast location during live sharing (seconds)
  static const int locationBroadcastInterval = 10;

  // ── App Info ────────────────────────────────
  static const String appName    = 'Raksha+';
  static const String appTagline = 'Safer Steps. Brighter Tomorrows.';
}
