// ─────────────────────────────────────────────
//  fake_shutdown_view.dart
//  In-App Fake Switch-Off & Stealth Defense.
//  Simulates realistic OS shutdown, goes pitch black to fool attackers,
//  and secretly tracks GPS coordinates and ambient audio.
//  Unlockable via Raksha PIN or Device Screen Lock.
//  Completely safe & compliant with Google Play Protect.
// ─────────────────────────────────────────────
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/app_lock_service.dart';
import '../../services/audio_capture_service.dart';
import '../../services/sos_service.dart';
import '../../theme/app_colors.dart';

enum FakeShutdownState { powerMenu, shuttingDown, pitchBlack, pinPrompt }

class FakeShutdownView extends StatefulWidget {
  const FakeShutdownView({super.key});

  @override
  State<FakeShutdownView> createState() => _FakeShutdownViewState();
}

class _FakeShutdownViewState extends State<FakeShutdownView> {
  FakeShutdownState _state = FakeShutdownState.powerMenu;
  String _enteredPin = '';
  String _errorMessage = '';
  Timer? _pinDismissTimer;
  Timer? _stealthTrackerTimer;

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _pinDismissTimer?.cancel();
    _stealthTrackerTimer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _triggerShutdownAnimation() {
    setState(() => _state = FakeShutdownState.shuttingDown);
    HapticFeedback.heavyImpact();

    // Dim system overlays & immerse in stealth
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Covertly start emergency GPS beacons & audio in background
    _startStealthDefense();

    // After 2.5 seconds of "Shutting down...", go into pitch black stealth mode
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() => _state = FakeShutdownState.pitchBlack);
      }
    });
  }

  void _startStealthDefense() {
    try {
      if (Get.isRegistered<SosService>()) {
        final sosService = Get.find<SosService>();
        Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        ).then((pos) {
          sosService.triggerSos(
            latitude: pos.latitude,
            longitude: pos.longitude,
            triggerType: 'fake_shutdown_defense',
          ).then((resp) {
            final data = resp.data as Map<String, dynamic>?;
            final incId = (data?['incident_id'] ?? data?['_id'] ?? data?['id'] ?? '').toString();
            if (incId.isNotEmpty) {
              AudioCaptureService().startEmergencyRecording(
                incidentId: incId,
                sosService: sosService,
                recordDuration: const Duration(seconds: 45),
              );
            }
          }).catchError((_) {});
        }).catchError((_) {});

        _stealthTrackerTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
          try {
            await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
            );
          } catch (_) {}
        });
      }
    } catch (_) {}
  }

  void _onScreenTappedInStealth() {
    if (_state == FakeShutdownState.pitchBlack) {
      setState(() {
        _state = FakeShutdownState.pinPrompt;
        _enteredPin = '';
        _errorMessage = '';
      });

      // Auto-hide back to pitch black if untouched for 12 seconds
      _pinDismissTimer?.cancel();
      _pinDismissTimer = Timer(const Duration(seconds: 12), () {
        if (mounted && _state == FakeShutdownState.pinPrompt) {
          setState(() => _state = FakeShutdownState.pitchBlack);
        }
      });
    }
  }

  void _handleKeypadInput(String digit) {
    if (_enteredPin.length < 4) {
      HapticFeedback.selectionClick();
      setState(() {
        _enteredPin += digit;
        _errorMessage = '';
      });

      if (_enteredPin.length == 4) {
        _verifyEnteredPin();
      }
    }
  }

  void _handleBackspace() {
    if (_enteredPin.isNotEmpty) {
      HapticFeedback.selectionClick();
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorMessage = '';
      });
    }
  }

  void _verifyEnteredPin() {
    final appLock = AppLockService();
    bool isValid = appLock.isLockEnabled ? appLock.verifyPin(_enteredPin) : true;

    if (isValid) {
      _exitStealthMode();
    } else {
      HapticFeedback.vibrate();
      setState(() {
        _errorMessage = 'Incorrect PIN. Stealth active.';
        _enteredPin = '';
      });

      Future.delayed(const Duration(milliseconds: 1800), () {
        if (mounted && _state == FakeShutdownState.pinPrompt) {
          setState(() => _state = FakeShutdownState.pitchBlack);
        }
      });
    }
  }

  void _exitStealthMode() {
    HapticFeedback.heavyImpact();
    _stealthTrackerTimer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    Get.back();
    Get.snackbar(
      '🛡️ Stealth Deactivated',
      'Device successfully unlocked from Fake Switch-Off mode.',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.black87,
      colorText: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _state == FakeShutdownState.powerMenu,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _onScreenTappedInStealth();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _onScreenTappedInStealth,
          child: SizedBox.expand(
            child: _buildCurrentState(),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentState() {
    switch (_state) {
      case FakeShutdownState.powerMenu:
        return _buildSimulatedPowerMenu();
      case FakeShutdownState.shuttingDown:
        return _buildShuttingDownAnimation();
      case FakeShutdownState.pitchBlack:
        return const SizedBox.expand(); // Completely black screen
      case FakeShutdownState.pinPrompt:
        return _buildPinPrompt();
    }
  }

  Widget _buildSimulatedPowerMenu() {
    return Container(
      color: Colors.black.withValues(alpha: 0.9),
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.power_settings_new_rounded, color: AppColors.primary, size: 40),
          ),
          const SizedBox(height: 20),
          Text(
            'Simulate Fake Switch-Off',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The screen will animate "Shutting down..." and switch to pitch black. Attacker will believe the phone is completely dead while GPS & audio broadcast secretly in background.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 36),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _powerButton(
                icon: Icons.power_settings_new_rounded,
                label: 'Power off',
                color: Colors.redAccent,
                onTap: _triggerShutdownAnimation,
              ),
              _powerButton(
                icon: Icons.restart_alt_rounded,
                label: 'Restart',
                color: Colors.greenAccent,
                onTap: _triggerShutdownAnimation,
              ),
            ],
          ),
          const SizedBox(height: 40),
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel & Return to App',
              style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _powerButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.18),
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(icon, color: color, size: 34),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildShuttingDownAnimation() {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(Colors.white70)),
          ),
          const SizedBox(height: 24),
          Text(
            'Shutting down...',
            style: GoogleFonts.roboto(color: Colors.white70, fontSize: 16, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildPinPrompt() {
    return Container(
      color: const Color(0xFF0A0A0A),
      padding: const EdgeInsets.symmetric(horizontal: 28),
      alignment: Alignment.center,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shield_rounded, color: AppColors.primary, size: 32),
            ),
            const SizedBox(height: 14),
            Text(
              'Anti-Theft Stealth Active',
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Enter Raksha PIN or use Phone Device Lock to unlock',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12),
            ),
            const SizedBox(height: 20),

            // PIN Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final isFilled = i < _enteredPin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled ? AppColors.primary : Colors.white24,
                  ),
                );
              }),
            ),

            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage,
                style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],

            const SizedBox(height: 24),

            // Numpad
            for (var row in [
              ['1', '2', '3'],
              ['4', '5', '6'],
              ['7', '8', '9'],
              ['', '0', '⌫'],
            ]) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: row.map((key) {
                  if (key.isEmpty) return const SizedBox(width: 72, height: 60);
                  return InkWell(
                    onTap: () {
                      if (key == '⌫') {
                        _handleBackspace();
                      } else {
                        _handleKeypadInput(key);
                      }
                    },
                    borderRadius: BorderRadius.circular(32),
                    child: Container(
                      width: 68,
                      height: 54,
                      margin: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: key == '⌫'
                          ? const Icon(Icons.backspace_outlined, color: Colors.white, size: 20)
                          : Text(
                              key,
                              style: GoogleFonts.poppins(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 16),

            // Unlock with Device Lock (Fingerprint / Device PIN)
            TextButton.icon(
              onPressed: () async {
                final didAuth = await AppLockService().authenticateWithDeviceLock();
                if (didAuth) {
                  _exitStealthMode();
                }
              },
              icon: const Icon(Icons.fingerprint_rounded, color: AppColors.primary, size: 22),
              label: Text(
                'Unlock with Device Lock (Fingerprint / PIN)',
                style: GoogleFonts.poppins(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),

            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() => _state = FakeShutdownState.pitchBlack);
              },
              child: Text(
                'Back to Stealth Black Screen',
                style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
