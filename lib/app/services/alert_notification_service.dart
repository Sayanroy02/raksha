// ─────────────────────────────────────────────
//  alert_notification_service.dart
//  Real-time Push & In-App Emergency and Non-Safe Zone Alert Engine.
//  Monitors user GPS proximity to Admin-marked Danger Zones (Circles & Roads)
//  and dispatches high-priority audible/vibrating warning notifications.
// ─────────────────────────────────────────────
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'api_service.dart';
import '../theme/app_colors.dart';

class DangerZoneAlertItem {
  final String id;
  final String title;
  final String description;
  final String zoneType; // 'CIRCLE' | 'ROAD_LINE'
  final double latitude;
  final double longitude;
  final double radiusM;
  final String severity;
  final List<List<double>> pathCoordinates;

  DangerZoneAlertItem({
    required this.id,
    required this.title,
    required this.description,
    required this.zoneType,
    required this.latitude,
    required this.longitude,
    required this.radiusM,
    required this.severity,
    required this.pathCoordinates,
  });

  factory DangerZoneAlertItem.fromJson(Map<String, dynamic> json) {
    List<List<double>> paths = [];
    final rawPaths = json['path_coordinates'] ?? json['pathCoordinates'] ?? json['paths'];
    if (rawPaths is List) {
      for (var item in rawPaths) {
        if (item is List && item.length >= 2) {
          paths.add([
            (item[0] as num).toDouble(),
            (item[1] as num).toDouble(),
          ]);
        }
      }
    }

    final rawType = (json['zone_type'] ?? json['zoneType'] ?? 'CIRCLE').toString().toUpperCase();
    final normalizedType = (rawType.contains('ROAD') || rawType.contains('LINE')) ? 'ROAD_LINE' : 'CIRCLE';

    return DangerZoneAlertItem(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: json['title']?.toString() ?? 'Unsafe Area',
      description: json['description']?.toString() ?? 'Caution: Known hazardous or unlit zone.',
      zoneType: normalizedType,
      latitude: (json['latitude'] as num?)?.toDouble() ?? (json['lat'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? (json['lng'] as num?)?.toDouble() ?? 0.0,
      radiusM: (json['radius_m'] as num?)?.toDouble() ??
          (json['radiusM'] as num?)?.toDouble() ??
          (json['radius'] as num?)?.toDouble() ??
          300.0,
      severity: (json['severity'] ?? 'HIGH').toString().toUpperCase(),
      pathCoordinates: paths,
    );
  }
}

class AlertNotificationService {
  static final AlertNotificationService _instance = AlertNotificationService._internal();
  factory AlertNotificationService() => _instance;
  AlertNotificationService._internal();

  List<DangerZoneAlertItem> _cachedZones = [];
  final Map<String, DateTime> _lastAlertedMap = {};
  DateTime? _lastFetchTime;

  // Reactive notifications history for NotificationsView
  final RxList<Map<String, dynamic>> notificationsHistory = <Map<String, dynamic>>[].obs;

  /// Fetch active danger zones from backend
  Future<void> refreshDangerZones() async {
    try {
      final api = Get.find<ApiService>();
      final resp = await api.dio.get('/places/danger-zones');
      if (resp.statusCode == 200 && resp.data is List) {
        _cachedZones = (resp.data as List)
            .map((z) => DangerZoneAlertItem.fromJson(z as Map<String, dynamic>))
            .toList();
        _lastFetchTime = DateTime.now();
        debugPrint('[AlertNotification] Synchronized ${_cachedZones.length} danger zones.');
      }
    } catch (e) {
      debugPrint('[AlertNotification] Error fetching danger zones: $e');
    }
  }

  /// Check if user's current coordinates are inside or approaching an unsafe zone
  Future<void> checkProximityToDangerZones(double userLat, double userLng) async {
    // Refresh zones cache every 3 minutes
    if (_lastFetchTime == null || DateTime.now().difference(_lastFetchTime!).inMinutes > 3) {
      await refreshDangerZones();
    }

    if (_cachedZones.isEmpty) return;

    for (final zone in _cachedZones) {
      double minDistance = double.infinity;

      if (zone.zoneType == 'ROAD_LINE' && zone.pathCoordinates.length >= 2) {
        // Calculate distance from user to the road polyline
        minDistance = _distanceToPolyline(userLat, userLng, zone.pathCoordinates);
      } else {
        // Calculate distance to circle center
        minDistance = Geolocator.distanceBetween(
          userLat,
          userLng,
          zone.latitude,
          zone.longitude,
        );
      }

      // Alert threshold: within radius + 150m buffer (or within 200m for roads)
      final threshold = zone.zoneType == 'ROAD_LINE' ? 220.0 : (zone.radiusM + 120.0);

      if (minDistance <= threshold) {
        // Cooldown check (prevent repeated alerts for same zone within 5 minutes)
        final lastAlert = _lastAlertedMap[zone.id];
        if (lastAlert == null || DateTime.now().difference(lastAlert).inMinutes >= 5) {
          _lastAlertedMap[zone.id] = DateTime.now();
          _dispatchNonSafeZoneAlert(zone, minDistance.round());
        }
      }
    }
  }

  /// Trigger Non-Safe Zone Push & In-App Alert
  void _dispatchNonSafeZoneAlert(DangerZoneAlertItem zone, int distanceMeters) {
    HapticFeedback.heavyImpact();

    final isRoad = zone.zoneType == 'ROAD_LINE';
    final title = isRoad
        ? '⚠️ UNSAFE ROAD ALERT ($distanceMeters m away)'
        : '⚠️ DANGER ZONE ALERT ($distanceMeters m away)';
    final message = '${zone.title}: ${zone.description}. Stay in well-lit areas.';

    // Add to notifications history
    notificationsHistory.insert(0, {
      'title': title,
      'detail': message,
      'time': 'Just now',
      'icon': isRoad ? Icons.alt_route_rounded : Icons.warning_amber_rounded,
      'color': zone.severity == 'HIGH' ? Colors.redAccent : Colors.orangeAccent,
    });

    // Show instant Heads-up Notification banner
    Get.snackbar(
      title,
      message,
      duration: const Duration(seconds: 7),
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFF1E1014),
      colorText: Colors.white,
      borderColor: const Color(0xFFEF4444),
      borderWidth: 1.5,
      margin: const EdgeInsets.all(12),
      borderRadius: 12,
      icon: const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 30),
      mainButton: TextButton(
        onPressed: () => Get.toNamed('/live-location'),
        child: Text(
          'VIEW MAP',
          style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
    );
  }

  /// Dispatch Emergency SOS Push Alert
  void dispatchEmergencyAlert({required String title, required String message}) {
    HapticFeedback.heavyImpact();

    notificationsHistory.insert(0, {
      'title': '🚨 $title',
      'detail': message,
      'time': 'Just now',
      'icon': Icons.emergency_rounded,
      'color': Colors.redAccent,
    });

    Get.snackbar(
      '🚨 $title',
      message,
      duration: const Duration(seconds: 8),
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFF2B0A11),
      colorText: Colors.white,
      borderColor: const Color(0xFFFF2A55),
      borderWidth: 2,
      margin: const EdgeInsets.all(12),
      borderRadius: 14,
      icon: const Icon(Icons.crisis_alert_rounded, color: Color(0xFFFF2A55), size: 32),
    );
  }

  // ── Math: Point to Polyline distance (in meters) ────────
  double _distanceToPolyline(double pLat, double pLng, List<List<double>> polyline) {
    double minD = double.infinity;
    for (int i = 0; i < polyline.length - 1; i++) {
      final aLat = polyline[i][0];
      final aLng = polyline[i][1];
      final bLat = polyline[i + 1][0];
      final bLng = polyline[i + 1][1];

      final d = _distanceToSegment(pLat, pLng, aLat, aLng, bLat, bLng);
      if (d < minD) minD = d;
    }
    return minD;
  }

  double _distanceToSegment(
    double pLat,
    double pLng,
    double aLat,
    double aLng,
    double bLat,
    double bLng,
  ) {
    // Project point P onto line segment AB using Equirectangular approximation
    final x = (bLng - aLng) * cos((aLat + bLat) * pi / 360);
    final y = bLat - aLat;
    final segLenSq = x * x + y * y;

    if (segLenSq == 0) {
      return Geolocator.distanceBetween(pLat, pLng, aLat, aLng);
    }

    final px = (pLng - aLng) * cos((aLat + pLat) * pi / 360);
    final py = pLat - aLat;
    final t = ((px * x + py * y) / segLenSq).clamp(0.0, 1.0);

    final projLat = aLat + t * (bLat - aLat);
    final projLng = aLng + t * (bLng - aLng);

    return Geolocator.distanceBetween(pLat, pLng, projLat, projLng);
  }
}
