// ─────────────────────────────────────────────
//  fake_shutdown_view.dart
//  Hyper-realistic Fake Shutdown Screen & Stealth Lock.
//  Simulates authentic OS power down, switches screen to pitch black,
//  and requires Raksha Safety PIN to wake device.
// ─────────────────────────────────────────────
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/app_lock_service.dart';
import '../../services/fake_shutdown_service.dart';
import '../../theme/app_colors.dart';

enum ShutdownState { powerMenu, shuttingDown, pitchBlack, pinPrompt }

class FakeShutdownView extends StatefulWidget {
  const FakeShutdownView({super.key});

  @override
  State<FakeShutdownView> createState() => _FakeShutdownViewState();
}

class _FakeShutdownViewState extends State<FakeShutdownView> {
  ShutdownState _state = ShutdownState.powerMenu;
  final TextEditingController _pinController = TextEditingController();
  String _enteredPin = '';
  String _errorMessage = '';
  Timer? _pinDismissTimer;

  @override
  void initState() {
    super.initState();
    // Vibrate briefly on power menu appearance
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _pinDismissTimer?.cancel();
    _pinController.dispose();
    super.dispose();
  }

  void _triggerShutdownAnimation() {
    setState(() => _state = ShutdownState.shuttingDown);
    HapticFeedback.heavyImpact();

    // After 2.5 seconds of "Shutting down...", go into pitch black stealth mode
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() => _state = ShutdownState.pitchBlack);
      }
    });
  }

  void _onScreenTappedInStealth() {
    if (_state == ShutdownState.pitchBlack) {
      setState(() {
        _state = ShutdownState.pinPrompt;
        _enteredPin = '';
        _errorMessage = '';
      });

      // Auto-hide PIN prompt back to pitch black if unattended for 12 seconds
      _pinDismissTimer?.cancel();
      _pinDismissTimer = Timer(const Duration(seconds: 12), () {
        if (mounted && _state == ShutdownState.pinPrompt) {
          setState(() => _state = ShutdownState.pitchBlack);
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
    bool isValid = false;

    if (appLock.isLockEnabled) {
      isValid = appLock.verifyPin(_enteredPin);
    } else {
      // If user hasn't explicitly set a PIN, allow default emergency pin 1234 or any 4 digits
      isValid = true;
    }

    if (isValid) {
      HapticFeedback.heavyImpact();
      FakeShutdownService().exitFakeShutdown();
      Get.back();
      Get.snackbar(
        '🛡️ Protection Deactivated',
        'Device successfully unlocked from Fake Switch-Off mode.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.black87,
        colorText: Colors.white,
      );
    } else {
      HapticFeedback.vibrate();
      setState(() {
        _errorMessage = 'Incorrect PIN. Protection active.';
        _enteredPin = '';
      });

      // After 2 seconds of error, go back to pitch black
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted && _state == ShutdownState.pinPrompt) {
          setState(() => _state = ShutdownState.pitchBlack);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Intercept back button so attacker cannot press back to exit
    return PopScope(
      canPop: false,
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
          child: _buildCurrentStateView(),
        ),
      ),
    );
  }

  Widget _buildCurrentStateView() {
    switch (_state) {
      case ShutdownState.powerMenu:
        return _buildNativePowerMenu();
      case ShutdownState.shuttingDown:
        return _buildShuttingDownAnimation();
      case ShutdownState.pitchBlack:
        return const SizedBox.expand(); // Completely black screen
      case ShutdownState.pinPrompt:
        return _buildPinPrompt();
    }
  }

  // ── Realistic Power Menu ────────────────────────────────
  Widget _buildNativePowerMenu() {
    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Power Off Phone',
            style: GoogleFonts.roboto(
              fontSize: 16,
              color: Colors.white70,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 36),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Power off button
              GestureDetector(
                onTap: _triggerShutdownAnimation,
                child: Column(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.power_settings_new_rounded, color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Power off',
                      style: GoogleFonts.roboto(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 44),
              // Restart button
              GestureDetector(
                onTap: _triggerShutdownAnimation,
                child: Column(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Restart',
                      style: GoogleFonts.roboto(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          TextButton(
            onPressed: () {
              FakeShutdownService().exitFakeShutdown();
              Get.back();
            },
            child: Text(
              'Cancel',
              style: GoogleFonts.roboto(color: Colors.white60, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  // ── Realistic Shutdown Wheel ────────────────────────────
  Widget _buildShuttingDownAnimation() {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation(Colors.white70),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Shutting down...',
            style: GoogleFonts.roboto(
              color: Colors.white70,
              fontSize: 15,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Stealth PIN Keypad ──────────────────────────────────
  Widget _buildPinPrompt() {
    return Container(
      color: const Color(0xFF0A0A0A),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      alignment: Alignment.center,
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
          const SizedBox(height: 16),
          Text(
            'Anti-Theft Protection Active',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Enter Raksha PIN to unlock phone screen',
            style: GoogleFonts.poppins(
              color: Colors.white60,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),

          // 4-dot PIN indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final isFilled = i < _enteredPin.length;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFilled ? AppColors.primary : Colors.white24,
                ),
              );
            }),
          ),

          if (_errorMessage.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              _errorMessage,
              style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],

          const SizedBox(height: 32),

          // Numeric Keypad
          _buildKeypad(),

          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              setState(() => _state = ShutdownState.pitchBlack);
            },
            child: Text(
              'Back to Stealth Mode',
              style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeypad() {
    const keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'DEL'],
    ];

    return Column(
      children: keys.map((row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((key) {
              if (key.isEmpty) {
                return const SizedBox(width: 72, height: 72);
              }
              if (key == 'DEL') {
                return SizedBox(
                  width: 72,
                  height: 72,
                  child: IconButton(
                    icon: const Icon(Icons.backspace_outlined, color: Colors.white70),
                    onPressed: _handleBackspace,
                  ),
                );
              }
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(32),
                  onTap: () => _handleKeypadInput(key),
                  child: Center(
                    child: Text(
                      key,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}
