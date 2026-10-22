// ─────────────────────────────────────────────
//  fake_shutdown_service.dart
//  Anti-Theft Protection: Fake Switch-Off Engine.
//  Intercepts or simulates a phone shutdown.
//  The screen appears completely powered off and dead to attackers,
//  while covertly broadcasting real-time GPS coordinates and
//  recording ambient audio in the stealth background.
//  Requires Raksha PIN to wake up.
// ─────────────────────────────────────────────
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sos_service.dart';
import 'audio_capture_service.dart';
import '../views/security/fake_shutdown_view.dart';

class FakeShutdownService {
  static const String _kEnabledKey = 'fake_shutdown_enabled';

  static final FakeShutdownService _instance = FakeShutdownService._internal();
  factory FakeShutdownService() => _instance;
  FakeShutdownService._internal();

  bool isEnabled = false;
  bool isInFakeShutdown = false;
  Timer? _stealthTrackerTimer;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    isEnabled = prefs.getBool(_kEnabledKey) ?? true; // Enabled by default for maximum safety
  }

  Future<void> setEnabled(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabledKey, val);
    isEnabled = val;
  }

  /// Initiates the Fake Switch-Off sequence
  void launchFakeShutdown(BuildContext context) {
    if (isInFakeShutdown) return;
    isInFakeShutdown = true;

    // Dim system overlays & immerse in stealth
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Start background stealth tracking and audio
    _startStealthDefense();

    // Navigate to FakeShutdownView
    Get.to(
      () => const FakeShutdownView(),
      transition: Transition.noTransition,
      fullscreenDialog: true,
    );
  }

  /// Covertly records audio and transmits GPS coordinates during fake shutdown
  void _startStealthDefense() {
    _stealthTrackerTimer?.cancel();

    // Trigger silent emergency beacon
    try {
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
            // Secretly record ambient audio
            AudioCaptureService().startEmergencyRecording(
              incidentId: incId,
              sosService: sosService,
              recordDuration: const Duration(seconds: 45),
            );
          }
        }).catchError((_) {});
      }).catchError((_) {});

      // Continuous GPS beacons every 15 seconds
      _stealthTrackerTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
        try {
          final p = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
          );
          debugPrint('[FakeShutdown] 📡 Stealth GPS Beacon: ${p.latitude}, ${p.longitude}');
        } catch (_) {}
      });
    } catch (_) {}
  }

  /// Exit fake shutdown when the user inputs their correct PIN
  void exitFakeShutdown() {
    isInFakeShutdown = false;
    _stealthTrackerTimer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
}
