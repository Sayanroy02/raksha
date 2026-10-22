// ─────────────────────────────────────────────
//  audio_capture_service.dart
//  Captures real ambient microphone audio during SOS emergency trigger,
//  saves to local storage, and uploads directly to Raksha backend evidence.
// ─────────────────────────────────────────────
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import 'sos_service.dart';

class AudioCaptureService {
  static final AudioCaptureService _instance = AudioCaptureService._internal();
  factory AudioCaptureService() => _instance;
  AudioCaptureService._internal();

  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _currentRecordingPath;
  Timer? _autoStopTimer;

  bool get isRecording => _isRecording;

  /// Start recording emergency audio immediately upon SOS trigger.
  /// Automatically stops and uploads after [recordDuration] (default 20 seconds).
  Future<void> startEmergencyRecording({
    required String incidentId,
    required SosService sosService,
    Duration recordDuration = const Duration(seconds: 20),
  }) async {
    if (_isRecording) return;

    try {
      // 1. Ensure microphone permission
      final micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        debugPrint('[AudioCaptureService] Microphone permission not granted');
        return;
      }

      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        debugPrint('[AudioCaptureService] Recorder reports permission denied');
        return;
      }

      // 2. Prepare destination path
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${tempDir.path}/sos_ambient_$timestamp.m4a';

      // 3. Start recording
      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      );

      await _recorder.start(config, path: _currentRecordingPath!);
      _isRecording = true;
      debugPrint('[AudioCaptureService] 🎙️ Recording ambient audio to: $_currentRecordingPath');

      // 4. Set auto-stop timer to upload when done
      _autoStopTimer?.cancel();
      _autoStopTimer = Timer(recordDuration, () async {
        await stopAndUploadRecording(incidentId: incidentId, sosService: sosService);
      });
    } catch (e) {
      debugPrint('[AudioCaptureService] Error starting audio recording: $e');
      _isRecording = false;
    }
  }

  /// Stop the active recording and immediately upload to backend evidence
  Future<String?> stopAndUploadRecording({
    required String incidentId,
    required SosService sosService,
  }) async {
    _autoStopTimer?.cancel();
    if (!_isRecording) return null;

    try {
      final path = await _recorder.stop();
      _isRecording = false;
      final finalPath = path ?? _currentRecordingPath;

      if (finalPath != null && File(finalPath).existsSync()) {
        debugPrint('[AudioCaptureService] 📤 Uploading emergency audio evidence...');
        final resp = await sosService.uploadAudioFile(
          incidentId: incidentId,
          filePath: finalPath,
        );
        debugPrint('[AudioCaptureService] ✅ Audio evidence uploaded: ${resp.data}');
        return finalPath;
      }
    } catch (e) {
      debugPrint('[AudioCaptureService] Error stopping or uploading audio: $e');
    } finally {
      _isRecording = false;
    }
    return null;
  }

  /// Cancel current recording without upload
  Future<void> cancelRecording() async {
    _autoStopTimer?.cancel();
    if (_isRecording) {
      try {
        await _recorder.stop();
      } catch (_) {}
      _isRecording = false;
    }
  }

  void dispose() {
    _autoStopTimer?.cancel();
    _recorder.dispose();
  }
}
