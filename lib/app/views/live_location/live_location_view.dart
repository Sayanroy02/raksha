// ─────────────────────────────────────────────
//  live_location_view.dart
//  Interactive visual map with real-time GPS coordinates,
//  pinpoint marker, accuracy indicator, WhatsApp share,
//  and SOS live sharing controls powered by Geoapify & flutter_map.
// ─────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/location_controller.dart';
import '../../controllers/sos_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/raksha_visual_map.dart';

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
            tooltip: 'Refresh Danger Zones',
            icon: const Icon(Icons.refresh_rounded, color: Colors.amberAccent),
            onPressed: () {
              controller.loadDangerZones();
              Get.snackbar('Synchronizing', 'Refreshing active danger zones from admin...', snackPosition: SnackPosition.TOP);
            },
          ),
          IconButton(
            tooltip: 'Location History',
            icon: const Icon(Icons.history_rounded, color: Colors.white),
            onPressed: () => _showHistorySheet(context),
          ),
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
          // ── 1. Interactive Visual Map ─────────────
          Obx(() {
            final point = controller.currentPoint.value;
            final isSos = sos.isActive.value;
            final addr = controller.formattedAddress.value;
            final acc = controller.currentAccuracy.value;

            return RakshaVisualMap(
              center: point,
              zoom: 16.5,
              showUserPulse: true,
              isEmergency: isSos,
              addressText: addr,
              accuracyMeters: acc,
              polylinePoints: controller.polyline.toList(),
              dangerZones: controller.dangerZones.toList(),
              onRecenter: controller.recenterCamera,
            );
          }),

          // ── Danger Zones Active Overlay Chip ──
          Positioned(
            top: 14,
            left: 14,
            child: Obx(() {
              final count = controller.dangerZones.length;
              if (count == 0) return const SizedBox.shrink();
              return GestureDetector(
                onTap: () => _showDangerZonesSheet(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.redAccent, width: 1.5),
                    boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 6)],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.amberAccent, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '$count Danger Zone${count > 1 ? "s" : ""} on Map',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 18),
                    ],
                  ),
                ),
              );
            }),
          ),

          // ── 2. Bottom Information & Sharing Card ───
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

  void _showDangerZonesSheet(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: const BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                    const SizedBox(width: 10),
                    Text(
                      'Admin Danger Zones & Roads',
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    controller.loadDangerZones();
                    Get.back();
                  },
                  child: const Text('Refresh', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Obx(() {
              final zones = controller.dangerZones;
              if (zones.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text('No active danger zones reported in this area.',
                        style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13)),
                  ),
                );
              }
              return ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: zones.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final z = zones[i];
                    final isRoad = z.zoneType == 'ROAD_LINE';
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.scaffoldBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: z.severity == 'HIGH'
                              ? Colors.redAccent.withValues(alpha: 0.5)
                              : Colors.orangeAccent.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isRoad ? Icons.alt_route_rounded : Icons.radio_button_checked_rounded,
                            color: z.severity == 'HIGH' ? Colors.redAccent : Colors.orangeAccent,
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  z.title,
                                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                Text(
                                  '${isRoad ? "Corridor Road" : "${z.radiusM.toInt()}m Circle Radius"} • ${z.description}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          ElevatedButton(
                            onPressed: () {
                              controller.focusDangerZone(z);
                              Get.back();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text('Fly to', style: GoogleFonts.poppins(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showHistorySheet(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: const BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.timeline_rounded, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Text(
                      'Location Movement History',
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Obx(() => controller.locationHistory.isNotEmpty
                    ? TextButton(
                        onPressed: controller.clearHistory,
                        child: const Text('Clear', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                      )
                    : const SizedBox.shrink()),
              ],
            ),
            const SizedBox(height: 6),
            Obx(() => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: controller.isUserMoving.value
                        ? Colors.blueAccent.withValues(alpha: 0.15)
                        : Colors.greenAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Status: ${controller.movementStatus.value}',
                    style: TextStyle(
                      color: controller.isUserMoving.value ? Colors.blueAccent : Colors.greenAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )),
            const SizedBox(height: 16),
            Obx(() {
              if (controller.locationHistory.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.place_outlined, color: AppColors.textHint, size: 40),
                        const SizedBox(height: 10),
                        Text(
                          'You are at a static location.\nAs you move, each new location checkpoint will be recorded here automatically.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: controller.locationHistory.length,
                  separatorBuilder: (_, __) => const Divider(color: AppColors.divider),
                  itemBuilder: (_, i) {
                    final item = controller.locationHistory[i];
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: i == 0
                            ? AppColors.primary.withValues(alpha: 0.25)
                            : Colors.white10,
                        child: Icon(
                          i == 0 ? Icons.my_location : Icons.location_on_outlined,
                          size: 16,
                          color: i == 0 ? AppColors.primary : AppColors.textSecondary,
                        ),
                      ),
                      title: Text(
                        item.address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                      subtitle: Text(
                        '${item.timestamp.toLocal().toString().split('.')[0]} • (${item.latitude.toStringAsFixed(4)}, ${item.longitude.toStringAsFixed(4)})',
                        style: const TextStyle(color: AppColors.textHint, fontSize: 11),
                      ),
                    );
                  },
                ),
              );
            }),
          ],
        ),
      ),
      isScrollControlled: true,
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
                        : 'Real-time GPS Active (Geoapify Powered)',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: sos.isActive.value ? Colors.redAccent : AppColors.liveGreen,
                    ),
                  ),
                ],
              )),

          const SizedBox(height: 6),
          Obx(() => Text(
                locationCtrl.formattedAddress.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              )),

          // Nearest Emergency Services directly in Google Maps
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: OutlinedButton.icon(
                    onPressed: () => sos.openNearestInGoogleMaps('police'),
                    icon: const Icon(Icons.local_police_rounded, color: Colors.blueAccent, size: 18),
                    label: Text(
                      'Nearest Police',
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.blueAccent.withValues(alpha: 0.5)),
                      backgroundColor: Colors.blueAccent.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: OutlinedButton.icon(
                    onPressed: () => sos.openNearestInGoogleMaps('hospital'),
                    icon: const Icon(Icons.local_hospital_rounded, color: Colors.redAccent, size: 18),
                    label: Text(
                      'Nearest Hospital',
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.5)),
                      backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Action Buttons: WhatsApp Share & Quick SOS Email
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: locationCtrl.shareLocationOnWhatsApp,
                    icon: const Icon(Icons.chat_outlined, color: Colors.white, size: 18),
                    label: Text(
                      'WhatsApp',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
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
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => _showEmailDialog(context),
                    icon: const Icon(Icons.mail_outline_rounded, color: Colors.white, size: 18),
                    label: Text(
                      'Email Alert',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
            ],
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

  void _showEmailDialog(BuildContext context) {
    final emailTextCtrl = TextEditingController();
    Get.defaultDialog(
      title: 'Send Location Email Alert',
      titleStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
      backgroundColor: AppColors.cardBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      content: Column(
        children: [
          Text(
            'Deliver live GPS coordinates, interactive map link, and formatted address via Resend.',
            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: emailTextCtrl,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Recipient email address',
              hintStyle: const TextStyle(color: AppColors.textHint),
              prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary),
              filled: true,
              fillColor: AppColors.scaffoldBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
      textConfirm: 'Send via Resend',
      confirmTextColor: Colors.white,
      buttonColor: AppColors.primary,
      onConfirm: () {
        final email = emailTextCtrl.text.trim();
        Get.back();
        sos.sendCustomEmailAlert(email);
      },
      textCancel: 'Cancel',
      cancelTextColor: AppColors.textHint,
    );
  }
}
