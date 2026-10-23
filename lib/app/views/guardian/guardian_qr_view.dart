// ─────────────────────────────────────────────
//  guardian_qr_view.dart
//  Displays the user's unique Raksha+ Guardian QR code.
//  Another Raksha+ user can scan this QR code to
//  instantly track this phone and listen to live audio.
// ─────────────────────────────────────────────

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../controllers/auth_controller.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../models/user_model.dart';
import '../../theme/app_colors.dart';

class GuardianQrView extends StatefulWidget {
  const GuardianQrView({super.key});

  @override
  State<GuardianQrView> createState() => _GuardianQrViewState();
}

class _GuardianQrViewState extends State<GuardianQrView> {
  final AuthController auth = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    _ensureUserLoaded();
  }

  Future<void> _ensureUserLoaded() async {
    if (auth.user.value == null || auth.user.value!.id.isEmpty) {
      try {
        final storage = Get.find<StorageService>();
        final jsonStr = await storage.getUserData();
        if (jsonStr != null) {
          auth.user.value = UserModel.fromJsonString(jsonStr);
        }
        final meResp = await Get.find<AuthService>().getMe();
        if (meResp.statusCode == 200 && meResp.data != null) {
          final u = UserModel.fromJson(meResp.data as Map<String, dynamic>);
          auth.user.value = u;
          await storage.saveUserData(u.toJsonString());
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('My Guardian QR'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Obx(() {
          final user = auth.user.value;
          final userId = (user?.id != null && user!.id.isNotEmpty)
              ? user.id
              : (user?.email != null && user!.email.isNotEmpty ? user.email : '');
          final userName = user?.name.isNotEmpty == true ? user!.name : 'Raksha+ User';
          final userPhone = user?.phone ?? '';
          final userEmail = user?.email ?? '';

          final qrPayload = jsonEncode({
            'app': 'raksha_plus',
            'type': 'guardian_track',
            'user_id': userId,
            'name': userName,
            'phone': userPhone,
            'email': userEmail,
          });

          return Column(
            children: [
              const SizedBox(height: 10),
              Text(
                'Pair Guardian Device',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Let a trusted family member or friend scan this QR code using their Raksha+ app to track your live GPS and listen to audio in an emergency.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),

              // ── QR Code Card ───────────────────────
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    QrImageView(
                      data: qrPayload,
                      version: QrVersions.auto,
                      size: 220.0,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Color(0xFF0D0D1A),
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Color(0xFF0D0D1A),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shield_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Raksha+ Verified Guardian ID',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0D0D1A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── User Information Badge ─────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'R',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            userPhone.isNotEmpty ? userPhone : (userEmail.isNotEmpty ? userEmail : 'Safety Profile Active'),
                            style: GoogleFonts.poppins(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, color: AppColors.primary, size: 20),
                      tooltip: 'Copy Guardian ID',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: userId));
                        Get.snackbar('Copied', 'Guardian ID copied to clipboard');
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Scanner shortcut button ────────────
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => Get.toNamed(AppRoutes.guardianScanner),
                  icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                  label: Text(
                    'Scan Someone Else\'s QR Code',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
