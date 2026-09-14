// ─────────────────────────────────────────────
//  guardian_scanner_view.dart
//  Camera QR code scanner.
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

    _isProcessing = true;

    String targetId = rawValue;
    String targetName = 'Tracked User';
    String targetPhone = '';

    try {
      final decoded = jsonDecode(rawValue) as Map<String, dynamic>;
      if (decoded['user_id'] != null) {
        targetId = decoded['user_id'].toString();
      }
      if (decoded['name'] != null) {
        targetName = decoded['name'].toString();
      }
      if (decoded['phone'] != null) {
        targetPhone = decoded['phone'].toString();
      }
    } catch (_) {
      // Raw string ID fallback
      targetId = rawValue.trim();
    }

    // Stop camera and navigate to tracking screen
    _scannerController.stop();
    Get.offNamed(
      AppRoutes.guardianTrack,
      arguments: {
        'targetId': targetId,
        'name': targetName,
        'phone': targetPhone,
      },
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
            icon: const Icon(Icons.flash_on_rounded),
            onPressed: () => _scannerController.toggleTorch(),
          ),
          IconButton(
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

          // ── Instructional Guide ────────────────────
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.cardBg.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  const Icon(Icons.qr_code_2_rounded, color: AppColors.primary, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Align the Raksha+ Guardian QR code within the frame to start live tracking & audio monitoring.',
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
          ),
        ],
      ),
    );
  }
}
