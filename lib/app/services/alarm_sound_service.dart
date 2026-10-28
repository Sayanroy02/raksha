// ─────────────────────────────────────────────
//  alarm_sound_service.dart
//  Loud Emergency Siren Alarm Engine.
//  Plays high-volume piercing alarm siren continuously
//  on SOS trigger or high noise (>50 dB) detection.
// ─────────────────────────────────────────────
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class AlarmSoundService {
  static final AlarmSoundService _instance = AlarmSoundService._internal();
  factory AlarmSoundService() => _instance;
  AlarmSoundService._internal();

  final AudioPlayer _player = AudioPlayer();
  final RxBool isAlarmPlaying = false.obs;
  Timer? _vibrationTimer;

  Future<void> init() async {
    _player.onPlayerStateChanged.listen((state) {
      isAlarmPlaying.value = (state == PlayerState.playing);
    });
  }

  /// Start playing loud siren alarm with continuous pulsing vibration
  Future<void> startAlarm() async {
    if (isAlarmPlaying.value) return;

    try {
      isAlarmPlaying.value = true;
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(1.0);
      await _player.play(AssetSource('sounds/emergency_siren.wav'));

      // Pulsing vibration
      _vibrationTimer?.cancel();
      _vibrationTimer = Timer.periodic(const Duration(milliseconds: 900), (_) {
        if (isAlarmPlaying.value) {
          HapticFeedback.heavyImpact();
        }
      });

      debugPrint('[AlarmSoundService] 🚨 Emergency siren alarm activated');
    } catch (e) {
      debugPrint('[AlarmSoundService] Error playing siren audio: $e');
      // If audio player fails, at least trigger continuous haptic vibration
      _vibrationTimer?.cancel();
      _vibrationTimer = Timer.periodic(const Duration(milliseconds: 700), (_) {
        HapticFeedback.heavyImpact();
      });
    }
  }

  /// Silence/Stop the emergency siren alarm
  Future<void> stopAlarm() async {
    isAlarmPlaying.value = false;
    _vibrationTimer?.cancel();
    _vibrationTimer = null;
    try {
      await _player.stop();
      debugPrint('[AlarmSoundService] 🔇 Emergency siren alarm stopped');
    } catch (e) {
      debugPrint('[AlarmSoundService] Error stopping siren: $e');
    }
  }

  void dispose() {
    stopAlarm();
    _player.dispose();
  }
}

