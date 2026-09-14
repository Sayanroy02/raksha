// ─────────────────────────────────────────────
//  sos_controller.dart
//  Manages the SOS emergency flow:
//
//  1. User holds the SOS button for 3 seconds
//  2. Controller counts down with visual feedback
//  3. On trigger — gets GPS, calls API, starts
//     periodic location broadcast
//  4. "Stop Sharing" cancels everything
// ─────────────────────────────────────────────
import 'dart:async';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/sos_service.dart';
import '../utils/constants.dart';

class SosController extends GetxController {
  final SosService _sosService;
  SosController(this._sosService);

  // ── State ────────────────────────────────────
  final RxBool   isActive       = false.obs; // SOS is currently live
  final RxBool   isLoading      = false.obs;
  final RxInt    holdProgress   = 0.obs;     // 0–100 fill for hold animation
  final RxString elapsedTime    = '00:00'.obs;
  final RxString activeIncidentId = ''.obs;

  Timer? _holdTimer;   // tracks the 3-second hold countdown
  Timer? _elapsedTimer;// tracks how long SOS has been active
  Timer? _broadcastTimer; // periodic location broadcast
  int    _elapsedSeconds = 0;
  int    _holdSeconds    = 0;

  // ── Hold logic ───────────────────────────────

  /// Called when the user starts pressing the SOS button
  void onHoldStart() {
    if (isActive.value) return; // already triggered
    _holdSeconds = 0;
    holdProgress.value = 0;

    // Tick every 30 ms to animate the fill ring smoothly
    _holdTimer = Timer.periodic(const Duration(milliseconds: 30), (t) {
      _holdSeconds += 30;
      holdProgress.value =
          (_holdSeconds / (AppConstants.sosHoldDuration * 1000) * 100)
              .clamp(0, 100)
              .toInt();

      if (_holdSeconds >= AppConstants.sosHoldDuration * 1000) {
        t.cancel();
        _triggerSos(); // 3 seconds reached — fire!
      }
    });
  }

  /// Called when the user lifts their finger before 3 seconds
  void onHoldCancel() {
    _holdTimer?.cancel();
    holdProgress.value = 0;
  }

  // ── SOS Trigger ──────────────────────────────

  Future<void> _triggerSos() async {
    isLoading.value = true;
    try {
      final position = await _getCurrentPosition();
      if (position == null) {
        Get.snackbar(
          'Location Error',
          'Could not get your location. Please enable GPS.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final resp = await _sosService.triggerSos(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      final data = resp.data as Map<String, dynamic>?;
      final incId = (data?['incident_id'] ?? data?['_id'] ?? data?['id'] ?? '').toString();
      activeIncidentId.value = incId;
      isActive.value = true;

      _startElapsedTimer();
      _startBroadcast();

      // Automatically attach emergency audio recording simulation link so guardian can listen
      if (incId.isNotEmpty) {
        _sosService.attachAudio(
          incidentId: incId,
          audioUrl: 'https://actions.google.com/sounds/v1/emergency/siren_emergency_truck.ogg',
          durationSeconds: 15.0,
        ).ignore();
      }

      Get.snackbar(
        '🆘 SOS Triggered',
        'Your safety circle has been alerted. Location is broadcasting live.',
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      Get.snackbar('Error', 'Could not trigger SOS: $e',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
      holdProgress.value = 0;
    }
  }

  /// Share live location and SOS status directly to WhatsApp
  Future<void> shareOnWhatsApp({double? lat, double? lng}) async {
    final pos = await _getCurrentPosition();
    final lt = lat ?? pos?.latitude ?? 26.7271;
    final ln = lng ?? pos?.longitude ?? 88.3953;
    final googleMapsUrl = 'https://www.google.com/maps?q=$lt,$ln';

    final message = '🚨 EMERGENCY SOS ALERT! - Raksha+\n'
        'I am in danger and need immediate assistance!\n'
        '📍 My Live GPS Location: $googleMapsUrl\n'
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
        await _sosService.stopSos(activeIncidentId.value);
      }
      isActive.value       = false;
      activeIncidentId.value = '';
      _elapsedSeconds      = 0;
      elapsedTime.value    = '00:00';
    } catch (_) {
      isActive.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  // ── Private helpers ──────────────────────────

  void _startElapsedTimer() {
    _elapsedSeconds = 0;
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedSeconds++;
      final m = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
      final s = (_elapsedSeconds  % 60).toString().padLeft(2, '0');
      elapsedTime.value = '$m:$s';
    });
  }

  void _startBroadcast() {
    _broadcastTimer = Timer.periodic(
      Duration(seconds: AppConstants.locationBroadcastInterval),
      (_) async {
        if (activeIncidentId.value.isEmpty) return;
        final pos = await _getCurrentPosition();
        if (pos != null) {
          await _sosService.logLocation(
            incidentId: activeIncidentId.value,
            latitude:   pos.latitude,
            longitude:  pos.longitude,
          );
        }
      },
    );
  }

  Future<Position?> _getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  void onClose() {
    _holdTimer?.cancel();
    _elapsedTimer?.cancel();
    _broadcastTimer?.cancel();
    super.onClose();
  }
}
