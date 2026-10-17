// ─────────────────────────────────────────────
//  guardian_scanner_view.dart
//  Camera QR code scanner with manual ID/Email fallback.
//  Scans another Raksha+ user's QR code to open
//  the live Guardian Tracking & Audio screen.
// ─────────────────────────────────────────────

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';

class GuardianScannerView extends StatefulWidget {
  const GuardianScannerView({super.key});

  @override
  State<GuardianScannerView> createState() => _GuardianScannerViewState();
}

class _GuardianScannerViewState extends State<GuardianScannerView> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isProcessing = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    _navigateToTrack(rawValue);
  }

  void _navigateToTrack(String rawValue) {
    if (_isProcessing) return;
    _isProcessing = true;

    String targetId = rawValue.trim();
    String targetName = 'Tracked User';
    String targetPhone = '';

    try {
      final decoded = jsonDecode(rawValue) as Map<String, dynamic>;
      if (decoded['user_id'] != null) {
        targetId = decoded['user_id'].toString();
      } else if (decoded['email'] != null) {
        targetId = decoded['email'].toString();
      }
      if (decoded['name'] != null) {
        targetName = decoded['name'].toString();
      }
      if (decoded['phone'] != null) {
        targetPhone = decoded['phone'].toString();
      }
    } catch (_) {
      targetId = rawValue.trim();
    }

    try {
      _scannerController.stop();
    } catch (_) {}

    Get.offNamed(
      AppRoutes.guardianTrack,
      arguments: {
        'targetId': targetId,
        'name': targetName,
        'phone': targetPhone,
      },
    );
  }

  void _showManualEntryDialog() {
    final textCtrl = TextEditingController();
    Get.defaultDialog(
      title: 'Enter Guardian ID / Email',
      titleStyle: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
      backgroundColor: AppColors.cardBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      content: Column(
        children: [
          Text(
            'Paste the Guardian User ID, Registered Email, or Phone number of the person you want to track.',
            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: textCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Guardian ID or user email',
              hintStyle: const TextStyle(color: AppColors.textHint),
              prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.primary),
              filled: true,
              fillColor: AppColors.scaffoldBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
      textConfirm: 'Start Tracking',
      confirmTextColor: Colors.white,
      buttonColor: AppColors.primary,
      onConfirm: () {
        final val = textCtrl.text.trim();
        if (val.isNotEmpty) {
          Get.back();
          _navigateToTrack(val);
        }
      },
      textCancel: 'Cancel',
      cancelTextColor: AppColors.textHint,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Scan Guardian QR'),
        actions: [
          IconButton(
            tooltip: 'Enter Manually',
            icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
            onPressed: _showManualEntryDialog,
          ),
          IconButton(
            tooltip: 'Torch',
            icon: const Icon(Icons.flash_on_rounded),
            onPressed: () => _scannerController.toggleTorch(),
          ),
          IconButton(
            tooltip: 'Switch Camera',
            icon: const Icon(Icons.cameraswitch_rounded),
            onPressed: () => _scannerController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Camera Scanner ─────────────────────────
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),

          // ── Visual Scanner Overlay Box ─────────────
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 3),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),

          // ── Instructional Guide & Manual Button ────
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.qr_code_2_rounded, color: AppColors.primary, size: 26),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Align the Raksha+ Guardian QR code inside the frame.',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: _showManualEntryDialog,
                  icon: const Icon(Icons.keyboard_alt_outlined, color: AppColors.primary),
                  label: Text(
                    'Cannot scan? Enter Guardian ID manually',
                    style: GoogleFonts.poppins(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
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
