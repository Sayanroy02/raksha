// ─────────────────────────────────────────────
//  sos_service.dart
//  API calls for SOS (Emergency trigger).
// ─────────────────────────────────────────────
import 'package:dio/dio.dart';
import 'api_service.dart';

class SosService {
  final ApiService _api;
  SosService(this._api);

  /// Trigger an SOS incident — starts live location sharing
  /// POST /sos/trigger
  Future<Response> triggerSos({
    required double latitude,
    required double longitude,
    String triggerType = 'manual',
  }) {
    return _api.dio.post('/sos/trigger', data: {
      'location': {
        'lat': latitude,
        'lng': longitude,
      },
      'trigger_type': triggerType,
    });
  }

  /// Stop/cancel the active SOS incident
  /// POST /sos/{incident_id}/stop or /cancel
  Future<Response> stopSos(String incidentId) {
    return _api.dio.post('/sos/$incidentId/stop');
  }

  /// Get the current active incident for the authenticated user
  /// GET /sos/active
  Future<Response> getActiveIncident() {
    return _api.dio.get('/sos/active');
  }

  /// Log a live location update during an active SOS
  /// POST /sos/{incident_id}/location
  Future<Response> logLocation({
    required String incidentId,
    required double latitude,
    required double longitude,
    double? accuracy,
  }) {
    return _api.dio.post('/sos/$incidentId/location', data: {
      'coordinates': {
        'lat': latitude,
        'lng': longitude,
      },
      'accuracy': accuracy ?? 5.0,
    });
  }

  /// Guardian Tracking: Fetch live location and emergency status of a scanned QR target
  /// GET /sos/track/{target_id}
  Future<Response> trackTarget(String targetId) {
    return _api.dio.get('/sos/track/$targetId');
  }

  /// Attach audio evidence / live audio recording link to the incident
  /// POST /sos/{incident_id}/audio
  Future<Response> attachAudio({
    required String incidentId,
    required String audioUrl,
    double? durationSeconds,
  }) {
    return _api.dio.post('/sos/$incidentId/audio', data: {
      'audio_url': audioUrl,
      'duration_seconds': durationSeconds,
    });
  }
}
