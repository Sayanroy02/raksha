// ─────────────────────────────────────────────
//  main.dart
//  Entry point for the Raksha+ Flutter app.
//
//  Uses GetMaterialApp so GetX can handle:
//  • Navigation (named routes with transitions)
//  • State management (GetX controllers)
//  • Dependency injection (Bindings)
//  • Snackbars and dialogs
// ─────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';

import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/services/app_lock_service.dart';
import 'app/theme/app_theme.dart';
import 'app/utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables (.env)
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // If .env file not bundled, fallback to defaults in AppConstants
  }

  // Initialize App Lock Service (Device Lock & 4-Digit Security PIN)
  try {
    await AppLockService().init();
  } catch (e) {
    debugPrint('[Main] AppLock init error: $e');
  }

  // Lock orientation to portrait for mobile — keeps UI consistent
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Make the status bar transparent so our dark bg shows through
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const RakshaApp());
}

class RakshaApp extends StatelessWidget {
  const RakshaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      // ── App metadata ────────────────────────
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // ── Theme ───────────────────────────────
      theme: AppTheme.dark,

      // ── Routing ─────────────────────────────
      // GetX manages all navigation — no Navigator.push needed anywhere
      initialRoute: AppRoutes.splash,
      getPages: AppPages.routes,

      // ── Default page transition ──────────────
      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),

      // ── GetX Snackbar / Dialog locale ───────
      locale: const Locale('en', 'US'),
    );
  }
}
