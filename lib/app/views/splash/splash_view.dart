// ─────────────────────────────────────────────
//  splash_view.dart
//  First screen shown on app launch.
//  Animates the Raksha+ logo then checks
//  if the user is already logged in:
//  • Logged in  → go to Home
//  • First launch → go to Onboarding
//  • Returning but not logged in → go to Login
// ─────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../routes/app_routes.dart';
import '../../services/app_lock_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_colors.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    // 1. Primary navigation after splash branding animation
    Future.delayed(const Duration(milliseconds: 2200), _safeNavigate);

    // 2. Failsafe backup timer: GUARANTEES the app never hangs on splash
    Future.delayed(const Duration(milliseconds: 4000), () {
      if (!_hasNavigated && mounted) {
        debugPrint('[SplashView] Failsafe backup timer triggered');
        _safeNavigate();
      }
    });
  }

  Future<void> _safeNavigate() async {
    if (_hasNavigated) return;
    _hasNavigated = true;

    try {
      final storage = Get.find<StorageService>();

      // First ever launch → onboarding
      bool isFirst = false;
      try {
        isFirst = await storage.isFirstLaunch().timeout(
          const Duration(seconds: 2),
          onTimeout: () => false,
        );
      } catch (_) {
        isFirst = false;
      }

      if (isFirst) {
        try {
          await storage.setFirstLaunchDone();
        } catch (_) {}
        Get.offAllNamed(AppRoutes.onboarding);
        return;
      }

      // Returning user — check for a stored access token
      String? token;
      try {
        token = await storage.getAccessToken().timeout(
          const Duration(seconds: 2),
          onTimeout: () => null,
        );
      } catch (_) {
        token = null;
      }

      if (token != null && token.isNotEmpty) {
        if (AppLockService().isLockEnabled) {
          if (!mounted) return;
          AppLockService().showUnlockBarrier(context, () {
            Get.offAllNamed(AppRoutes.home);
          });
        } else {
          Get.offAllNamed(AppRoutes.home);
        }
      } else {
        Get.offAllNamed(AppRoutes.login);
      }
    } catch (e) {
      debugPrint('[SplashView] Navigation exception: $e');
      Get.offAllNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Shield logo icon / Badge ─────────────────
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.5),
                    blurRadius: 36,
                    spreadRadius: 6,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/logo/Protective Gradient Profile Badge.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: AppColors.pinkGradient),
                    ),
                    child: const Icon(Icons.shield_rounded, size: 60, color: Colors.white),
                  ),
                ),
              ),
            )
                .animate()
                .scale(duration: 600.ms, curve: Curves.elasticOut)
                .fadeIn(duration: 400.ms),

            const SizedBox(height: 24),

            // ── App name ────────────────────────
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Raksha',
                    style: GoogleFonts.poppins(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  TextSpan(
                    text: '+',
                    style: GoogleFonts.poppins(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            )
                .animate(delay: 400.ms)
                .slideY(begin: 0.3, end: 0, duration: 500.ms)
                .fadeIn(duration: 500.ms),

            const SizedBox(height: 8),

            // ── Tagline ─────────────────────────
            Text(
              'Safer Steps. Brighter Tomorrows.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            )
                .animate(delay: 700.ms)
                .fadeIn(duration: 600.ms),

            const SizedBox(height: 60),

            // ── Loading indicator ───────────────
            SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
              ),
            ).animate(delay: 1000.ms).fadeIn(duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
