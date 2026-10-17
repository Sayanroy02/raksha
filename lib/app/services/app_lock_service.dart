// ─────────────────────────────────────────────
//  app_lock_service.dart
//  Device-level security lock (4-Digit PIN Lock)
//  Protects user privacy, emergency contacts & evidence vault.
// ─────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_colors.dart';

class AppLockService {
  static const String _kLockEnabledKey = 'app_lock_enabled';
  static const String _kLockPinKey = 'app_lock_pin_code';

  static final AppLockService _instance = AppLockService._internal();
  factory AppLockService() => _instance;
  AppLockService._internal();

  bool isLockEnabled = false;
  String _savedPin = '';
  bool isUnlockedForSession = false;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    isLockEnabled = prefs.getBool(_kLockEnabledKey) ?? false;
    _savedPin = prefs.getString(_kLockPinKey) ?? '';
  }

  Future<bool> setPin(String pin) async {
    if (pin.length != 4) return false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLockEnabledKey, true);
    await prefs.setString(_kLockPinKey, pin);
    isLockEnabled = true;
    _savedPin = pin;
    isUnlockedForSession = true;
    return true;
  }

  Future<void> removePin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLockEnabledKey, false);
    await prefs.remove(_kLockPinKey);
    isLockEnabled = false;
    _savedPin = '';
    isUnlockedForSession = true;
  }

  bool verifyPin(String pin) {
    if (pin == _savedPin) {
      isUnlockedForSession = true;
      return true;
    }
    return false;
  }

  /// Suggests setting up App Lock right after login
  void promptAppLockSetupIfNeeded(BuildContext context) {
    if (isLockEnabled) return;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
        decoration: const BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: AppColors.primary, width: 2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
              child: const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              'Enhance Your Safety: Add App Lock',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Set a 4-digit PIN code so only you can access your live location, evidence vault recordings, and emergency contacts.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.divider),
                    ),
                    child: Text(
                      'Maybe Later',
                      style: GoogleFonts.poppins(color: AppColors.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back();
                      showSetPinDialog(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Set PIN Now',
                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      isDismissible: true,
    );
  }

  /// Opens the 4-digit PIN Setup Dialog
  void showSetPinDialog(BuildContext context) {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();
    final errorText = ''.obs;
    final step = 1.obs; // 1 = enter pin, 2 = confirm pin
    String firstPin = '';

    Get.dialog(
      Dialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Obx(
            () => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.pin_rounded, color: AppColors.primary, size: 40),
                const SizedBox(height: 12),
                Text(
                  step.value == 1 ? 'Create 4-Digit PIN' : 'Confirm Your PIN',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  step.value == 1
                      ? 'Enter a 4-digit security code'
                      : 'Re-enter your 4-digit security code to verify',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: step.value == 1 ? pinController : confirmController,
                  autofocus: true,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    color: Colors.white,
                    letterSpacing: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    counterText: '',
                    hintText: '••••',
                    hintStyle: TextStyle(letterSpacing: 16, color: Colors.white24),
                  ),
                ),
                if (errorText.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    errorText.value,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      onPressed: () async {
                        if (step.value == 1) {
                          if (pinController.text.length != 4) {
                            errorText.value = 'PIN must be 4 digits';
                            return;
                          }
                          firstPin = pinController.text;
                          errorText.value = '';
                          step.value = 2;
                        } else {
                          if (confirmController.text != firstPin) {
                            errorText.value = 'PINs do not match. Try again.';
                            return;
                          }
                          await setPin(firstPin);
                          Get.back();
                          Get.snackbar(
                            'App Lock Enabled',
                            'Your app is now protected with your 4-digit PIN.',
                            backgroundColor: AppColors.cardBg,
                            colorText: Colors.white,
                            icon: const Icon(Icons.check_circle_rounded, color: Colors.greenAccent),
                          );
                        }
                      },
                      child: Text(step.value == 1 ? 'Next' : 'Save PIN'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Screen shown to unlock the app when lock is active
  void showUnlockBarrier(BuildContext context, VoidCallback onUnlocked) {
    if (!isLockEnabled || isUnlockedForSession) {
      onUnlocked();
      return;
    }

    final pinCtrl = TextEditingController();
    final errorMsg = ''.obs;

    Get.dialog(
      PopScope(
        canPop: false, // Prevent bypassing lock
        child: Dialog.fullscreen(
          backgroundColor: AppColors.scaffoldBg,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.15),
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: const Icon(Icons.shield_rounded, color: AppColors.primary, size: 36),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Raksha+ Protected',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your 4-digit PIN to open the app',
                    style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: 180,
                    child: TextField(
                      controller: pinCtrl,
                      autofocus: true,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 32,
                        color: Colors.white,
                        letterSpacing: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      onChanged: (val) {
                        if (val.length == 4) {
                          if (verifyPin(val)) {
                            Get.back();
                            onUnlocked();
                          } else {
                            errorMsg.value = 'Incorrect PIN. Try again.';
                            pinCtrl.clear();
                          }
                        }
                      },
                      decoration: const InputDecoration(
                        counterText: '',
                        hintText: '••••',
                        hintStyle: TextStyle(letterSpacing: 18, color: Colors.white24),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Obx(
                    () => errorMsg.isNotEmpty
                        ? Text(
                            errorMsg.value,
                            style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }
}
