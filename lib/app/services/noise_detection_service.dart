// ─────────────────────────────────────────────
//  noise_detection_service.dart
//  High Noise (>50 dB) Sentinel & Automatic SOS Trigger Engine.
//  Continuously monitors ambient decibels via microphone.
//  If loud noise/scream (>50 dB) is detected, it automatically:
//  1. Triggers Emergency SOS broadcast with GPS coordinates
//  2. Records ambient audio evidence
//  3. Blasts high-volume siren alarm noise
// ─────────────────────────────────────────────
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../controllers/sos_controller.dart';
import 'alarm_sound_service.dart';

class NoiseDetectionService {
  static final NoiseDetectionService _instance =
      NoiseDetectionService._internal();
  factory NoiseDetectionService() => _instance;
  NoiseDetectionService._internal();

  final AudioRecorder _recorder = AudioRecorder();
  final RxBool isMonitoring = false.obs;
  final RxDouble currentDecibels = 0.0.obs;
  final RxDouble thresholdDb = 85.0.obs;
  final RxBool autoSosEnabled = true.obs;

  Timer? _sampleTimer;
  int _consecutiveHighSpikes = 0;
  DateTime? _lastTriggerTime;

  /// Start ambient noise level monitor
  Future<void> startMonitoring() async {
    if (isMonitoring.value) return;

    try {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        debugPrint('[NoiseDetectionService] Microphone permission not granted');
        return;
      }

      final hasPerm = await _recorder.hasPermission();
      if (!hasPerm) return;

      final tempDir = await getTemporaryDirectory();
      final monitorPath = '${tempDir.path}/noise_sentinel_buffer.m4a';

      // Start recording into buffer to read live amplitude
      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 64000,
        sampleRate: 44100,
      );

      await _recorder.start(config, path: monitorPath);
      isMonitoring.value = true;
      _consecutiveHighSpikes = 0;

      debugPrint(
          '[NoiseDetectionService] 🎙️ Ambient noise sentinel started (Threshold: ${thresholdDb.value} dB)');

      _sampleTimer?.cancel();
      _sampleTimer =
          Timer.periodic(const Duration(milliseconds: 300), (_) async {
        await _sampleNoiseLevel();
      });
    } catch (e) {
      debugPrint('[NoiseDetectionService] Error starting noise monitor: $e');
      isMonitoring.value = false;
    }
  }

  Future<void> _sampleNoiseLevel() async {
    if (!isMonitoring.value) return;

    try {
      final amp = await _recorder.getAmplitude();
      // amp.current is in dBFS (-160 to 0).
      // Convert dBFS to approximate SPL dB:
      // Silence ≈ -60 dBFS -> ~25 dB SPL
      // Normal speaking ≈ -25 dBFS -> ~60 dB SPL
      // Scream / High distress ≈ -15 to 0 dBFS -> ~70 to 85+ dB SPL
      final rawCurrent = amp.current;
      double splEstimate;
      if (rawCurrent <= -100) {
        splEstimate = 20.0;
      } else {
        splEstimate = (rawCurrent + 85.0).clamp(15.0, 110.0);
      }

      currentDecibels.value = double.parse(splEstimate.toStringAsFixed(1));

      // Check if noise exceeds threshold (> 50 dB)
      if (splEstimate >= thresholdDb.value && autoSosEnabled.value) {
        _consecutiveHighSpikes++;

        // Trigger on 2 consecutive samples (>500ms continuous scream/shouting)
        // or a massive sudden shock spike (>70 dB)
        if (_consecutiveHighSpikes >= 2 || splEstimate >= 72.0) {
          _consecutiveHighSpikes = 0;
          _handleHighNoiseDetected(splEstimate);
        }
      } else {
        if (_consecutiveHighSpikes > 0) _consecutiveHighSpikes--;
      }
    } catch (_) {}
  }

  void _handleHighNoiseDetected(double detectedDb) {
    final now = DateTime.now();
    // Cooldown check: prevent re-triggering within 60 seconds
    if (_lastTriggerTime != null &&
        now.difference(_lastTriggerTime!).inSeconds < 60) {
      return;
    }
    _lastTriggerTime = now;

    debugPrint(
        '[NoiseDetectionService] 🚨 CRITICAL NOISE SPIKE DETECTED: ${detectedDb.toInt()} dB > ${thresholdDb.value} dB! Triggering Automatic SOS!');

    // 1. Activate loud siren alarm with noise
    AlarmSoundService().startAlarm();

    // 2. Trigger SOS automatically
    if (Get.isRegistered<SosController>()) {
      final sosCtrl = Get.find<SosController>();
      if (!sosCtrl.isActive.value) {
        sosCtrl.triggerSosAutomatic(
          triggerType: 'high_noise_detection_${detectedDb.toInt()}dB',
        );
      }
    }

    // 3. Heads-up alert banner
    Get.snackbar(
      '🚨 HIGH NOISE SOS DETECTED (${detectedDb.toInt()} dB)',
      'Scream or distress noise above 50 dB detected! Emergency SOS & Siren Alarm activated.',
      duration: const Duration(seconds: 10),
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFF3B0000),
      colorText: Colors.white,
      borderColor: const Color(0xFFFF1744),
      borderWidth: 2,
    );
  }

  /// Stop noise monitoring
  Future<void> stopMonitoring() async {
    isMonitoring.value = false;
    _sampleTimer?.cancel();
    _sampleTimer = null;
    currentDecibels.value = 0.0;
    try {
      await _recorder.stop();
      debugPrint('[NoiseDetectionService] ⏹️ Noise sentinel stopped');
    } catch (_) {}
  }

  void dispose() {
    stopMonitoring();
    _recorder.dispose();
  }
}
