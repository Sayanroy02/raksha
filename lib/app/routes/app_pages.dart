// ─────────────────────────────────────────────
//  app_pages.dart
//  GetX route table — maps route names to their
//  View widgets and Bindings (DI).
//  GetMaterialApp uses this list instead of
//  Flutter's standard routes map.
// ─────────────────────────────────────────────
import 'package:get/get.dart';

import '../bindings/splash_binding.dart';
import '../bindings/auth_binding.dart';
import '../bindings/home_binding.dart';
import '../bindings/location_binding.dart';
import '../bindings/threat_binding.dart';
import '../bindings/evidence_binding.dart';
import '../bindings/contacts_binding.dart';
import '../bindings/chat_binding.dart';
import '../bindings/profile_binding.dart';

import '../views/splash/splash_view.dart';
import '../views/onboarding/onboarding_view.dart';
import '../views/auth/login_view.dart';
import '../views/auth/register_view.dart';
import '../views/home/home_view.dart';
import '../views/live_location/live_location_view.dart';
import '../views/threat_detection/threat_detection_view.dart';
import '../views/evidence/evidence_view.dart';
import '../views/safety_circle/safety_circle_view.dart';
import '../views/location_history/location_history_view.dart';
import '../views/safety_assistant/safety_assistant_view.dart';
import '../views/profile/profile_view.dart';
import '../views/profile/personal_info_view.dart';
import '../views/notifications/notifications_view.dart';
import '../views/guardian/guardian_qr_view.dart';
import '../views/guardian/guardian_scanner_view.dart';
import '../views/guardian/guardian_track_view.dart';

import 'app_routes.dart';

class AppPages {
  AppPages._();

  static final routes = [
    // Splash — initial route, checks token and redirects
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),

    // Onboarding — shown only on first launch
    GetPage(
      name: AppRoutes.onboarding,
      page: () => const OnboardingView(),
      transition: Transition.fadeIn,
    ),

    // Auth
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
      binding: AuthBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.register,
      page: () => const RegisterView(),
      binding: AuthBinding(),
      transition: Transition.rightToLeft,
    ),

    // Main app screens
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.liveLocation,
      page: () => const LiveLocationView(),
      binding: LocationBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.threatDetection,
      page: () => const ThreatDetectionView(),
      binding: ThreatBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.evidence,
      page: () => const EvidenceView(),
      binding: EvidenceBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.safetyCircle,
      page: () => const SafetyCircleView(),
      binding: ContactsBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.locationHistory,
      page: () => const LocationHistoryView(),
      binding: LocationBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.safetyAssistant,
      page: () => const SafetyAssistantView(),
      binding: ChatBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfileView(),
      binding: ProfileBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.personalInfo,
      page: () => const PersonalInfoView(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.notifications,
      page: () => const NotificationsView(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.guardianQr,
      page: () => const GuardianQrView(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.guardianScanner,
      page: () => const GuardianScannerView(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.guardianTrack,
      page: () => const GuardianTrackView(),
      transition: Transition.rightToLeft,
    ),
  ];
}
