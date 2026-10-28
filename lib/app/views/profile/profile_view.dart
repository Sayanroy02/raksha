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
import '../../services/app_lock_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bottom_nav_bar.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    controller.loadUser();

    final settingsItems = [
      _SettingsItem(Icons.person_outline_rounded,   'Personal Information',   AppRoutes.personalInfo),
      _SettingsItem(Icons.lock_outline_rounded,      'App Lock & PIN Security', null),
      _SettingsItem(Icons.power_settings_new_rounded,'Fake Switch-Off (Stealth)', AppRoutes.fakeShutdown),
      _SettingsItem(Icons.qr_code_2_rounded,         'My Guardian QR Code',    AppRoutes.guardianQr),
      _SettingsItem(Icons.qr_code_scanner_rounded,   'Scan Guardian QR',       AppRoutes.guardianScanner),
      _SettingsItem(Icons.shield_outlined,           'Safety Circle',          AppRoutes.safetyCircle),
      _SettingsItem(Icons.location_on_outlined,      'Live Location',          AppRoutes.liveLocation),
      _SettingsItem(Icons.local_hospital_outlined,   'Nearby Police & Hospitals', AppRoutes.nearbyServices),
      _SettingsItem(Icons.notifications_outlined,    'Notifications',          AppRoutes.notifications),
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
                return GestureDetector(
                  onTap: () => Get.toNamed(AppRoutes.personalInfo)?.then((_) => controller.loadUser()),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 88,
                            height: 88,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(colors: AppColors.pinkGradient),
                            ),
                            child: Center(
                              child: Text(
                                user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
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
                              child: const Icon(Icons.edit_rounded, size: 16, color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      Text(
                        user?.name.isNotEmpty == true ? user!.name : 'Raksha+ User',
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
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        alignment: WrapAlignment.center,
                        children: [
                          if (user?.bloodGroup != null && user!.bloodGroup!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                              ),
                              child: Text(
                                '🩸 Blood: ${user.bloodGroup}',
                                style: GoogleFonts.poppins(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.w600),
                              ),
                            ),
                          if (user?.guardianPhone != null && user!.guardianPhone!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.greenAccent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.5)),
                              ),
                              child: Text(
                                '👨‍👩‍👧 Guardian: ${user.guardianPhone}',
                                style: GoogleFonts.poppins(fontSize: 11, color: Colors.greenAccent, fontWeight: FontWeight.w600),
                              ),
                            ),
                          if (user?.policeStation != null && user!.policeStation!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.5)),
                              ),
                              child: Text(
                                '🚓 PS: ${user.policeStation}',
                                style: GoogleFonts.poppins(fontSize: 11, color: Colors.blueAccent, fontWeight: FontWeight.w600),
                              ),
                            ),
                          if (user?.postOffice != null && user!.postOffice!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.amberAccent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.5)),
                              ),
                              child: Text(
                                '📮 PO: ${user.postOffice}',
                                style: GoogleFonts.poppins(fontSize: 11, color: Colors.amberAccent, fontWeight: FontWeight.w600),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              }).animate().fadeIn(duration: 400.ms),

              const SizedBox(height: 28),

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
                            if (item.route != null) {
                              Get.toNamed(item.route!)?.then((_) => controller.loadUser());
                            } else if (item.label == 'App Lock & PIN Security') {
                              final appLock = AppLockService();
                              Get.bottomSheet(
                                StatefulBuilder(
                                  builder: (ctx, setModalState) {
                                    return Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                                      decoration: const BoxDecoration(
                                        color: AppColors.cardBg,
                                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                      ),
                                      child: SingleChildScrollView(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            Center(
                                              child: Container(
                                                width: 40,
                                                height: 4,
                                                decoration: BoxDecoration(
                                                  color: Colors.white24,
                                                  borderRadius: BorderRadius.circular(2),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            Row(
                                              children: [
                                                const Icon(Icons.security_rounded, color: AppColors.primary, size: 22),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    'App Lock & Privacy Security',
                                                    style: GoogleFonts.poppins(
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 20),
                                                  onPressed: () => Get.back(),
                                                  visualDensity: VisualDensity.compact,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                                              ),
                                              child: Text(
                                                'Lock Raksha+ to prevent unauthorized access to your live tracking, emergency contacts, and recorded audio evidence.',
                                                style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 12),
                                              ),
                                            ),
                                            const SizedBox(height: 16),

                                            // 1. Device Screen Lock Toggle (Fingerprint / Device PIN)
                                            SwitchListTile(
                                              contentPadding: EdgeInsets.zero,
                                              title: Text(
                                                'Use Phone Device Lock',
                                                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                                              ),
                                              subtitle: Text(
                                                'Unlock using phone PIN, pattern, or fingerprint',
                                                style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 12),
                                              ),
                                              value: appLock.useDeviceLock,
                                              activeColor: AppColors.primary,
                                              onChanged: (val) async {
                                                if (val) {
                                                  final didAuth = await appLock.authenticateWithDeviceLock();
                                                  if (didAuth) {
                                                    await appLock.setUseDeviceLock(true);
                                                    setModalState(() {});
                                                  }
                                                } else {
                                                  await appLock.setUseDeviceLock(false);
                                                  setModalState(() {});
                                                }
                                              },
                                            ),

                                            const Divider(color: Colors.white12),

                                            // 2. Custom 4-Digit Security PIN
                                            ListTile(
                                              contentPadding: EdgeInsets.zero,
                                              title: Text(
                                                'Raksha 4-Digit PIN',
                                                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                                              ),
                                              subtitle: Text(
                                                appLock.hasPin ? 'PIN is configured & active' : 'No 4-digit PIN set yet',
                                                style: GoogleFonts.poppins(
                                                  color: appLock.hasPin ? Colors.greenAccent : AppColors.textSecondary,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              trailing: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppColors.primary,
                                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                ),
                                                onPressed: () {
                                                  Get.back();
                                                  appLock.showSetPinDialog(context);
                                                },
                                                child: Text(
                                                  appLock.hasPin ? 'Change PIN' : 'Set PIN',
                                                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ),

                                            if (appLock.isLockEnabled) ...[
                                              const SizedBox(height: 12),
                                              OutlinedButton(
                                                style: OutlinedButton.styleFrom(
                                                  side: const BorderSide(color: Colors.redAccent),
                                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                ),
                                                onPressed: () async {
                                                  await appLock.disableAllLocks();
                                                  Get.back();
                                                  Get.snackbar(
                                                    'App Lock Disabled',
                                                    'All app locks have been removed.',
                                                    backgroundColor: AppColors.cardBg,
                                                    colorText: Colors.white,
                                                  );
                                                },
                                                child: Text(
                                                  'Disable All App Locks',
                                                  style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w600),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                isScrollControlled: true,
                              );
                            } else if (item.label == 'Help & Support') {
                              Get.defaultDialog(
                                title: 'Emergency Support',
                                titleStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
                                backgroundColor: AppColors.cardBg,
                                middleText: 'National Emergency Helpline: 112\nWomen Safety Helpline: 1091',
                                middleTextStyle: GoogleFonts.poppins(color: AppColors.textSecondary),
                                textConfirm: 'Close',
                                confirmTextColor: Colors.white,
                                buttonColor: AppColors.primary,
                                onConfirm: () => Get.back(),
                              );
                            } else if (item.label == 'About Raksha+') {
                              Get.defaultDialog(
                                title: 'About Raksha+',
                                titleStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
                                backgroundColor: AppColors.cardBg,
                                middleText: 'Raksha+ v1.0.0\nAI-Powered Women Safety & Real-Time Emergency Network.\nSafer Steps. Brighter Tomorrows.',
                                middleTextStyle: GoogleFonts.poppins(color: AppColors.textSecondary),
                                textConfirm: 'OK',
                                confirmTextColor: Colors.white,
                                buttonColor: AppColors.primary,
                                onConfirm: () => Get.back(),
                              );
                            }
                          },
                          leading: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(item.icon, color: AppColors.primary, size: 20),
                          ),
                          title: Text(item.label, style: GoogleFonts.poppins(fontSize: 14, color: Colors.white)),
                          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
                        ),
                        if (i < settingsItems.length - 1)
                          const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.divider),
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
                label: const Text('Logout', style: TextStyle(color: AppColors.error)),
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
