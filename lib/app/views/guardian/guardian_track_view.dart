// ─────────────────────────────────────────────
//  guardian_track_view.dart
//  Guardian Live Tracking & Audio Monitor Screen.
//  Displays the tracked user's real-time position using
//  RakshaVisualMap (flutter_map & Geoapify tiles),
//  emergency status, and an interactive audio player
//  to listen to live/emergency audio from their phone.
// ─────────────────────────────────────────────

import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/sos_service.dart';
import '../../services/geoapify_service.dart';
import '../../controllers/location_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/raksha_visual_map.dart';

class GuardianTrackView extends StatefulWidget {
  const GuardianTrackView({super.key});

  @override
  State<GuardianTrackView> createState() => _GuardianTrackViewState();
}

class _GuardianTrackViewState extends State<GuardianTrackView> {
  final SosService _sosService = Get.find<SosService>();
  final GeoapifyService _geoapify = GeoapifyService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  Timer? _pollingTimer;

  String _targetId = '';
  String _userName = 'Tracked User';
  String _userPhone = '';
  bool _isLoading = true;
  bool _isEmergency = false;
  String _statusText = 'Active';
  String _formattedAddress = 'Detecting location address...';

  ll.LatLng _currentLocation = const ll.LatLng(26.7271, 88.3953);
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

      final newPoint = ll.LatLng(lat, lng);

      if (mounted) {
        setState(() {
          _userName = data['name'] ?? _userName;
          _userPhone = data['phone'] ?? _userPhone;
          _isEmergency = data['is_emergency'] ?? false;
          _statusText = data['status'] ?? 'Active';
          _audioUrl = data['latest_audio_url'];
          _currentLocation = newPoint;
          _isLoading = false;
        });

        _geoapify.reverseGeocode(lat, lng).then((addr) {
          if (mounted) {
            setState(() => _formattedAddress = addr.formatted);
          }
        }).catchError((_) {});
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
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchTrackData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Stack(
              children: [
                // ── 1. Interactive Visual Map (No White Screen) ──
                RakshaVisualMap(
                  center: _currentLocation,
                  zoom: 16.5,
                  showUserPulse: true,
                  isEmergency: _isEmergency,
                  addressText: _formattedAddress,
                  dangerZones: Get.isRegistered<LocationController>()
                      ? Get.find<LocationController>().dangerZones.toList()
                      : const [],
                  onRecenter: _fetchTrackData,
                ),

                // ── 2. Top Emergency / Safe Status Banner ──
                Positioned(
                  top: 14,
                  left: 14,
                  right: 14,
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
                                _isEmergency ? '⚠️ EMERGENCY SOS ACTIVE!' : 'Guardian Live Tracking',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                _formattedAddress,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _isEmergency ? Colors.red : AppColors.liveGreen.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _isEmergency ? 'CRITICAL' : _statusText.toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── 3. Bottom Action Controls & Audio Monitor ──
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    decoration: const BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      border: Border(top: BorderSide(color: AppColors.divider)),
                      boxShadow: [
                        BoxShadow(color: Colors.black54, blurRadius: 15, offset: Offset(0, -3)),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Live Audio Stream Monitor
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.scaffoldBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _isPlayingAudio ? AppColors.primary : AppColors.divider,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isPlayingAudio ? Icons.graphic_eq_rounded : Icons.mic_rounded,
                                color: _isPlayingAudio ? AppColors.primary : AppColors.textSecondary,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isPlayingAudio ? 'Streaming Emergency Audio...' : 'Live Microphone Feed',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      _audioUrl != null ? 'Audio evidence active' : 'Click listen to monitor ambient audio',
                                      style: GoogleFonts.poppins(
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _isLoadingAudio
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                    )
                                  : ElevatedButton(
                                      onPressed: _toggleAudio,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _isPlayingAudio ? Colors.redAccent : AppColors.primary,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      ),
                                      child: Text(
                                        _isPlayingAudio ? 'Stop' : 'Listen',
                                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Action Buttons: Call User & Call 112
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 46,
                                child: OutlinedButton.icon(
                                  onPressed: _callUser,
                                  icon: const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 18),
                                  label: Text(
                                    'Call $_userName',
                                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppColors.divider),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 46,
                                child: ElevatedButton.icon(
                                  onPressed: _callEmergency,
                                  icon: const Icon(Icons.emergency_rounded, color: Colors.white, size: 18),
                                  label: Text(
                                    'Call Police (112)',
                                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
