// ─────────────────────────────────────────────
//  home_view.dart
//  Main home screen matching the UI design:
// ─────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/sos_controller.dart';
import '../../routes/app_routes.dart';
import '../../services/permission_service.dart';
import '../../services/alarm_sound_service.dart';
import '../../services/noise_detection_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/constants.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/feature_card.dart';
import '../../widgets/sos_button.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final NoiseDetectionService _noiseService = NoiseDetectionService();
  final AlarmSoundService _alarmService = AlarmSoundService();

  @override
  void initState() {
    super.initState();
    _alarmService.init();
    _noiseService.startMonitoring();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (Get.isRegistered<PermissionService>()) {
        final perm = Get.find<PermissionService>();
        final alreadyAsked = await perm.hasPromptedOnce();
        if (!alreadyAsked) {
          await perm.markPromptedOnce();
          final hasAll = await perm.hasAllCriticalPermissions();
          if (!hasAll) {
            await perm.requestAllSafetyPermissions(showDialogFirst: true);
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final sos = Get.find<SosController>();

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
                        const TextSpan(
                            text: '👋', style: TextStyle(fontSize: 22)),
                      ]),
                    );
                  }),
                  // Notification bell
                  GestureDetector(
                    onTap: () => Get.toNamed(AppRoutes.notifications),
                    child: Container(
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
                  'Hold for ${AppConstants.sosHoldDuration} seconds to alert your\ntrusted contacts and share location.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ).animate(delay: 300.ms).fadeIn(),

              // ── Quick SOS Google Maps Nearest Emergency Bar ──
              Obx(() {
                if (!sos.isActive.value) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.emergency_rounded,
                              color: Colors.redAccent, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'EMERGENCY LIVE · Navigation Support',
                            style: GoogleFonts.poppins(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  sos.openNearestInGoogleMaps('police'),
                              icon: const Icon(Icons.local_police_rounded,
                                  size: 18, color: Colors.white),
                              label: const Text('Nearest Police',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E88E5),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  sos.openNearestInGoogleMaps('hospital'),
                              icon: const Icon(Icons.local_hospital_rounded,
                                  size: 18, color: Colors.white),
                              label: const Text('Nearest Hospital',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE53935),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn();
              }),

              // ── Active Siren Alarm Bar ──
              Obx(() {
                if (!sos.isActive.value) return const SizedBox.shrink();
                final isAlarm = _alarmService.isAlarmPlaying.value;
                return Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isAlarm ? const Color(0xFF5A0000) : AppColors.cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.redAccent, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Icon(
                          isAlarm
                              ? Icons.warning_rounded
                              : Icons.volume_off_rounded,
                          color: Colors.white,
                          size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAlarm
                                  ? '🚨 LOUD ALARM BLARING'
                                  : '🔇 Alarm Siren Muted',
                              style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13),
                            ),
                            Text(
                              isAlarm
                                  ? 'Emergency siren & ambient audio recording active'
                                  : 'Audio recording continues in background',
                              style: GoogleFonts.poppins(
                                  color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (isAlarm) {
                            _alarmService.stopAlarm();
                          } else {
                            _alarmService.startAlarm();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isAlarm ? Colors.black87 : Colors.redAccent,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(
                          isAlarm ? 'Mute' : 'Play Siren',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // ── Ambient Noise Sentinel (>50 dB Auto-SOS) ──
              Container(
                margin: const EdgeInsets.only(top: 20, bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color:
                                    Colors.orangeAccent.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.mic_rounded,
                                  color: Colors.orangeAccent, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'High Noise(>85 dB)',
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 14),
                                ),
                                Text(
                                  'Auto-triggers SOS & Siren if noise > 85 dB',
                                  style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Obx(() => Switch(
                              value: _noiseService.autoSosEnabled.value,
                              onChanged: (val) {
                                _noiseService.autoSosEnabled.value = val;
                                if (val && !_noiseService.isMonitoring.value) {
                                  _noiseService.startMonitoring();
                                }
                              },
                              activeColor: Colors.orangeAccent,
                            )),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Obx(() {
                      final db = _noiseService.currentDecibels.value;
                      final isHigh = db >= 85.0;
                      return Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: (db / 100.0).clamp(0.0, 1.0),
                                minHeight: 10,
                                backgroundColor: Colors.white10,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isHigh
                                      ? Colors.redAccent
                                      : (db > 38
                                          ? Colors.amberAccent
                                          : Colors.greenAccent),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isHigh
                                  ? Colors.redAccent.withValues(alpha: 0.2)
                                  : Colors.white10,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: isHigh
                                      ? Colors.redAccent
                                      : Colors.white24),
                            ),
                            child: Text(
                              '${db.toInt()} dB ${isHigh ? "⚠️ LOUD" : "• Normal"}',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color:
                                    isHigh ? Colors.redAccent : Colors.white70,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () {
                              _noiseService.thresholdDb.value = 85.0;
                              sos.triggerSosAutomatic(
                                  triggerType: 'high_noise_test_85dB');
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.redAccent),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text('Test >85dB',
                                style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),

              // // ── Fake Switch (Stealth Power-Off) Card ──
              // Container(
              //   margin: const EdgeInsets.only(bottom: 20),
              //   padding: const EdgeInsets.all(16),
              //   decoration: BoxDecoration(
              //     gradient: LinearGradient(
              //       colors: [
              //         const Color(0xFF261026),
              //         AppColors.cardBg,
              //       ],
              //       begin: Alignment.topLeft,
              //       end: Alignment.bottomRight,
              //     ),
              //     borderRadius: BorderRadius.circular(18),
              //     border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.35)),
              //   ),
              //   child: Row(
              //     children: [
              //       Container(
              //         padding: const EdgeInsets.all(12),
              //         decoration: BoxDecoration(
              //           color: Colors.purpleAccent.withValues(alpha: 0.2),
              //           shape: BoxShape.circle,
              //           border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.5)),
              //         ),
              //         child: const Icon(Icons.power_settings_new_rounded, color: Colors.purpleAccent, size: 26),
              //       ),
              //       const SizedBox(width: 14),
              //       Expanded(
              //         child: Column(
              //           crossAxisAlignment: CrossAxisAlignment.start,
              //           children: [
              //             Row(
              //               children: [
              //                 Text(
              //                   'Fake Switch',
              //                   style: GoogleFonts.poppins(
              //                     fontSize: 14,
              //                     fontWeight: FontWeight.bold,
              //                     color: Colors.white,
              //                   ),
              //                 ),
              //                 const SizedBox(width: 6),
              //                 Container(
              //                   padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              //                   decoration: BoxDecoration(
              //                     color: Colors.purpleAccent.withValues(alpha: 0.2),
              //                     borderRadius: BorderRadius.circular(6),
              //                   ),
              //                   child: Text('STEALTH', style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.purpleAccent)),
              //                 ),
              //               ],
              //             ),
              //             const SizedBox(height: 2),
              //             Text(
              //               'Simulate OS shutdown & pitch black screen while covertly tracking GPS and recording audio.',
              //               style: GoogleFonts.poppins(
              //                 fontSize: 11,
              //                 color: AppColors.textSecondary,
              //                 height: 1.3,
              //               ),
              //             ),
              //           ],
              //         ),
              //       ),
              //       const SizedBox(width: 8),
              //       ElevatedButton(
              //         onPressed: () => Get.toNamed(AppRoutes.fakeShutdown),
              //         style: ElevatedButton.styleFrom(
              //           backgroundColor: Colors.purpleAccent.shade700,
              //           padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              //           minimumSize: Size.zero,
              //           tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              //           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              //         ),
              //         child: Text('Fake Switch', style: GoogleFonts.poppins(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
              //       ),
              //     ],
              //   ),
              // ),

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
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.qr_code_2_rounded,
                          color: Colors.white, size: 26),
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text('My QR',
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(height: 6),
                        OutlinedButton(
                          onPressed: () =>
                              Get.toNamed(AppRoutes.guardianScanner),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: AppColors.divider),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text('Scan QR',
                              style: GoogleFonts.poppins(
                                  fontSize: 11, color: Colors.white70)),
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
