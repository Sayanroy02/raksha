// ─────────────────────────────────────────────
//  threat_detection_view.dart
//  AI Threat Detection screen — spinning ring,
//  four sequential detection checks with
//  animated status indicators.
// ─────────────────────────────────────────────
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/threat_controller.dart';
import '../../theme/app_colors.dart';

class ThreatDetectionView extends GetView<ThreatController> {
  const ThreatDetectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('AI Threat Detection'),
        actions: [
          IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () {}),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [

            // ── Spinning ring + shield icon ──────
            Obx(() => GestureDetector(
              onTap: controller.isScanning.value
                  ? controller.stopScan
                  : controller.startScan,
              child: SizedBox(
                height: 200,
                width: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer glow
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.15),
                          width: 2,
                        ),
                      ),
                    ),
                    // Spinning arc
                    if (controller.isScanning.value)
                      Transform.rotate(
                        angle: controller.ringAngle.value * pi / 180,
                        child: SizedBox(
                          width: 160,
                          height: 160,
                          child: CircularProgressIndicator(
                            value: 0.75,
                            strokeWidth: 3,
                            backgroundColor:
                                AppColors.primary.withOpacity(0.1),
                            valueColor: const AlwaysStoppedAnimation(
                                AppColors.primary),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                      ),
                    // Shield centre
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.cardBg,
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.2),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: Icon(
                        controller.isScanning.value
                            ? Icons.radar_rounded
                            : Icons.shield_rounded,
                        size: 48,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            )),

            const SizedBox(height: 16),

            // Status text
            Obx(() => Text(
              controller.statusText.value,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            )),

            const SizedBox(height: 8),

            // Tap hint when not scanning
            Obx(() => !controller.isScanning.value
                ? TextButton.icon(
                    onPressed: controller.startScan,
                    icon: const Icon(Icons.play_arrow_rounded,
                        color: AppColors.primary),
                    label: const Text('Tap to scan',
                        style: TextStyle(color: AppColors.primary)),
                  )
                : const SizedBox.shrink()),

            const SizedBox(height: 32),

            // ── Detection checks list ────────────
            ...List.generate(controller.checks.length, (i) {
              final check = controller.checks[i];
              return Obx(() => _CheckTile(
                    label:  check.label,
                    status: check.status.value ?? CheckStatus.pending,
                  ).animate(delay: Duration(milliseconds: i * 80)).fadeIn());
            }),

            const Spacer(),

            // Disclaimer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.warning, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Stay alert. Trust your instincts.\n'
                      "This feature helps, but it's not 100% accurate.",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.warning,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── Individual detection check row ──────────
class _CheckTile extends StatelessWidget {
  final String      label;
  final CheckStatus status;
  const _CheckTile({required this.label, required this.status});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (status) {
      CheckStatus.done    => (Icons.check_circle_rounded,  AppColors.success),
      CheckStatus.scanning=> (Icons.radio_button_on,        AppColors.primary),
      CheckStatus.pending => (Icons.radio_button_off,       AppColors.textHint),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          status == CheckStatus.scanning
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                )
              : Icon(icon, color: color, size: 22),
          const SizedBox(width: 14),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: status == CheckStatus.pending
                  ? AppColors.textHint
                  : AppColors.textPrimary,
              fontWeight: status == CheckStatus.done
                  ? FontWeight.w500
                  : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
