// ─────────────────────────────────────────────
//  guardian_track_view.dart
//  Guardian Live Tracking & Audio Monitor Screen.
//  Displays the tracked user's real-time position,
//  emergency status, and an interactive audio player
//  to listen to live/emergency audio from their phone.
// ─────────────────────────────────────────────

import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/sos_service.dart';
import '../../theme/app_colors.dart';

class GuardianTrackView extends StatefulWidget {
  const GuardianTrackView({super.key});

  @override
  State<GuardianTrackView> createState() => _GuardianTrackViewState();
}

class _GuardianTrackViewState extends State<GuardianTrackView> {
  final SosService _sosService = Get.find<SosService>();
  final AudioPlayer _audioPlayer = AudioPlayer();

  GoogleMapController? _mapController;
  Timer? _pollingTimer;

  String _targetId = '';
  String _userName = 'Tracked User';
  String _userPhone = '';
  bool _isLoading = true;
  bool _isEmergency = false;
  String _statusText = 'Active';

  LatLng _currentLocation = const LatLng(26.7271, 88.3953);
  final Set<Marker> _markers = {};
  String? _audioUrl;

  bool _isPlayingAudio = false;
  bool _isLoadingAudio = false;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    _targetId = args?['targetId'] ?? '';
    _userName = args?['name'] ?? 'Tracked User';
    _userPhone = args?['phone'] ?? '';

    _setupAudioPlayer();
    _fetchTrackData();

    // Poll live location every 5 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchTrackData());
  }

  void _setupAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlayingAudio = (state == PlayerState.playing);
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlayingAudio = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _audioPlayer.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _fetchTrackData() async {
    if (_targetId.isEmpty) return;

    try {
      final resp = await _sosService.trackTarget(_targetId);
      final data = resp.data as Map<String, dynamic>;

      final loc = data['latest_location'] as Map<String, dynamic>?;
      final lat = (loc?['lat'] as num?)?.toDouble() ?? _currentLocation.latitude;
      final lng = (loc?['lng'] as num?)?.toDouble() ?? _currentLocation.longitude;

      if (mounted) {
        setState(() {
          _userName = data['name'] ?? _userName;
          _userPhone = data['phone'] ?? _userPhone;
          _isEmergency = data['is_emergency'] ?? false;
          _statusText = data['status'] ?? 'Active';
          _audioUrl = data['latest_audio_url'];
          _currentLocation = LatLng(lat, lng);
          _isLoading = false;

          _markers.clear();
          _markers.add(
            Marker(
              markerId: const MarkerId('tracked_user'),
              position: _currentLocation,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                _isEmergency ? BitmapDescriptor.hueRed : BitmapDescriptor.hueRose,
              ),
              infoWindow: InfoWindow(
                title: _userName,
                snippet: _isEmergency ? '🚨 SOS EMERGENCY ACTIVE!' : 'Location Active',
              ),
            ),
          );
        });

        _mapController?.animateCamera(CameraUpdate.newLatLng(_currentLocation));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleAudio() async {
    final url = _audioUrl ?? 'https://actions.google.com/sounds/v1/emergency/siren_emergency_truck.ogg';

    if (_isPlayingAudio) {
      await _audioPlayer.pause();
    } else {
      setState(() => _isLoadingAudio = true);
      try {
        await _audioPlayer.play(UrlSource(url));
      } catch (e) {
        Get.snackbar('Audio Error', 'Could not stream audio: $e');
      } finally {
        if (mounted) setState(() => _isLoadingAudio = false);
      }
    }
  }

  Future<void> _callUser() async {
    if (_userPhone.isNotEmpty) {
      final uri = Uri.parse('tel:$_userPhone');
      if (await canLaunchUrl(uri)) await launchUrl(uri);
    } else {
      Get.snackbar('No Phone Number', 'No contact phone number recorded for this user.');
    }
  }

  Future<void> _callEmergency() async {
    final uri = Uri.parse('tel:112');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: Text('Tracking: $_userName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchTrackData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Stack(
              children: [
                // ── Google Map ───────────────────────
                GoogleMap(
                  onMapCreated: (c) {
                    _mapController = c;
                    c.animateCamera(CameraUpdate.newLatLngZoom(_currentLocation, 16));
                  },
                  initialCameraPosition: CameraPosition(
                    target: _currentLocation,
                    zoom: 16,
                  ),
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                ),

                // ── Top Status Banner ────────────────
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: _isEmergency
                          ? const Color(0xFF8B0000).withValues(alpha: 0.95)
                          : AppColors.cardBg.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isEmergency ? Colors.redAccent : AppColors.divider,
                        width: _isEmergency ? 2 : 1,
                      ),
                      boxShadow: const [
                        BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isEmergency ? Icons.warning_rounded : Icons.shield_rounded,
                          color: _isEmergency ? Colors.yellowAccent : AppColors.liveGreen,
                          size: 26,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _isEmergency ? '⚠️ EMERGENCY SOS ACTIVE!' : 'Tracking Live Location',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'GPS: ${_currentLocation.latitude.toStringAsFixed(5)}, ${_currentLocation.longitude.toStringAsFixed(5)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black38,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _statusText.toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _isEmergency ? Colors.redAccent : AppColors.liveGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Bottom Controls: Audio & Actions ──
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                    decoration: const BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      border: Border(top: BorderSide(color: AppColors.divider)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── Audio Monitor Box ────────
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.inputBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _isPlayingAudio ? AppColors.primary : AppColors.divider,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  onPressed: _isLoadingAudio ? null : _toggleAudio,
                                  icon: _isLoadingAudio
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.primary,
                                          ),
                                        )
                                      : Icon(
                                          _isPlayingAudio ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                          color: AppColors.primary,
                                          size: 26,
                                        ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isPlayingAudio ? 'Listening to Phone Audio...' : 'Listen to Live Phone Audio',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      _isPlayingAudio
                                          ? 'Streaming ambient microphone audio'
                                          : 'Tap play to listen to surroundings audio',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.graphic_eq_rounded,
                                color: _isPlayingAudio ? AppColors.primary : AppColors.textHint,
                                size: 28,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── Quick Action Call Buttons ──
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: OutlinedButton.icon(
                                  onPressed: _callUser,
                                  icon: const Icon(Icons.call, color: Colors.white, size: 18),
                                  label: Text(
                                    'Call User',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppColors.divider),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: ElevatedButton.icon(
                                  onPressed: _callEmergency,
                                  icon: const Icon(Icons.emergency_rounded, color: Colors.white, size: 18),
                                  label: Text(
                                    'Call 112 (Police)',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
