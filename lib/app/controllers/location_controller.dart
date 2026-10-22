// ─────────────────────────────────────────────
//  location_controller.dart
//  Tracks GPS position, manages location history,
//  and drives the Live Location visual map screen.
// ─────────────────────────────────────────────
import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/location_log_model.dart';
import '../services/geoapify_service.dart';
import '../services/alert_notification_service.dart';

class LocationController extends GetxController {
  final GeoapifyService _geoapify = GeoapifyService();

  // ── State ────────────────────────────────────
  final Rx<ll.LatLng>        currentPoint      = const ll.LatLng(26.7271, 88.3953).obs;
  final RxList<LocationLogModel> locationHistory = <LocationLogModel>[].obs;
  final RxBool isLoadingHistory = false.obs;
  final RxBool isLocating       = false.obs;
  final RxDouble currentAccuracy = 5.0.obs;
  final RxString lastUpdatedTime = 'Just now'.obs;
  final RxString formattedAddress = 'Detecting current address...'.obs;
  final RxList<ll.LatLng> polyline = <ll.LatLng>[].obs;

  StreamSubscription<Position>? _positionStream;

  @override
  void onInit() {
    super.onInit();
    _startTracking();
    _loadHistory();
  }

  // ── Live Tracking ────────────────────────────

  void _startTracking() async {
    isLocating.value = true;
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar(
          'GPS Disabled',
          'Please enable Location Services (GPS) on your phone for precise tracking.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }

      // Fast immediate position:
      Position? initialPos = await Geolocator.getLastKnownPosition();
      if (initialPos == null) {
        try {
          initialPos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.best,
              timeLimit: Duration(seconds: 4),
            ),
          );
        } catch (_) {}
      }

      if (initialPos != null) {
        _updateLocation(initialPos);
      } else {
        // Fallback to IP geolocation via Geoapify
        final ipLoc = await _geoapify.getIpLocation();
        final lat = (ipLoc['lat'] as num?)?.toDouble() ?? 26.7271;
        final lng = (ipLoc['lng'] as num?)?.toDouble() ?? 88.3953;
        currentPoint.value = ll.LatLng(lat, lng);
        polyline.add(currentPoint.value);
        _resolveAddress(lat, lng);
      }
    } catch (_) {
      polyline.add(currentPoint.value);
    } finally {
      isLocating.value = false;
    }

    // Continuous high-precision GPS stream
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 3, // update every 3 metres of movement
      ),
    ).listen(_updateLocation);
  }

  final RxBool isUserMoving = false.obs;
  final RxString movementStatus = 'Static • Stationary'.obs;
  Position? _lastRecordedPos;

  static const String _kHistoryPrefsKey = 'raksha_location_history_logs';

  void _updateLocation(Position pos) {
    final point = ll.LatLng(pos.latitude, pos.longitude);
    currentPoint.value = point;
    currentAccuracy.value = pos.accuracy;
    lastUpdatedTime.value = 'Just now';

    // Proximity check against active danger zones and road lines
    AlertNotificationService().checkProximityToDangerZones(pos.latitude, pos.longitude);

    // Add to breadcrumb path if moved
    if (polyline.isEmpty || polyline.last != point) {
      polyline.add(point);
    }

    double distMoved = 0;
    if (_lastRecordedPos != null) {
      distMoved = Geolocator.distanceBetween(
        _lastRecordedPos!.latitude,
        _lastRecordedPos!.longitude,
        pos.latitude,
        pos.longitude,
      );
    }

    // Detect if moving vs static
    if (pos.speed > 0.8 || distMoved > 4.0) {
      isUserMoving.value = true;
      final speedKmh = ((pos.speed > 0 ? pos.speed : 1.2) * 3.6).toStringAsFixed(1);
      movementStatus.value = 'Moving ($speedKmh km/h)';
    } else {
      isUserMoving.value = false;
      movementStatus.value = 'Static • Safe';
    }

    _resolveAddress(pos.latitude, pos.longitude);

    // Only record checkpoint into locationHistory when user moves > 8 metres
    if (_lastRecordedPos == null || distMoved >= 8.0) {
      _lastRecordedPos = pos;
      _recordCheckpoint(pos);
    }
  }

  Future<void> _recordCheckpoint(Position pos) async {
    try {
      final addr = await _geoapify.reverseGeocode(pos.latitude, pos.longitude);
      final log = LocationLogModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        latitude: pos.latitude,
        longitude: pos.longitude,
        address: addr.formatted,
        timestamp: DateTime.now(),
      );
      locationHistory.insert(0, log);
      if (locationHistory.length > 50) {
        locationHistory.removeLast();
      }
      _saveHistoryToPrefs();
    } catch (_) {}
  }

  Future<void> _resolveAddress(double lat, double lon) async {
    try {
      final addr = await _geoapify.reverseGeocode(lat, lon);
      formattedAddress.value = addr.formatted;
    } catch (_) {}
  }

  /// Recenter the map on user position
  void recenterCamera() {
    isLocating.value = true;
    Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        timeLimit: Duration(seconds: 3),
      ),
    ).then((pos) {
      _updateLocation(pos);
    }).catchError((_) {}).whenComplete(() {
      isLocating.value = false;
    });
  }

  /// Share current live coordinates on WhatsApp
  Future<void> shareLocationOnWhatsApp() async {
    final lt = currentPoint.value.latitude;
    final ln = currentPoint.value.longitude;
    final mapsUrl = 'https://www.google.com/maps?q=$lt,$ln';
    final staticMap = _geoapify.getStaticMapUrl(lt, ln);

    final message = '📍 Raksha+ Live Location Update:\n'
        '🏠 Address: ${formattedAddress.value}\n'
        '🌐 Maps Link: $mapsUrl\n'
        '🗺️ Live Map: $staticMap\n'
        '📍 Coordinates: ${lt.toStringAsFixed(5)}, ${ln.toStringAsFixed(5)} (±${currentAccuracy.value.toInt()}m)\n'
        'Stay safe with Raksha+ Women Safety Platform!';

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

  // ── History Persistence ──────────────────────

  Future<void> _loadHistory() async {
    isLoadingHistory.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_kHistoryPrefsKey) ?? [];
      final list = <LocationLogModel>[];
      for (final s in raw) {
        try {
          final m = jsonDecode(s) as Map<String, dynamic>;
          list.add(LocationLogModel.fromJson(m));
        } catch (_) {}
      }
      locationHistory.assignAll(list);
    } catch (_) {} finally {
      isLoadingHistory.value = false;
    }
  }

  Future<void> _saveHistoryToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final strings = locationHistory.map((e) => jsonEncode(e.toJson())).toList();
      await prefs.setStringList(_kHistoryPrefsKey, strings);
    } catch (_) {}
  }

  Future<void> clearHistory() async {
    locationHistory.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kHistoryPrefsKey);
    Get.snackbar(
      'History Cleared',
      'Location movement history has been cleared.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  void onClose() {
    _positionStream?.cancel();
    super.onClose();
  }
}
