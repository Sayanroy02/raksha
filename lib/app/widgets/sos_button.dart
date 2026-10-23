// ─────────────────────────────────────────────
//  sos_button.dart
//  The centrepiece SOS button:
//  • Glowing pink circle with "SOS" text
//  • User holds it for 2 seconds to trigger
//  • Animated fill ring shows hold progress
//  • Pulsing glow when SOS is active (live)
// ─────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../controllers/sos_controller.dart';
import '../theme/app_colors.dart';

class SosButton extends StatelessWidget {
  final SosController controller;
  const SosButton({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isActive  = controller.isActive.value;
      final progress  = controller.holdProgress.value / 100.0;

      return GestureDetector(
        onLongPressStart: (_) => controller.onHoldStart(),
        onLongPressEnd:   (_) => controller.onHoldCancel(),
        onLongPressCancel:    () => controller.onHoldCancel(),
        child: SizedBox(
          width: 180,
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [

              // ── Outer glow ring (always visible) ─
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.25),
                    width: 2,
                  ),
                ),
              ),

              // ── Progress arc fill during hold ────
              if (progress > 0)
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 5,
                    backgroundColor: AppColors.divider,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),

              // ── Main SOS circle ──────────────────
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isActive
                        ? [AppColors.primaryDark, AppColors.primary]
                        : [AppColors.primary, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary
                          .withOpacity(isActive ? 0.8 : 0.5),
                      blurRadius: isActive ? 40 : 25,
                      spreadRadius: isActive ? 10 : 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'SOS',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 3,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    if (isActive)
                      Text(
                        controller.elapsedTime.value,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              )
                  // Pulsing animation when SOS is active
                  .animate(
                      onPlay: (a) => isActive ? a.repeat() : null,
                      target: isActive ? 1 : 0)
                  .scale(
                    begin: const Offset(1.0, 1.0),
                    end: const Offset(1.06, 1.06),
                    duration: 800.ms,
                    curve: Curves.easeInOut,
                  ),

              // ── "Stop" label when active ─────────
              if (isActive)
                Positioned(
                  bottom: 0,
                  child: GestureDetector(
                    onTap: controller.stopSos,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary),
                      ),
                      child: const Text(
                        'Stop Sharing',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}
