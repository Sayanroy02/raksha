// ─────────────────────────────────────────────
//  location_controller.dart
//  Tracks GPS position, manages location history,
//  and drives the Live Location map screen.
// ─────────────────────────────────────────────
import 'dart:async';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/location_log_model.dart';

class LocationController extends GetxController {
  // ── State ────────────────────────────────────
  final Rx<LatLng?>          currentPosition   = Rx(null);
  final RxList<LocationLogModel> locationHistory = <LocationLogModel>[].obs;
  final RxBool isLoadingHistory = false.obs;
  final RxBool isLocating       = false.obs;
  final RxDouble currentAccuracy = 0.0.obs;
  final RxString lastUpdatedTime = 'Just now'.obs;
  final RxSet<Marker>  markers  = <Marker>{}.obs;
  final RxList<LatLng> polyline = <LatLng>[].obs; // path trail on map

  GoogleMapController? mapController;
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
        Get.snackbar('GPS Disabled', 'Please enable Location Services (GPS) on your phone.',
            snackPosition: SnackPosition.BOTTOM);
      }

      // 1. Get immediate fix so user doesn't wait for movement
      final initialPos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      _updateLocation(initialPos);
    } catch (_) {
      // If error, use fallback
      if (currentPosition.value == null) {
        currentPosition.value = const LatLng(26.7271, 88.3953);
      }
    } finally {
      isLocating.value = false;
    }

    // 2. Listen to continuous GPS stream
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // update every 5 metres of movement
      ),
    ).listen(_updateLocation);
  }

  void _updateLocation(Position pos) {
    final latlng = LatLng(pos.latitude, pos.longitude);
    currentPosition.value = latlng;
    currentAccuracy.value = pos.accuracy;
    lastUpdatedTime.value = 'Just now';
    polyline.add(latlng);

    // Update "You are here" marker
    markers.clear();
    markers.add(
      Marker(
        markerId: const MarkerId('current'),
        position: latlng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
        infoWindow: InfoWindow(
          title: 'You are here',
          snippet: '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)} (±${pos.accuracy.toInt()}m)',
        ),
      ),
    );

    // Smoothly animate map camera to new position
    mapController?.animateCamera(CameraUpdate.newLatLng(latlng));
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    // Apply dark map style
    try {
      controller.setMapStyle(_darkMapStyle);
    } catch (_) {}
    // If we already have a position, move camera now
    if (currentPosition.value != null) {
      controller.animateCamera(CameraUpdate.newLatLngZoom(currentPosition.value!, 16));
    }
  }

  /// Recenter the camera on the user's current GPS position
  void recenterCamera() {
    final pos = currentPosition.value;
    if (pos != null && mapController != null) {
      mapController!.animateCamera(CameraUpdate.newLatLngZoom(pos, 16.5));
    }
  }

  /// Share current live coordinates on WhatsApp
  Future<void> shareLocationOnWhatsApp() async {
    final pos = currentPosition.value;
    final lt = pos?.latitude ?? 26.7271;
    final ln = pos?.longitude ?? 88.3953;
    final mapsUrl = 'https://www.google.com/maps?q=$lt,$ln';

    final message = '📍 Raksha+ Live Location Update:\n'
        'I am sharing my current location with you.\n'
        '🌐 Maps Link: $mapsUrl\n'
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

  // ── History ──────────────────────────────────

  Future<void> _loadHistory() async {
    // TODO: Call location history API endpoint
    // For now uses empty list — hook up to ApiService
    isLoadingHistory.value = true;
    await Future.delayed(const Duration(milliseconds: 500));
    isLoadingHistory.value = false;
  }

  @override
  void onClose() {
    _positionStream?.cancel();
    mapController?.dispose();
    super.onClose();
  }

  // ── Dark map style JSON ──────────────────────
  static const String _darkMapStyle = '''
  [
    {"elementType":"geometry","stylers":[{"color":"#1d2c4d"}]},
    {"elementType":"labels.text.fill","stylers":[{"color":"#8ec3b9"}]},
    {"elementType":"labels.text.stroke","stylers":[{"color":"#1a3646"}]},
    {"featureType":"road","elementType":"geometry","stylers":[{"color":"#304a7d"}]},
    {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0e1626"}]}
  ]
  ''';
}
