// ─────────────────────────────────────────────
//  register_view.dart
//  New account registration screen.
// ─────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/auth_controller.dart';
import '../../theme/app_colors.dart';

class RegisterView extends GetView<AuthController> {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    final obscure = true.obs;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Join Raksha+',
                      style: Theme.of(context).textTheme.headlineMedium)
                  .animate()
                  .fadeIn(duration: 400.ms),
              const SizedBox(height: 4),
              Text('Create your account to stay safe',
                      style: Theme.of(context).textTheme.bodyMedium)
                  .animate(delay: 100.ms)
                  .fadeIn(),
              const SizedBox(height: 32),

              // Name
              _label('Full Name'),
              const SizedBox(height: 8),
              TextFormField(
                onChanged: (v) => controller.nameInput.value = v,
                decoration: const InputDecoration(
                  hintText: 'Enter your full name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ).animate(delay: 120.ms).fadeIn().slideY(begin: 0.1),
              const SizedBox(height: 18),

              // Email
              _label('Email'),
              const SizedBox(height: 8),
              TextFormField(
                keyboardType: TextInputType.emailAddress,
                onChanged: (v) => controller.emailInput.value = v,
                decoration: const InputDecoration(
                  hintText: 'Enter your email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ).animate(delay: 160.ms).fadeIn().slideY(begin: 0.1),
              const SizedBox(height: 18),

              // Phone
              _label('Phone Number'),
              const SizedBox(height: 8),
              TextFormField(
                keyboardType: TextInputType.phone,
                onChanged: (v) => controller.phoneInput.value = v,
                decoration: const InputDecoration(
                  hintText: 'Enter your phone number',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1),
              const SizedBox(height: 18),

              // Password
              _label('Password'),
              const SizedBox(height: 8),
              Obx(() => TextFormField(
                    obscureText: obscure.value,
                    onChanged: (v) => controller.passwordInput.value = v,
                    decoration: InputDecoration(
                      hintText: 'Create a password',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(obscure.value
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () => obscure.toggle(),
                      ),
                    ),
                  )).animate(delay: 240.ms).fadeIn().slideY(begin: 0.1),
              const SizedBox(height: 12),

              // Error
              Obx(() => controller.errorMsg.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(controller.errorMsg.value,
                          style: const TextStyle(color: AppColors.error)),
                    )
                  : const SizedBox.shrink()),

              const SizedBox(height: 28),

              // Submit
              Obx(() => ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : controller.register,
                    child: controller.isLoading.value
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Create Account'),
                  )).animate(delay: 280.ms).fadeIn(),

              const SizedBox(height: 20),

              // Login link
              Center(
                child: TextButton(
                  onPressed: () => Get.back(),
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.poppins(
                          fontSize: 14, color: AppColors.textSecondary),
                      children: const [
                        TextSpan(text: 'Already have an account? '),
                        TextSpan(
                          text: 'Login',
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

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary),
      );
}
