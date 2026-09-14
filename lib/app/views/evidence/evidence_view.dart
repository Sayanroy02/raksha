// ─────────────────────────────────────────────
//  evidence_view.dart
//  Evidence Capture screen — Photo / Video / Audio
//  tabs with camera preview and saved evidence list.
// ─────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_colors.dart';

class EvidenceView extends StatelessWidget {
  const EvidenceView({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedTab = 0.obs; // 0=Photo, 1=Video, 2=Audio
    final tabs = ['Photo', 'Video', 'Audio'];

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(title: const Text('Evidence Capture')),
      body: Column(
        children: [
          // ── Tab selector ─────────────────────
          Obx(() => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: List.generate(tabs.length, (i) {
                final isSelected = selectedTab.value == i;
                return GestureDetector(
                  onTap: () => selectedTab.value = i,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.divider,
                      ),
                    ),
                    child: Text(
                      tabs[i],
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }),
            ),
          )),

          // ── Camera / Recorder area ───────────
          Expanded(
            child: Obx(() {
              return Column(
                children: [
                  // Camera preview placeholder
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            selectedTab.value == 2
                                ? Icons.mic_rounded
                                : Icons.camera_alt_outlined,
                            size: 72,
                            color: AppColors.textHint,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            selectedTab.value == 0
                                ? 'Tap to capture photo'
                                : selectedTab.value == 1
                                    ? 'Tap to record video'
                                    : 'Tap to record audio',
                            style: GoogleFonts.poppins(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Capture photos or videos of\n'
                            'suspicious activity, harassment\n'
                            'or any emergency situation.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: AppColors.textHint,
                              fontSize: 12,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Capture button
                          GestureDetector(
                            onTap: () => Get.snackbar(
                              'Camera',
                              'Camera permission required. '
                                  'Please implement camera plugin.',
                            ),
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.primary, width: 3),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primary,
                                  ),
                                  child: Icon(
                                    selectedTab.value == 2
                                        ? Icons.mic_rounded
                                        : Icons.camera_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 300.ms),
                  ),

                  const SizedBox(height: 16),

                  // ── Saved Evidence row ───────────
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.folder_outlined,
                              color: AppColors.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text('Saved Evidence',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white)),
                          ),
                          const Icon(Icons.chevron_right,
                              color: AppColors.textHint),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
