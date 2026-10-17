// ─────────────────────────────────────────────
//  safety_circle_view.dart
//  Shows the user's trusted contacts list and
//  allows adding contacts with Name, Phone, Email & Relation dropdown.
// ─────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../controllers/contacts_controller.dart';
import '../../models/contact_model.dart';
import '../../theme/app_colors.dart';

class SafetyCircleView extends GetView<ContactsController> {
  const SafetyCircleView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Safety Circle'),
        actions: [
          IconButton(
            tooltip: 'Add Trusted Contact',
            icon: const Icon(Icons.person_add_rounded, color: AppColors.primary),
            onPressed: () => _showAddContactSheet(context),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_rounded, color: AppColors.primary, size: 30),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trusted Guardians & Contacts',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 15),
                        ),
                        Text(
                          'When SOS is triggered, your live GPS coordinates, interactive map, and address are automatically emailed & texted to them.',
                          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Contact list
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.contacts.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }
              if (controller.contacts.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.group_add_outlined, size: 68, color: AppColors.textHint),
                        const SizedBox(height: 14),
                        Text('No contacts in your Safety Circle',
                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 6),
                        Text(
                          'Add family members or close friends with their phone and email to receive instant emergency SOS alerts.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 12),
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton.icon(
                          onPressed: () => _showAddContactSheet(context),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add Trusted Contact'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: controller.contacts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _ContactTile(
                  contact: controller.contacts[i],
                  onDelete: () => controller.deleteContact(controller.contacts[i].id),
                ).animate(delay: Duration(milliseconds: i * 50)).fadeIn().slideX(begin: 0.05),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddContactSheet(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: Text('Add Contact', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white)),
      ),
    );
  }

  void _showAddContactSheet(BuildContext context) {
    Get.bottomSheet(
      _AddContactSheet(controller: controller),
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
    );
  }
}

// ── Single contact tile ──────────────────────
class _ContactTile extends StatelessWidget {
  final ContactModel contact;
  final VoidCallback onDelete;
  const _ContactTile({required this.contact, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar circle with initials
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.2),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
            ),
            child: Center(
              child: Text(
                contact.initials,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Name, relation, phone, email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      contact.name,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 15),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        contact.relation,
                        style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.phone_rounded, color: AppColors.textSecondary, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      contact.phone,
                      style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                if (contact.email != null && contact.email!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.mail_outline_rounded, color: Colors.cyanAccent, size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          contact.email!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.cyanAccent),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Call button
          IconButton(
            tooltip: 'Call Contact',
            icon: const Icon(Icons.call_rounded, color: AppColors.success),
            onPressed: () async {
              final uri = Uri.parse('tel:${contact.phone}');
              if (await canLaunchUrl(uri)) launchUrl(uri);
            },
          ),

          // Delete menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textHint),
            color: AppColors.cardBg,
            onSelected: (v) {
              if (v == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                  SizedBox(width: 8),
                  Text('Remove', style: TextStyle(color: AppColors.error)),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Add contact bottom sheet with Dropdown ────
class _AddContactSheet extends StatelessWidget {
  final ContactsController controller;
  const _AddContactSheet({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sheet handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              const Icon(Icons.person_add_rounded, color: AppColors.primary, size: 24),
              const SizedBox(width: 10),
              Text(
                'Add Trusted Contact',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Enter contact details. Emails will receive emergency live map snapshots & GPS links.',
            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),

          // Name field
          TextFormField(
            onChanged: (v) => controller.nameInput.value = v,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Full Name *',
              hintText: 'e.g. Maya Roy',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 14),

          // Phone field
          TextFormField(
            keyboardType: TextInputType.phone,
            onChanged: (v) => controller.phoneInput.value = v,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Phone Number *',
              hintText: 'e.g. +91 9876543210',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 14),

          // Email field
          TextFormField(
            keyboardType: TextInputType.emailAddress,
            onChanged: (v) => controller.emailInput.value = v,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Email Address (for Resend SOS)',
              hintText: 'e.g. guardian@example.com',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 14),

          // Relationship Dropdown
          Obx(() => DropdownButtonFormField<String>(
                value: controller.relationInput.value,
                dropdownColor: AppColors.inputBg,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Relationship *',
                  prefixIcon: Icon(Icons.people_outline_rounded),
                ),
                items: ContactsController.availableRelationships
                    .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(r, style: const TextStyle(color: Colors.white)),
                        ))
                    .toList(),
                onChanged: (v) => controller.relationInput.value = v ?? 'Family',
              )),
          const SizedBox(height: 22),

          Obx(() => SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: controller.isLoading.value ? null : controller.addContact,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: controller.isLoading.value
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'Add to Safety Circle',
                          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              )),
        ],
      ),
    );
  }
}
