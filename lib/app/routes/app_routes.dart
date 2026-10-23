// ─────────────────────────────────────────────
//  app_routes.dart
//  Named route constants used everywhere in the
//  app.  Centralising them avoids typos and
//  makes refactoring easy.
// ─────────────────────────────────────────────

abstract class AppRoutes {
  static const splash          = '/';
  static const onboarding      = '/onboarding';
  static const login           = '/login';
  static const register        = '/register';
  static const home            = '/home';
  static const liveLocation    = '/live-location';
  static const threatDetection = '/threat-detection';
  static const evidence        = '/evidence';
  static const safetyCircle   = '/safety-circle';
  static const locationHistory = '/location-history';
  static const safetyAssistant = '/safety-assistant';
  static const profile         = '/profile';
  static const personalInfo    = '/personal-info';
  static const notifications   = '/notifications';
  static const guardianQr      = '/guardian-qr';
  static const guardianScanner = '/guardian-scanner';
  static const guardianTrack   = '/guardian-track';
  static const fakeShutdown    = '/fake-shutdown';
}
