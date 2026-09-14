// ─────────────────────────────────────────────
//  onboarding_view.dart
//  Shown only on first launch.
//  PageView with 3 slides matching the UI design
//  (dark background, pink accents, "Get Started"
//  button on the last slide).
// ─────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';

// ── Data for each slide ──────────────────────
class _Slide {
  final String title;
  final String subtitle;
  final IconData icon;
  const _Slide(this.title, this.subtitle, this.icon);
}

const _slides = [
  _Slide(
    'Your Safety\nOur Priority',
    'Raksha+ helps you stay safe with real-time location, emergency alerts, AI threat detection and more.',
    Icons.shield_rounded,
  ),
  _Slide(
    'Emergency SOS\nIn Seconds',
    'Hold the SOS button for 3 seconds to instantly alert your trusted contacts and share your location.',
    Icons.sos_rounded,
  ),
  _Slide(
    'AI Powered\nThreat Detection',
    'Our AI scans your surroundings for potential threats using audio analysis and location risk scoring.',
    Icons.radar_rounded,
  ),
];

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final _controller = PageController();
  int _currentPage  = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      Get.offAllNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Skip button ─────────────────────
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () => Get.offAllNamed(AppRoutes.login),
                child: Text(
                  'Skip',
                  style: GoogleFonts.poppins(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            ),

            // ── Slides ──────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => _SlideWidget(slide: _slides[i]),
              ),
            ),

            // ── Dots indicator ──────────────────
            SmoothPageIndicator(
              controller: _controller,
              count: _slides.length,
              effect: WormEffect(
                activeDotColor: AppColors.primary,
                dotColor: AppColors.divider,
                dotHeight: 8,
                dotWidth: 8,
              ),
            ),

            const SizedBox(height: 32),

            // ── CTA button ──────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ElevatedButton(
                onPressed: _next,
                child: Text(
                  _currentPage == _slides.length - 1
                      ? 'Get Started'
                      : 'Next',
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Login link ──────────────────────
            TextButton(
              onPressed: () => Get.offAllNamed(AppRoutes.login),
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.poppins(
                      fontSize: 14, color: AppColors.textSecondary),
                  children: [
                    const TextSpan(text: 'Already have an account? '),
                    TextSpan(
                      text: 'Login',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Single slide widget ──────────────────────
class _SlideWidget extends StatelessWidget {
  final _Slide slide;
  const _SlideWidget({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Glowing icon
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: AppColors.pinkGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: Icon(slide.icon, size: 70, color: Colors.white),
          )
              .animate()
              .scale(duration: 500.ms, curve: Curves.elasticOut),

          const SizedBox(height: 40),

          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.3,
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

          const SizedBox(height: 16),

          Text(
            slide.subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ).animate().fadeIn(delay: 350.ms, duration: 500.ms),
        ],
      ),
    );
  }
}
