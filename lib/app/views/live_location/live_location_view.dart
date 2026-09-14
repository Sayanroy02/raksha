// ─────────────────────────────────────────────
//  live_location_view.dart
//  Shows a Google Map with real-time GPS coordinates,
//  pinpoint marker, accuracy indicator, WhatsApp share,
//  and SOS live sharing controls.
// ─────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/location_controller.dart';
import '../../controllers/sos_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bottom_nav_bar.dart';

class LiveLocationView extends GetView<LocationController> {
  const LiveLocationView({super.key});

  @override
  Widget build(BuildContext context) {
    final sos = Get.find<SosController>();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      bottomNavigationBar: const RakshaBottomNav(currentIndex: 1),
      appBar: AppBar(
        title: const Text('Live Location'),
        actions: [
          IconButton(
            tooltip: 'Share on WhatsApp',
            icon: const Icon(Icons.share_rounded, color: Colors.greenAccent),
            onPressed: controller.shareLocationOnWhatsApp,
          ),
          IconButton(
            tooltip: 'Recenter GPS',
            icon: const Icon(Icons.my_location_rounded),
            onPressed: controller.recenterCamera,
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── 1. Google Map ──────────────────────────
          Obx(() {
            final pos = controller.currentPosition.value;
            return GoogleMap(
              onMapCreated: controller.onMapCreated,
              initialCameraPosition: CameraPosition(
                target: pos ?? const LatLng(26.7271, 88.3953),
                zoom: 15.5,
              ),
              markers: controller.markers.toSet(),
              polylines: {
                if (controller.polyline.isNotEmpty)
                  Polyline(
                    polylineId: const PolylineId('trail'),
                    points: controller.polyline.toList(),
                    color: AppColors.primary,
                    width: 4,
                  ),
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            );
          }),

          // ── 2. Top Coordinates Status Banner ──────
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Obx(() {
              final pos = controller.currentPosition.value;
              final acc = controller.currentAccuracy.value;
              final isLocating = controller.isLocating.value;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.cardBg.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isLocating ? Colors.orangeAccent : AppColors.liveGreen,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            pos != null
                                ? '${pos.latitude.toStringAsFixed(5)}° N, ${pos.longitude.toStringAsFixed(5)}° E'
                                : 'Acquiring GPS Satellite Fix...',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            pos != null
                                ? 'GPS Accuracy: ±${acc.toInt()}m · High Precision'
                                : 'Please ensure you are under open sky with GPS on',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isLocating)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),

          // ── 3. Floating Quick Action Buttons ───────
          Positioned(
            right: 16,
            bottom: 230,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'whatsapp_btn',
                  backgroundColor: const Color(0xFF25D366),
                  onPressed: controller.shareLocationOnWhatsApp,
                  tooltip: 'Share Live on WhatsApp',
                  child: const Icon(Icons.chat_bubble, color: Colors.white),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.small(
                  heroTag: 'recenter_btn',
                  backgroundColor: AppColors.cardBg,
                  onPressed: controller.recenterCamera,
                  tooltip: 'Recenter on My Location',
                  child: const Icon(Icons.my_location, color: AppColors.primary),
                ),
              ],
            ),
          ),

          // ── 4. Bottom Information & Sharing Card ───
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _LocationInfoCard(sos: sos, locationCtrl: controller),
          ),
        ],
      ),
    );
  }
}

class _LocationInfoCard extends StatelessWidget {
  final SosController sos;
  final LocationController locationCtrl;
  const _LocationInfoCard({required this.sos, required this.locationCtrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Live status badge
          Obx(() => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: sos.isActive.value ? Colors.redAccent : AppColors.liveGreen,
                    ),
                  ),
                  Text(
                    sos.isActive.value
                        ? 'EMERGENCY SOS ACTIVE · ${sos.elapsedTime.value}'
                        : 'Real-time GPS Active',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: sos.isActive.value ? Colors.redAccent : AppColors.liveGreen,
                    ),
                  ),
                ],
              )),

          const SizedBox(height: 6),
          Text(
            'Your coordinates update continuously for maximum safety.',
            style: Theme.of(context).textTheme.bodySmall,
          ),

          const SizedBox(height: 16),

          // WhatsApp Share Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: locationCtrl.shareLocationOnWhatsApp,
              icon: const Icon(Icons.chat_outlined, color: Colors.white, size: 20),
              label: Text(
                'Share Live Location on WhatsApp',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // If SOS is active, show Stop button
          Obx(() {
            if (!sos.isActive.value) return const SizedBox.shrink();
            return SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                onPressed: sos.stopSos,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Stop SOS Sharing',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
