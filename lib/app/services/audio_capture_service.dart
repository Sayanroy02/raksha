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

  bool _shouldStreamContinuously = false;

  bool get isRecording => _isRecording;

  /// Start recording emergency audio immediately upon SOS trigger.
  /// Continuously streams/uploads in chunks while SOS remains active
  /// so admin panel can hear ambient audio in real time.
  Future<void> startEmergencyRecording({
    required String incidentId,
    required SosService sosService,
    Duration chunkDuration = const Duration(seconds: 15),
    Duration? recordDuration,
  }) async {
    _shouldStreamContinuously = true;
    if (_isRecording) return;
    await _recordChunk(
      incidentId: incidentId,
      sosService: sosService,
      chunkDuration: recordDuration ?? chunkDuration,
    );
  }

  Future<void> _recordChunk({
    required String incidentId,
    required SosService sosService,
    required Duration chunkDuration,
  }) async {
    if (!_shouldStreamContinuously) return;

    try {
      final micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        debugPrint('[AudioCaptureService] Microphone permission not granted');
        return;
      }

      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) return;

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${tempDir.path}/sos_ambient_$timestamp.m4a';

      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      );

      await _recorder.start(config, path: _currentRecordingPath!);
      _isRecording = true;
      debugPrint('[AudioCaptureService] 🎙️ Live audio chunk recording started');

      _autoStopTimer?.cancel();
      _autoStopTimer = Timer(chunkDuration, () async {
        if (_shouldStreamContinuously) {
          await stopAndUploadRecording(incidentId: incidentId, sosService: sosService);
          // Chain next chunk immediately if SOS is still active
          if (_shouldStreamContinuously) {
            _recordChunk(incidentId: incidentId, sosService: sosService, chunkDuration: chunkDuration);
          }
        }
      });
    } catch (e) {
      debugPrint('[AudioCaptureService] Error recording audio chunk: $e');
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
        debugPrint('[AudioCaptureService] 📤 Uploading emergency live audio chunk...');
        final resp = await sosService.uploadAudioFile(
          incidentId: incidentId,
          filePath: finalPath,
        );
        debugPrint('[AudioCaptureService] ✅ Real-time audio evidence uploaded: ${resp.data}');
        return finalPath;
      }
    } catch (e) {
      debugPrint('[AudioCaptureService] Error stopping or uploading audio: $e');
    } finally {
      _isRecording = false;
    }
    return null;
  }

  /// Cancel current recording and stop streaming loop
  Future<void> cancelRecording() async {
    _shouldStreamContinuously = false;
    _autoStopTimer?.cancel();
    if (_isRecording) {
      try {
        await _recorder.stop();
      } catch (_) {}
      _isRecording = false;
    }
  }

  void dispose() {
    _shouldStreamContinuously = false;
    _autoStopTimer?.cancel();
    _recorder.dispose();
  }
}
