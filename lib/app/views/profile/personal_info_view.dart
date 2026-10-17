// ─────────────────────────────────────────────
//  personal_info_view.dart
//  Allows Raksha+ users to view and update their personal
//  profile and critical medical/emergency information.
//  Includes one-tap GPS address detection via Geoapify.
// ─────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';

import '../../controllers/auth_controller.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/geoapify_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_colors.dart';

class PersonalInfoView extends StatefulWidget {
  const PersonalInfoView({super.key});

  @override
  State<PersonalInfoView> createState() => _PersonalInfoViewState();
}

class _PersonalInfoViewState extends State<PersonalInfoView> {
  final AuthController auth = Get.find<AuthController>();
  final AuthService _authService = Get.find<AuthService>();
  final StorageService _storage = Get.find<StorageService>();
  final GeoapifyService _geoapify = GeoapifyService();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _medicalCtrl;
  late final TextEditingController _emergencyCtrl;
  late final TextEditingController _addressCtrl;

  String _selectedBloodGroup = 'O+';
  bool _isLoading = false;
  bool _isDetectingAddress = false;

  static const List<String> bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  @override
  void initState() {
    super.initState();
    final user = auth.user.value;
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _emailCtrl = TextEditingController(text: user?.email ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
    _medicalCtrl = TextEditingController(text: user?.medicalNotes ?? '');
    _emergencyCtrl = TextEditingController(text: user?.emergencyNotes ?? '');
    _addressCtrl = TextEditingController(text: user?.homeAddress ?? '');
    if (user?.bloodGroup != null && bloodGroups.contains(user!.bloodGroup)) {
      _selectedBloodGroup = user.bloodGroup!;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _medicalCtrl.dispose();
    _emergencyCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _detectAddressFromGps() async {
    setState(() => _isDetectingAddress = true);
    try {
      final pos = await Geolocator.getLastKnownPosition() ??
          await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 4),
            ),
          );

      final address = await _geoapify.reverseGeocode(pos.latitude, pos.longitude);
      _addressCtrl.text = address.formatted;
      Get.snackbar('📍 Address Detected', 'Fetched exact street address using Geoapify.');
    } catch (_) {
      Get.snackbar('Error', 'Could not fetch current GPS address.');
    } finally {
      if (mounted) setState(() => _isDetectingAddress = false);
    }
  }

  Future<void> _saveProfile() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    if (name.isEmpty || email.isEmpty || phone.isEmpty) {
      Get.snackbar('Validation', 'Name, email, and phone are required');
      return;
    }

    if (!GetUtils.isEmail(email)) {
      Get.snackbar('Validation', 'Please enter a valid email address');
      return;
    }

    setState(() => _isLoading = true);

    final updatePayload = {
      'name': name,
      'email': email,
      'phone': phone,
      'blood_group': _selectedBloodGroup,
      'medical_notes': _medicalCtrl.text.trim(),
      'emergency_notes': _emergencyCtrl.text.trim(),
      'home_address': _addressCtrl.text.trim(),
    };

    try {
      final resp = await _authService.updateProfile(updatePayload);
      if (resp.statusCode == 200) {
        final updatedUser = UserModel.fromJson(resp.data as Map<String, dynamic>);
        auth.user.value = updatedUser;
        await _storage.saveUserData(updatedUser.toJsonString());
      }
      Get.back();
      Get.snackbar('✅ Profile Saved', 'Personal information and emergency data updated successfully.');
    } catch (e) {
      // Offline fallback: save locally
      final curUser = auth.user.value;
      final localUser = UserModel(
        id: curUser?.id ?? 'user_local',
        name: name,
        email: email,
        phone: phone,
        bloodGroup: _selectedBloodGroup,
        medicalNotes: _medicalCtrl.text.trim(),
        emergencyNotes: _emergencyCtrl.text.trim(),
        homeAddress: _addressCtrl.text.trim(),
      );
      auth.user.value = localUser;
      await _storage.saveUserData(localUser.toJsonString());
      Get.back();
      Get.snackbar('✅ Saved Locally', 'Personal info saved to device.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Personal Information'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_rounded, color: AppColors.primary),
            onPressed: _isLoading ? null : _saveProfile,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Emergency Safety Profile',
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'This critical info will be shared with responders and trusted guardians in an emergency.',
              style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 22),

            // Full Name
            _buildField(label: 'Full Name *', controller: _nameCtrl, icon: Icons.person_outline),
            const SizedBox(height: 14),

            // Email Address
            _buildField(
              label: 'Email Address (for Resend SOS Alerts) *',
              controller: _emailCtrl,
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),

            // Phone
            _buildField(
              label: 'Primary Phone Number *',
              controller: _phoneCtrl,
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 14),

            // Blood Group Dropdown
            DropdownButtonFormField<String>(
              value: _selectedBloodGroup,
              dropdownColor: AppColors.inputBg,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Blood Group',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.bloodtype_outlined, color: Colors.redAccent),
                filled: true,
                fillColor: AppColors.cardBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
              ),
              items: bloodGroups
                  .map((bg) => DropdownMenuItem(value: bg, child: Text(bg, style: const TextStyle(color: Colors.white))))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedBloodGroup = v);
              },
            ),
            const SizedBox(height: 14),

            // Medical Notes
            _buildField(
              label: 'Medical Notes & Allergies',
              controller: _medicalCtrl,
              icon: Icons.medical_services_outlined,
              hint: 'e.g. Asthma, Penicillin allergy, Diabetic',
            ),
            const SizedBox(height: 14),

            // Emergency Notes
            _buildField(
              label: 'Emergency Instructions',
              controller: _emergencyCtrl,
              icon: Icons.notification_important_outlined,
              hint: 'e.g. Call my sister Maya first on her mobile',
            ),
            const SizedBox(height: 14),

            // Home Address with GPS Button
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    label: 'Primary Address',
                    controller: _addressCtrl,
                    icon: Icons.home_outlined,
                    hint: 'Your home / frequent safety location',
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Fill from GPS',
                  onPressed: _isDetectingAddress ? null : _detectAddressFromGps,
                  icon: _isDetectingAddress
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        )
                      : const Icon(Icons.my_location_rounded, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveProfile,
                icon: const Icon(Icons.save_rounded, color: Colors.white),
                label: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Save Personal Information',
                        style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.primary),
        filled: true,
        fillColor: AppColors.cardBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}
