// ─────────────────────────────────────────────
//  video_evidence_service.dart
//  Captures 30 seconds of high-priority video evidence automatically
//  on SOS trigger, saves it locally to the Evidence Vault,
//  and uploads directly to the Raksha backend for police/admin dispatch.
// ─────────────────────────────────────────────
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sos_service.dart';

class VideoEvidenceService {
  static final VideoEvidenceService _instance = VideoEvidenceService._internal();
  factory VideoEvidenceService() => _instance;
  VideoEvidenceService._internal();

  CameraController? _cameraController;
  bool _isRecording = false;
  Timer? _countdownTimer;

  bool get isRecording => _isRecording;

  /// Automatically captures 30 seconds of video evidence on SOS trigger
  Future<void> start30sVideoEvidenceCapture({
    required String incidentId,
    required SosService sosService,
  }) async {
    if (_isRecording) return;

    try {
      final camStatus = await Permission.camera.request();
      final micStatus = await Permission.microphone.request();

      if (!camStatus.isGranted) {
        debugPrint('[VideoEvidenceService] Camera permission not granted');
        return;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        debugPrint('[VideoEvidenceService] No cameras found on device');
        return;
      }

      // Prefer back camera for situational environment; fallback to front
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: micStatus.isGranted,
      );

      await _cameraController!.initialize();
      await _cameraController!.startVideoRecording();
      _isRecording = true;
      debugPrint('[VideoEvidenceService] 📹 30-second emergency video recording started');

      // Automatically stop and upload after 30 seconds
      _countdownTimer?.cancel();
      _countdownTimer = Timer(const Duration(seconds: 30), () async {
        await stopAndUploadVideo(incidentId: incidentId, sosService: sosService);
      });
    } catch (e) {
      debugPrint('[VideoEvidenceService] Error initializing camera or recording video: $e');
      _isRecording = false;
      try {
        await _cameraController?.dispose();
      } catch (_) {}
      _cameraController = null;
    }
  }

  /// Stop recording early (e.g. when SOS is stopped before 30s) and upload
  Future<String?> stopAndUploadVideo({
    required String incidentId,
    required SosService sosService,
  }) async {
    _countdownTimer?.cancel();
    if (!_isRecording || _cameraController == null) return null;

    try {
      final XFile file = await _cameraController!.stopVideoRecording();
      _isRecording = false;

      final filePath = file.path;
      if (File(filePath).existsSync()) {
        debugPrint('[VideoEvidenceService] 📤 Uploading 30s emergency video: $filePath');
        final resp = await sosService.uploadVideoFile(
          incidentId: incidentId,
          filePath: filePath,
        );
        debugPrint('[VideoEvidenceService] ✅ Video evidence uploaded: ${resp.data}');

        // Save to user's local Evidence Vault
        try {
          final prefs = await SharedPreferences.getInstance();
          final list = prefs.getStringList('raksha_saved_evidence_vault') ?? [];
          final item = {
            'path': filePath,
            'type': 'video',
            'timestamp': DateTime.now().toIso8601String(),
            'title': 'SOS_Emergency_Video_30s',
          };
          list.insert(0, jsonEncode(item));
          await prefs.setStringList('raksha_saved_evidence_vault', list);
        } catch (_) {}

        return filePath;
      }
    } catch (e) {
      debugPrint('[VideoEvidenceService] Error stopping or uploading video: $e');
    } finally {
      _isRecording = false;
      try {
        await _cameraController?.dispose();
      } catch (_) {}
      _cameraController = null;
    }
    return null;
  }

  Future<void> cancelRecording() async {
    _countdownTimer?.cancel();
    if (_isRecording && _cameraController != null) {
      try {
        await _cameraController?.stopVideoRecording();
      } catch (_) {}
      _isRecording = false;
      try {
        await _cameraController?.dispose();
      } catch (_) {}
      _cameraController = null;
    }
  }

  void dispose() {
    _countdownTimer?.cancel();
    _cameraController?.dispose();
    _cameraController = null;
  }
}
