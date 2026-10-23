// ─────────────────────────────────────────────
//  raksha_visual_map.dart
//  Interactive visual map component powered by flutter_map
//  and Geoapify / OpenStreetMap raster tiles.
//  • Fixes the blank white screen issue permanently
//  • Real-time animated radar pulse at user's GPS pin
//  • Movement path polyline breadcrumbs
//  • Custom emergency markers (Tracked user, Police, Hospital)
//  • Map style toggle (Dark Safety / Street Bright)
// ─────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:google_fonts/google_fonts.dart';

import '../services/geoapify_service.dart';
import '../services/alert_notification_service.dart';
import '../theme/app_colors.dart';

class RakshaMapMarker {
  final ll.LatLng point;
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final bool isEmergency;

  const RakshaMapMarker({
    required this.point,
    required this.title,
    this.subtitle,
    this.icon = Icons.location_on,
    this.color = AppColors.primary,
    this.isEmergency = false,
  });
}

class RakshaVisualMap extends StatefulWidget {
  final ll.LatLng center;
  final double zoom;
  final List<RakshaMapMarker> markers;
  final List<ll.LatLng> polylinePoints;
  final List<DangerZoneAlertItem> dangerZones;
  final bool showUserPulse;
  final bool isEmergency;
  final String? addressText;
  final double? accuracyMeters;
  final VoidCallback? onRecenter;

  const RakshaVisualMap({
    super.key,
    required this.center,
    this.zoom = 16.0,
    this.markers = const [],
    this.polylinePoints = const [],
    this.dangerZones = const [],
    this.showUserPulse = true,
    this.isEmergency = false,
    this.addressText,
    this.accuracyMeters,
    this.onRecenter,
  });

  @override
  State<RakshaVisualMap> createState() => _RakshaVisualMapState();
}

class _RakshaVisualMapState extends State<RakshaVisualMap>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  final GeoapifyService _geoapify = GeoapifyService();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isDarkStyle = true;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.5).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOutQuad),
    );
  }

  @override
  void didUpdateWidget(RakshaVisualMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.center != widget.center && _isMapReady) {
      try {
        _mapController.move(widget.center, _mapController.camera.zoom);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tileUrl = _geoapify.getTileUrlTemplate(dark: _isDarkStyle);

    return Stack(
      children: [
        // ── Flutter Map Tile Layer ──────────────────
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: widget.center,
            initialZoom: widget.zoom,
            minZoom: 4,
            maxZoom: 19,
            onMapReady: () {
              _isMapReady = true;
            },
          ),
          children: [
            TileLayer(
              urlTemplate: tileUrl,
              userAgentPackageName: 'com.raksha.raksha_plus',
              maxZoom: 19,
            ),

            // Danger Zones (Circles & Radius)
            if (widget.dangerZones.any((z) => z.zoneType == 'CIRCLE'))
              CircleLayer(
                circles: widget.dangerZones
                    .where((z) => z.zoneType == 'CIRCLE')
                    .map((z) => CircleMarker(
                          point: ll.LatLng(z.latitude, z.longitude),
                          radius: z.radiusM,
                          useRadiusInMeter: true,
                          color: (z.severity == 'HIGH' ? Colors.redAccent : Colors.orangeAccent)
                              .withValues(alpha: 0.22),
                          borderColor: z.severity == 'HIGH' ? Colors.redAccent : Colors.orangeAccent,
                          borderStrokeWidth: 2.0,
                        ))
                    .toList(),
              ),

            // Polyline breadcrumb trail + Danger Road line corridors
            PolylineLayer(
              polylines: [
                if (widget.polylinePoints.length > 1)
                  Polyline(
                    points: widget.polylinePoints,
                    strokeWidth: 4.0,
                    color: AppColors.primary.withValues(alpha: 0.8),
                  ),
                ...widget.dangerZones
                    .where((z) => z.zoneType == 'ROAD_LINE' && z.pathCoordinates.isNotEmpty)
                    .map((z) => Polyline(
                          points: z.pathCoordinates.map((c) => ll.LatLng(c[0], c[1])).toList(),
                          strokeWidth: 5.0,
                          color: Colors.redAccent.withValues(alpha: 0.85),
                          borderColor: Colors.amberAccent,
                          borderStrokeWidth: 1.5,
                        )),
              ],
            ),

            // Markers layer
            MarkerLayer(
              markers: [
                // Pulse ripple around center
                if (widget.showUserPulse)
                  Marker(
                    point: widget.center,
                    width: 90,
                    height: 90,
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Center(
                          child: Container(
                            width: 30 * _pulseAnimation.value,
                            height: 30 * _pulseAnimation.value,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: (widget.isEmergency ? Colors.redAccent : AppColors.primary)
                                  .withValues(alpha: (1.5 - _pulseAnimation.value).clamp(0.0, 0.7)),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                // Center pin
                Marker(
                  point: widget.center,
                  width: 50,
                  height: 50,
                  child: Center(
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.isEmergency ? const Color(0xFFFF0055) : AppColors.primary,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Danger Zone Warning Pins
                ...widget.dangerZones.map((z) {
                  final pos = z.zoneType == 'CIRCLE'
                      ? ll.LatLng(z.latitude, z.longitude)
                      : (z.pathCoordinates.isNotEmpty
                          ? ll.LatLng(z.pathCoordinates.first[0], z.pathCoordinates.first[1])
                          : ll.LatLng(z.latitude, z.longitude));
                  return Marker(
                    point: pos,
                    width: 34,
                    height: 34,
                    child: Tooltip(
                      message: '⚠️ ${z.title} (${z.zoneType == 'CIRCLE' ? '${z.radiusM.toInt()}m radius' : 'Corridor'})\n${z.description}',
                      child: Container(
                        decoration: BoxDecoration(
                          color: z.severity == 'HIGH' ? Colors.red.shade900 : Colors.deepOrange.shade900,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.amberAccent, width: 2),
                          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
                        ),
                        child: const Icon(Icons.warning_amber_rounded, color: Colors.amberAccent, size: 18),
                      ),
                    ),
                  );
                }),

                // Additional custom markers
                ...widget.markers.map((m) {
                  return Marker(
                    point: m.point,
                    width: 48,
                    height: 48,
                    child: Tooltip(
                      message: m.title,
                      child: Container(
                        decoration: BoxDecoration(
                          color: m.color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [
                            BoxShadow(color: Colors.black38, blurRadius: 6),
                          ],
                        ),
                        child: Icon(m.icon, color: Colors.white, size: 24),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),

        // ── Top GPS & Address Banner ────────────────
        if (widget.addressText != null && widget.addressText!.isNotEmpty)
          Positioned(
            top: 14,
            left: 14,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.cardBg.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
                boxShadow: const [
                  BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.addressText!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (widget.accuracyMeters != null)
                          Text(
                            'GPS Accuracy: ±${widget.accuracyMeters!.toInt()}m • Geoapify Live',
                            style: GoogleFonts.poppins(
                              color: AppColors.liveGreen,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

        // ── Floating Action Buttons (Recenter & Style) ──
        Positioned(
          bottom: 20,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Style switcher (Dark / Bright)
              FloatingActionButton.small(
                heroTag: 'map_style_toggle',
                backgroundColor: AppColors.cardBg,
                foregroundColor: Colors.white,
                onPressed: () => setState(() => _isDarkStyle = !_isDarkStyle),
                child: Icon(_isDarkStyle ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined),
              ),
              const SizedBox(height: 10),

              // Zoom In
              FloatingActionButton.small(
                heroTag: 'map_zoom_in',
                backgroundColor: AppColors.cardBg,
                foregroundColor: Colors.white,
                onPressed: () {
                  final cur = _mapController.camera.zoom;
                  _mapController.move(_mapController.camera.center, cur + 1);
                },
                child: const Icon(Icons.add),
              ),
              const SizedBox(height: 10),

              // Zoom Out
              FloatingActionButton.small(
                heroTag: 'map_zoom_out',
                backgroundColor: AppColors.cardBg,
                foregroundColor: Colors.white,
                onPressed: () {
                  final cur = _mapController.camera.zoom;
                  _mapController.move(_mapController.camera.center, cur - 1);
                },
                child: const Icon(Icons.remove),
              ),
              const SizedBox(height: 10),

              // Recenter on user
              FloatingActionButton(
                heroTag: 'map_recenter',
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                onPressed: () {
                  _mapController.move(widget.center, 16.5);
                  if (widget.onRecenter != null) widget.onRecenter!();
                },
                child: const Icon(Icons.my_location_rounded),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
