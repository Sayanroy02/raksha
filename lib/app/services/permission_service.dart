// ─────────────────────────────────────────────
//  permission_service.dart
//  Handles runtime permission requests for:
//  • Location (Fine GPS & Background)
//  • Camera (Evidence & QR Scanner)
//  • Microphone (Audio evidence & threat detection)
// ─────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_colors.dart';

class PermissionService extends GetxService {
  static const String _kAskedOnceKey = 'safety_permissions_asked_once';

  /// Check if the initial safety permission dialog has already been shown once
  Future<bool> hasPromptedOnce() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kAskedOnceKey) ?? false;
  }

  /// Mark that permissions have been prompted once so user is not prompted on every launch
  Future<void> markPromptedOnce() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAskedOnceKey, true);
  }

  /// Check if all critical permissions are granted
  Future<bool> hasAllCriticalPermissions() async {
    final loc = await Permission.location.isGranted;
    final cam = await Permission.camera.isGranted;
    final mic = await Permission.microphone.isGranted;
    return loc && cam && mic;
  }

  /// Request all essential safety permissions sequentially or via UI prompt
  Future<void> requestAllSafetyPermissions({bool showDialogFirst = true}) async {
    if (showDialogFirst) {
      final shouldProceed = await showPermissionExplanationDialog();
      if (!shouldProceed) return;
    }

    // 1. Location
    final locStatus = await Permission.location.request();
    if (locStatus.isGranted) {
      // Try requesting background location if supported
      await Permission.locationAlways.request();
    }

    // 2. Camera
    await Permission.camera.request();

    // 3. Microphone
    await Permission.microphone.request();
  }

  /// Show a modern dark dialog explaining why Raksha+ needs these permissions
  Future<bool> showPermissionExplanationDialog() async {
    final result = await Get.dialog<bool>(
      Dialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.security_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Safety Permissions',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Raksha+ requires the following permissions to protect you in emergency situations:',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),

              _permRow(
                icon: Icons.location_on_rounded,
                title: 'Live GPS Location',
                subtitle: 'Pinpoints your exact coordinates for SOS and live tracking.',
              ),
              const SizedBox(height: 12),
              _permRow(
                icon: Icons.camera_alt_rounded,
                title: 'Camera & QR Scanner',
                subtitle: 'Used for photo/video evidence and Guardian QR code scanning.',
              ),
              const SizedBox(height: 12),
              _permRow(
                icon: Icons.mic_rounded,
                title: 'Microphone & Audio',
                subtitle: 'Enables audio evidence recording and scream/stress detection.',
              ),

              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(result: false),
                      child: Text(
                        'Not Now',
                        style: GoogleFonts.poppins(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Get.back(result: true),
                      child: Text(
                        'Grant All',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return result ?? false;
  }

  static Widget _permRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
