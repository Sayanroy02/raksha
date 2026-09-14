// ─────────────────────────────────────────────
//  login_view.dart
//  Email + password login screen.
//  Bound to AuthController via AuthBinding.
// ─────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/auth_controller.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';

class LoginView extends GetView<AuthController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    // Local TextEditingControllers bound to the GetX controller
    final emailCtrl    = TextEditingController();
    final passwordCtrl = TextEditingController();
    final obscure      = true.obs; // toggle password visibility

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Logo ────────────────────────────
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: AppColors.pinkGradient,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.shield_rounded,
                          size: 36, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    RichText(
                      text: TextSpan(children: [
                        TextSpan(
                          text: 'Raksha',
                          style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        TextSpan(
                          text: '+',
                          style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary),
                        ),
                      ]),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 500.ms),

              const SizedBox(height: 40),

              Text('Welcome Back',
                      style: Theme.of(context).textTheme.headlineMedium)
                  .animate()
                  .slideX(begin: -0.2, duration: 400.ms)
                  .fadeIn(),

              const SizedBox(height: 6),

              Text('Sign in to your account',
                      style: Theme.of(context).textTheme.bodyMedium)
                  .animate(delay: 100.ms)
                  .fadeIn(),

              const SizedBox(height: 36),

              // ── Email field ──────────────────────
              _buildLabel('Email'),
              const SizedBox(height: 8),
              TextFormField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                onChanged: (v) => controller.emailInput.value = v,
                decoration: const InputDecoration(
                  hintText: 'Enter your email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ).animate(delay: 150.ms).fadeIn().slideY(begin: 0.1),

              const SizedBox(height: 20),

              // ── Password field ───────────────────
              _buildLabel('Password'),
              const SizedBox(height: 8),
              Obx(() => TextFormField(
                    controller: passwordCtrl,
                    obscureText: obscure.value,
                    onChanged: (v) => controller.passwordInput.value = v,
                    decoration: InputDecoration(
                      hintText: 'Enter your password',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(obscure.value
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () => obscure.toggle(),
                      ),
                    ),
                  )).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1),

              const SizedBox(height: 12),

              // ── Error message ────────────────────
              Obx(() => controller.errorMsg.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        controller.errorMsg.value,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    )
                  : const SizedBox.shrink()),

              const SizedBox(height: 28),

              // ── Login button ─────────────────────
              Obx(() => ElevatedButton(
                    onPressed:
                        controller.isLoading.value ? null : controller.login,
                    child: controller.isLoading.value
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Login'),
                  )).animate(delay: 250.ms).fadeIn(),

              const SizedBox(height: 24),

              // ── Register link ────────────────────
              Center(
                child: TextButton(
                  onPressed: () => Get.toNamed(AppRoutes.register),
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.poppins(
                          fontSize: 14, color: AppColors.textSecondary),
                      children: [
                        const TextSpan(text: "Don't have an account? "),
                        const TextSpan(
                          text: 'Register',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
        text,
        style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary),
      );
}
