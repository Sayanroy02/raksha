// ─────────────────────────────────────────────
//  threat_detection_view.dart
//  AI Multi-Modal Threat Detection Screen.
//  Analyzes Audio decibels/voice recording, Visual patterns,
//  Location risk level via Geoapify, and Crowd behaviour.
// ─────────────────────────────────────────────
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/threat_controller.dart';
import '../../controllers/sos_controller.dart';
import '../../theme/app_colors.dart';

class ThreatDetectionView extends GetView<ThreatController> {
  const ThreatDetectionView({super.key});

  @override
  Widget build(BuildContext context) {
    final sos = Get.find<SosController>();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('AI Threat Detection'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        child: Column(
          children: [
            // ── Spinning radar + shield icon ─────
            Obx(() => GestureDetector(
                  onTap: controller.isScanning.value
                      ? controller.stopScan
                      : controller.startScan,
                  child: SizedBox(
                    height: 190,
                    width: 190,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer pulse ring
                        Container(
                          width: 190,
                          height: 190,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: controller.threatFound.value
                                  ? Colors.redAccent.withValues(alpha: 0.3)
                                  : AppColors.primary.withValues(alpha: 0.2),
                              width: 2,
                            ),
                          ),
                        ),
                        // Spinning radar arc
                        if (controller.isScanning.value)
                          Transform.rotate(
                            angle: controller.ringAngle.value * pi / 180,
                            child: SizedBox(
                              width: 150,
                              height: 150,
                              child: CircularProgressIndicator(
                                value: 0.75,
                                strokeWidth: 3,
                                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                valueColor: AlwaysStoppedAnimation(
                                  controller.threatFound.value ? Colors.redAccent : AppColors.primary,
                                ),
                                strokeCap: StrokeCap.round,
                              ),
                            ),
                          ),
                        // Center icon container
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.cardBg,
                            border: Border.all(
                              color: controller.threatFound.value
                                  ? Colors.redAccent
                                  : AppColors.primary.withValues(alpha: 0.4),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (controller.threatFound.value ? Colors.redAccent : AppColors.primary)
                                    .withValues(alpha: 0.25),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: Icon(
                            controller.isScanning.value
                                ? Icons.radar_rounded
                                : (controller.threatFound.value ? Icons.warning_rounded : Icons.shield_rounded),
                            size: 46,
                            color: controller.threatFound.value ? Colors.redAccent : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )),

            const SizedBox(height: 14),

            // Threat Status Badge
            Obx(() {
              final level = controller.threatLevelLabel.value;
              final isHigh = level == 'HIGH RISK';
              final isCaution = level == 'CAUTION';
              final badgeColor = isHigh
                  ? Colors.redAccent
                  : (isCaution ? Colors.orangeAccent : AppColors.liveGreen);

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: badgeColor),
                ),
                child: Text(
                  'STATUS: $level',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                    letterSpacing: 1,
                  ),
                ),
              );
            }),

            const SizedBox(height: 8),

            // Status description text
            Obx(() => Text(
                  controller.statusText.value,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                )),

            const SizedBox(height: 12),

            // Scan action button
            Obx(() => !controller.isScanning.value
                ? SizedBox(
                    height: 42,
                    child: ElevatedButton.icon(
                      onPressed: controller.startScan,
                      icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                      label: Text(
                        'Start Multi-Modal Scan',
                        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  )
                : const SizedBox.shrink()),

            const SizedBox(height: 24),

            // ── Detection checks cards ───────────
            ...List.generate(controller.checks.length, (i) {
              final check = controller.checks[i];
              return Obx(() => _CheckCard(
                    label: check.label,
                    description: check.description,
                    resultDetail: check.resultDetail.value,
                    status: check.status.value,
                    riskScore: check.riskScore.value,
                  ).animate(delay: Duration(milliseconds: i * 70)).fadeIn());
            }),

            const SizedBox(height: 20),

            // If elevated threat, show quick alert circle button
            Obx(() {
              if (controller.overallThreatScore.value <= 0.35) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B0000).withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.redAccent),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.yellowAccent, size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Elevated environmental risk detected!',
                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          sos.sendCustomEmailAlert(controller.locationAddress.value);
                          Get.snackbar('Alert Triggered', 'Safety circle notified of elevated threat.');
                        },
                        icon: const Icon(Icons.shield, color: Colors.white, size: 18),
                        label: const Text('Notify Safety Circle Now'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF0055),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Multi-modal card row ─────────────────────
class _CheckCard extends StatelessWidget {
  final String label;
  final String description;
  final String resultDetail;
  final CheckStatus status;
  final double riskScore;

  const _CheckCard({
    required this.label,
    required this.description,
    required this.resultDetail,
    required this.status,
    required this.riskScore,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (status) {
      CheckStatus.done => riskScore > 0.4
          ? (Icons.warning_rounded, Colors.redAccent)
          : (Icons.check_circle_rounded, AppColors.success),
      CheckStatus.scanning => (Icons.sync_rounded, AppColors.primary),
      CheckStatus.pending => (Icons.radio_button_off, AppColors.textHint),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          status == CheckStatus.scanning
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                )
              : Icon(icon, color: color, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.textHint,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.scaffoldBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    resultDetail,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: status == CheckStatus.done
                          ? (riskScore > 0.4 ? Colors.redAccent : AppColors.liveGreen)
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
