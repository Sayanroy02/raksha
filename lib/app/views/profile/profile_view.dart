// ─────────────────────────────────────────────
//  profile_view.dart
//  User profile screen with settings rows and
//  logout button — matching the UI design.
// ─────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/profile_controller.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bottom_nav_bar.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsItems = [
      _SettingsItem(Icons.person_outline_rounded,   'Personal Information',   AppRoutes.profile),
      _SettingsItem(Icons.qr_code_2_rounded,         'My Guardian QR Code',    AppRoutes.guardianQr),
      _SettingsItem(Icons.qr_code_scanner_rounded,   'Scan Guardian QR',       AppRoutes.guardianScanner),
      _SettingsItem(Icons.shield_outlined,           'Safety Circle',          AppRoutes.safetyCircle),
      _SettingsItem(Icons.location_on_outlined,      'Live Location',          AppRoutes.liveLocation),
      _SettingsItem(Icons.notifications_outlined,    'Notifications',          null),
      _SettingsItem(Icons.help_outline_rounded,      'Help & Support',         null),
      _SettingsItem(Icons.info_outline_rounded,      'About Raksha+',          null),
    ];

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      bottomNavigationBar: const RakshaBottomNav(currentIndex: 3),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          child: Column(
            children: [

              // ── Avatar + name ────────────────
              Obx(() {
                final user = controller.user.value;
                return Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                                colors: AppColors.pinkGradient),
                          ),
                          child: Center(
                            child: Text(
                              user?.name.isNotEmpty == true
                                  ? user!.name[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                        // Edit icon overlay
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.cardBg,
                            ),
                            child: const Icon(Icons.edit_rounded,
                                size: 16, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    Text(
                      user?.name ?? 'User',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                );
              }).animate().fadeIn(duration: 400.ms),

              const SizedBox(height: 32),

              // ── Settings list ────────────────
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: List.generate(settingsItems.length, (i) {
                    final item = settingsItems[i];
                    return Column(
                      children: [
                        ListTile(
                          onTap: () {
                            if (item.route != null) Get.toNamed(item.route!);
                          },
                          leading: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(item.icon,
                                color: AppColors.primary, size: 20),
                          ),
                          title: Text(item.label,
                              style: GoogleFonts.poppins(
                                  fontSize: 14, color: Colors.white)),
                          trailing: const Icon(Icons.chevron_right_rounded,
                              color: AppColors.textHint),
                        ),
                        if (i < settingsItems.length - 1)
                          const Divider(
                              height: 1,
                              indent: 16,
                              endIndent: 16,
                              color: AppColors.divider),
                      ],
                    );
                  }),
                ),
              ).animate(delay: 150.ms).fadeIn().slideY(begin: 0.05),

              const SizedBox(height: 24),

              // ── Logout button ────────────────
              OutlinedButton.icon(
                onPressed: controller.logout,
                icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                label: const Text('Logout',
                    style: TextStyle(color: AppColors.error)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  minimumSize: const Size(double.infinity, 52),
                ),
              ).animate(delay: 250.ms).fadeIn(),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String   label;
  final String?  route;
  const _SettingsItem(this.icon, this.label, this.route);
}
