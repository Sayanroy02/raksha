// ─────────────────────────────────────────────
//  bottom_nav_bar.dart
//  Custom bottom navigation bar with 4 tabs:
//  Home · Map · History · Profile
//  Matches the dark design from the UI mockup.
// ─────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';

class RakshaBottomNav extends StatelessWidget {
  final int currentIndex;
  const RakshaBottomNav({super.key, required this.currentIndex});

  static const _items = [
    _NavItem(Icons.home_rounded,          'Home',    AppRoutes.home),
    _NavItem(Icons.map_rounded,           'Map',     AppRoutes.liveLocation),
    _NavItem(Icons.local_hospital_rounded,'Nearby',  AppRoutes.nearbyServices),
    _NavItem(Icons.person_outline_rounded,'Profile', AppRoutes.profile),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBg,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_items.length, (i) {
          final item     = _items[i];
          final isActive = i == currentIndex;
          return GestureDetector(
            onTap: () {
              if (!isActive) Get.offNamed(item.route);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.icon,
                  size: 24,
                  color: isActive ? AppColors.primary : AppColors.textHint,
                ),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isActive ? AppColors.primary : AppColors.textHint,
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                // Active dot indicator
                if (isActive) ...[
                  const SizedBox(height: 4),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String   label;
  final String   route;
  const _NavItem(this.icon, this.label, this.route);
}
