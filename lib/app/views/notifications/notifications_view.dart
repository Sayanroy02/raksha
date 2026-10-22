// ─────────────────────────────────────────────
//  notifications_view.dart
//  Notifications history & emergency alert preferences.
// ─────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/alert_notification_service.dart';
import '../../theme/app_colors.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  bool _emailAlertsEnabled = true;
  bool _audioSirenEnabled = true;
  bool _smsFallbackEnabled = true;

  final List<Map<String, dynamic>> _alerts = [
    {
      'title': 'Resend Email Notification Active',
      'detail': 'Emergency live map snapshots and GPS coordinates will be emailed to your trusted circle.',
      'time': 'Just now',
      'icon': Icons.mark_email_read_rounded,
      'color': Colors.cyanAccent,
    },
    {
      'title': 'Geoapify Geolocation Synchronized',
      'detail': 'Reverse geocoding and raster visual map tiles initialized successfully.',
      'time': '5 mins ago',
      'icon': Icons.map_rounded,
      'color': AppColors.primary,
    },
    {
      'title': 'Guardian QR Pairing Ready',
      'detail': 'Your unique Guardian tracking link is active and ready to pair with family devices.',
      'time': '15 mins ago',
      'icon': Icons.qr_code_2_rounded,
      'color': AppColors.liveGreen,
    },
    {
      'title': 'AI Threat Engine Armed',
      'detail': 'Surveillance for sudden motion, high decibels and isolated risk zones is standing by.',
      'time': '1 hour ago',
      'icon': Icons.security_rounded,
      'color': Colors.amberAccent,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Emergency Notification Preferences',
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Preference switches
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  value: _emailAlertsEnabled,
                  activeColor: AppColors.primary,
                  title: Text('Resend Email SOS Alerts', style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
                  subtitle: Text('Email live GPS link to safety circle contacts',
                      style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 11)),
                  onChanged: (v) => setState(() => _emailAlertsEnabled = v),
                ),
                const Divider(color: AppColors.divider, height: 1),
                SwitchListTile(
                  value: _audioSirenEnabled,
                  activeColor: AppColors.primary,
                  title: Text('Emergency Siren Broadcast', style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
                  subtitle: Text('Allow guardians to monitor live audio stream',
                      style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 11)),
                  onChanged: (v) => setState(() => _audioSirenEnabled = v),
                ),
                const Divider(color: AppColors.divider, height: 1),
                SwitchListTile(
                  value: _smsFallbackEnabled,
                  activeColor: AppColors.primary,
                  title: Text('WhatsApp & SMS Live Sharing', style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
                  subtitle: Text('Generate instant one-tap messaging links',
                      style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 11)),
                  onChanged: (v) => setState(() => _smsFallbackEnabled = v),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          Text(
            'Recent Safety & Dispatch Activity',
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Obx(() {
            final liveAlerts = AlertNotificationService().notificationsHistory;
            final allAlerts = [...liveAlerts, ..._alerts];

            return Column(
              children: allAlerts.map((a) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (a['color'] as Color).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(a['icon'] as IconData, color: a['color'] as Color, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a['title'] as String,
                              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              a['detail'] as String,
                              style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              a['time'] as String,
                              style: GoogleFonts.poppins(color: AppColors.textHint, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }
}
