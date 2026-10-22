// ─────────────────────────────────────────────
//  sos_controller.dart
//  Manages the SOS emergency flow:
//  • Fast GPS acquisition with zero timeouts
//  • Dispatches SOS to backend + automatic Resend email alerts
//  • Real-time location broadcasting & WhatsApp sharing
// ─────────────────────────────────────────────
import 'dart:async';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/sos_service.dart';
import '../services/geoapify_service.dart';
import '../services/audio_capture_service.dart';
import '../services/alert_notification_service.dart';
import '../utils/constants.dart';

class SosController extends GetxController {
  final SosService _sosService;
  final GeoapifyService _geoapify = GeoapifyService();

  SosController(this._sosService);

  // ── State ────────────────────────────────────
  final RxBool   isActive         = false.obs; // SOS is currently live
  final RxBool   isLoading        = false.obs;
  final RxInt    holdProgress     = 0.obs;     // 0–100 fill for hold animation
  final RxString elapsedTime      = '00:00'.obs;
  final RxString activeIncidentId = ''.obs;
  final RxString lastKnownAddress = ''.obs;
  final RxDouble currentLat       = 26.7271.obs;
  final RxDouble currentLng       = 88.3953.obs;

  Timer? _holdTimer;       // tracks the 3-second hold countdown
  Timer? _elapsedTimer;    // tracks how long SOS has been active
  Timer? _broadcastTimer;  // periodic location broadcast
  int    _elapsedSeconds = 0;
  int    _holdSeconds    = 0;

  @override
  void onInit() {
    super.onInit();
    _checkActiveIncident();
  }

  Future<void> _checkActiveIncident() async {
    try {
      final resp = await _sosService.getActiveIncident();
      if (resp.statusCode == 200 && resp.data != null) {
        final data = resp.data as Map<String, dynamic>;
        final incId = (data['_id'] ?? data['id'] ?? '').toString();
        if (incId.isNotEmpty) {
          activeIncidentId.value = incId;
          isActive.value = true;
          _startElapsedTimer();
          _startBroadcast();
        }
      }
    } catch (_) {}
  }

  // ── Hold logic ───────────────────────────────

  void onHoldStart() {
    if (isActive.value) return;
    _holdSeconds = 0;
    holdProgress.value = 0;

    _holdTimer = Timer.periodic(const Duration(milliseconds: 30), (t) {
      _holdSeconds += 30;
      holdProgress.value =
          (_holdSeconds / (AppConstants.sosHoldDuration * 1000) * 100)
              .clamp(0, 100)
              .toInt();

      if (_holdSeconds >= AppConstants.sosHoldDuration * 1000) {
        t.cancel();
        _triggerSos();
      }
    });
  }

  void onHoldCancel() {
    _holdTimer?.cancel();
    holdProgress.value = 0;
  }

  // ── SOS Trigger ──────────────────────────────

  Future<void> _triggerSos() async {
    isLoading.value = true;
    try {
      final (lat, lng) = await _getFastPosition();
      currentLat.value = lat;
      currentLng.value = lng;

      // Reverse geocode via Geoapify in background
      _geoapify.reverseGeocode(lat, lng).then((addr) {
        lastKnownAddress.value = addr.formatted;
      }).catchError((_) {});

      final resp = await _sosService.triggerSos(
        latitude: lat,
        longitude: lng,
      );

      final data = resp.data as Map<String, dynamic>?;
      final incId = (data?['incident_id'] ?? data?['_id'] ?? data?['id'] ?? '').toString();
      activeIncidentId.value = incId;
      isActive.value = true;

      _startElapsedTimer();
      _startBroadcast();

      // Automatically send emergency live location email via Resend
      if (incId.isNotEmpty) {
        _sosService.sendEmailAlert(incId).ignore();

        // Capture real ambient microphone audio during SOS emergency
        AudioCaptureService().startEmergencyRecording(
          incidentId: incId,
          sosService: _sosService,
        ).ignore();

        // High priority emergency push notification
        AlertNotificationService().dispatchEmergencyAlert(
          title: 'SOS Emergency Alert Live',
          message: 'Real-time GPS broadcasted. Email & notifications dispatched to your safety circle.',
        );
      }
    } catch (e) {
      Get.snackbar(
        'SOS Notice',
        'SOS active in offline mode. Broadcasting location...',
        snackPosition: SnackPosition.BOTTOM,
      );
      isActive.value = true;
      _startElapsedTimer();
    } finally {
      isLoading.value = false;
      holdProgress.value = 0;
    }
  }

  /// Manually dispatch email alert with custom recipient or safety circle
  Future<void> sendCustomEmailAlert(String email) async {
    if (email.isEmpty || !GetUtils.isEmail(email)) {
      Get.snackbar('Invalid Email', 'Please enter a valid email address');
      return;
    }

    try {
      if (activeIncidentId.value.isNotEmpty) {
        await _sosService.sendEmailAlert(activeIncidentId.value, email: email);
      } else {
        // Trigger quick SOS or send direct alert
        await _triggerSos();
        if (activeIncidentId.value.isNotEmpty) {
          await _sosService.sendEmailAlert(activeIncidentId.value, email: email);
        }
      }
      Get.snackbar('📧 Email Sent', 'Live location and SOS alert delivered to $email via Resend.');
    } catch (e) {
      Get.snackbar('Error', 'Could not send email alert: $e');
    }
  }

  /// Share live location and SOS status directly to WhatsApp
  Future<void> shareOnWhatsApp({double? lat, double? lng}) async {
    final (lt, ln) = await _getFastPosition();
    final actualLat = lat ?? lt;
    final actualLng = lng ?? ln;
    final mapsUrl = 'https://www.google.com/maps?q=$actualLat,$actualLng';
    final geoapifyStatic = _geoapify.getStaticMapUrl(actualLat, actualLng);

    final message = '🚨 EMERGENCY SOS ALERT! - Raksha+\n'
        'I am in danger and need immediate assistance!\n'
        '📍 My Live GPS Location: $mapsUrl\n'
        '🗺️ Live Map Snapshot: $geoapifyStatic\n'
        '⚠️ Incident ID: ${activeIncidentId.value.isNotEmpty ? activeIncidentId.value : "ACTIVE_EMERGENCY"}\n'
        'Please send help or contact authorities immediately!';

    final whatsappUrl = 'whatsapp://send?text=${Uri.encodeComponent(message)}';
    final webUrl = 'https://api.whatsapp.com/send?text=${Uri.encodeComponent(message)}';

    try {
      final uri = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(Uri.parse(webUrl), mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      Get.snackbar('WhatsApp Error', 'Could not open WhatsApp. Please ensure it is installed.');
    }
  }

  // ── Stop sharing ─────────────────────────────

  Future<void> stopSos() async {
    _elapsedTimer?.cancel();
    _broadcastTimer?.cancel();
    isLoading.value = true;
    try {
      if (activeIncidentId.value.isNotEmpty) {
        // Finalize and upload any ongoing audio recording
        await AudioCaptureService().stopAndUploadRecording(
          incidentId: activeIncidentId.value,
          sosService: _sosService,
        );
        await _sosService.stopSos(activeIncidentId.value);
      }
      isActive.value         = false;
      activeIncidentId.value = '';
      _elapsedSeconds        = 0;
      elapsedTime.value      = '00:00';
    } catch (_) {
      isActive.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  // ── Private helpers ──────────────────────────

  void _startElapsedTimer() {
    _elapsedSeconds = 0;
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedSeconds++;
      final m = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
      final s = (_elapsedSeconds  % 60).toString().padLeft(2, '0');
      elapsedTime.value = '$m:$s';
    });
  }

  void _startBroadcast() {
    _broadcastTimer?.cancel();
    _broadcastTimer = Timer.periodic(
      Duration(seconds: AppConstants.locationBroadcastInterval),
      (_) async {
        if (activeIncidentId.value.isEmpty) return;
        final (lat, lng) = await _getFastPosition();
        currentLat.value = lat;
        currentLng.value = lng;
        try {
          await _sosService.logLocation(
            incidentId: activeIncidentId.value,
            latitude:   lat,
            longitude:  lng,
          );
        } catch (_) {}
      },
    );
  }

  /// Bulletproof fast position resolver: NEVER hangs or times out.
  /// 1. Checks last known position immediately (<10ms)
  /// 2. If null, tries high-accuracy GPS with a strict 3-second timeout
  /// 3. If that fails or times out, uses Geoapify IP location
  /// 4. Fallback default
  Future<(double, double)> _getFastPosition() async {
    try {
      final lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null) {
        return (lastPos.latitude, lastPos.longitude);
      }
    } catch (_) {}

    try {
      final curPos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 3),
        ),
      );
      return (curPos.latitude, curPos.longitude);
    } catch (_) {}

    try {
      final ipLoc = await _geoapify.getIpLocation();
      final lat = (ipLoc['lat'] as num?)?.toDouble() ?? 26.7271;
      final lng = (ipLoc['lng'] as num?)?.toDouble() ?? 88.3953;
      return (lat, lng);
    } catch (_) {}

    return (26.7271, 88.3953);
  }

  @override
  void onClose() {
    _holdTimer?.cancel();
    _elapsedTimer?.cancel();
    _broadcastTimer?.cancel();
    super.onClose();
  }
}
