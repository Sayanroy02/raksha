// ─────────────────────────────────────────────
//  location_history_view.dart
//  Shows a timeline of visited locations with
//  date-filter tabs at the top.
// ─────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../controllers/location_controller.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bottom_nav_bar.dart';

class LocationHistoryView extends GetView<LocationController> {
  const LocationHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    // Date tabs — Today plus last 3 days
    final dates = List.generate(4, (i) => DateTime.now().subtract(Duration(days: i)));
    final selectedDate = 0.obs;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      bottomNavigationBar: const RakshaBottomNav(currentIndex: 2),
      appBar: AppBar(title: const Text('Location History')),
      body: Column(
        children: [

          // ── Date filter tabs ─────────────────
          SizedBox(
            height: 44,
            child: Obx(() => ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: dates.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final isSelected = selectedDate.value == i;
                final label = i == 0
                    ? 'Today'
                    : DateFormat('MMM d').format(dates[i]);
                return GestureDetector(
                  onTap: () => selectedDate.value = i,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.divider,
                      ),
                    ),
                    child: Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            )),
          ),

          const SizedBox(height: 16),

          // ── Timeline list ────────────────────
          Expanded(
            child: Obx(() {
              if (controller.isLoadingHistory.value) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              // Demo data while real API is wired up
              final demoLogs = [
                ('06:45 PM', 'Home', 'Siliguri, WB'),
                ('06:32 PM', 'City Centre Mall', 'Siliguri, WB'),
                ('04:12 PM', 'Ramakrishna Mission', 'Friguri, WB'),
                ('12:28 PM', 'College', 'Siliguri, WB'),
              ];

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: demoLogs.length,
                itemBuilder: (_, i) => _TimelineTile(
                  time:    demoLogs[i].$1,
                  place:   demoLogs[i].$2,
                  address: demoLogs[i].$3,
                  isLast:  i == demoLogs.length - 1,
                ).animate(delay: Duration(milliseconds: i * 80)).fadeIn().slideX(begin: 0.05),
              );
            }),
          ),

          // ── View Full Map button ─────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: OutlinedButton.icon(
              onPressed: () => Get.toNamed(AppRoutes.liveLocation),
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: const Text('View Full Map'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final String time;
  final String place;
  final String address;
  final bool   isLast;
  const _TimelineTile({
    required this.time,
    required this.place,
    required this.address,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line + dot
          SizedBox(
            width: 30,
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.divider,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    time,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.textHint),
                  ),
                  Text(
                    place,
                    style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                  Text(
                    address,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.textSecondary),
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
