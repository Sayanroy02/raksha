// ─────────────────────────────────────────────
//  home_view.dart
//  Main home screen matching the UI design:
//
//  ┌────────────────────────────────────┐
//  │  Hello, Priya 👋     🔔            │
//  │  Stay aware. Stay safe.            │
//  │                                    │
//  │         ◉  SOS  (hold 3s)          │
//  │                                    │
//  │  [Live Loc] [AI Threat]            │
//  │  [Evidence] [Safety Circle]        │
//  │                                    │
//  │  🏠   🗺️   📜   👤               │← bottom nav
//  └────────────────────────────────────┘
// ─────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/sos_controller.dart';
import '../../routes/app_routes.dart';
import '../../services/permission_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/feature_card.dart';
import '../../widgets/sos_button.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (Get.isRegistered<PermissionService>()) {
        final perm = Get.find<PermissionService>();
        final hasAll = await perm.hasAllCriticalPermissions();
        if (!hasAll) {
          await perm.requestAllSafetyPermissions(showDialogFirst: true);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final sos  = Get.find<SosController>();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      bottomNavigationBar: const RakshaBottomNav(currentIndex: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Header ──────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Obx(() {
                    final name = auth.user.value?.firstName ?? 'there';
                    return RichText(
                      text: TextSpan(children: [
                        TextSpan(
                          text: 'Hello, $name ',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const TextSpan(text: '👋', style: TextStyle(fontSize: 22)),
                      ]),
                    );
                  }),
                  // Notification bell
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: const Icon(Icons.notifications_outlined,
                        color: AppColors.primary),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms),

              const SizedBox(height: 4),

              Text(
                'Stay aware. Stay safe.',
                style: Theme.of(context).textTheme.bodyMedium,
              ).animate(delay: 100.ms).fadeIn(),

              const SizedBox(height: 36),

              // ── SOS Button (centre) ─────────────
              Center(child: SosButton(controller: sos))
                  .animate(delay: 200.ms)
                  .scale(duration: 600.ms, curve: Curves.elasticOut),

              const SizedBox(height: 12),

              // SOS instruction text
              Center(
                child: Text(
                  'Hold for ${3} seconds to alert your\ntrusted contacts and share location.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ).animate(delay: 300.ms).fadeIn(),

              const SizedBox(height: 36),

              // ── Guardian QR Code Tracking Banner ──
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.18),
                      AppColors.cardBg,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Guardian QR & Audio Link',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Share your QR to let guardians track your phone & audio.',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      children: [
                        ElevatedButton(
                          onPressed: () => Get.toNamed(AppRoutes.guardianQr),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text('My QR', style: GoogleFonts.poppins(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(height: 6),
                        OutlinedButton(
                          onPressed: () => Get.toNamed(AppRoutes.guardianScanner),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: AppColors.divider),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text('Scan QR', style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70)),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.1),

              // ── Feature Grid 2×2 ────────────────
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.1,
                children: [
                  FeatureCard(
                    icon: Icons.location_on_rounded,
                    label: 'Live Location',
                    subtitle: 'Share your location\nin real-time',
                    onTap: () => Get.toNamed(AppRoutes.liveLocation),
                  ).animate(delay: 350.ms).fadeIn().slideY(begin: 0.15),

                  FeatureCard(
                    icon: Icons.radar_rounded,
                    label: 'AI Threat Detection',
                    subtitle: 'Scan for unsafe\nsurroundings',
                    onTap: () => Get.toNamed(AppRoutes.threatDetection),
                  ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.15),

                  FeatureCard(
                    icon: Icons.camera_alt_rounded,
                    label: 'Evidence Capture',
                    subtitle: 'Record & save\nimportant evidence',
                    onTap: () => Get.toNamed(AppRoutes.evidence),
                  ).animate(delay: 450.ms).fadeIn().slideY(begin: 0.15),

                  FeatureCard(
                    icon: Icons.group_rounded,
                    label: 'Safety Circle',
                    subtitle: 'Your trusted\ncontacts',
                    onTap: () => Get.toNamed(AppRoutes.safetyCircle),
                  ).animate(delay: 500.ms).fadeIn().slideY(begin: 0.15),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
