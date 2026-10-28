// ─────────────────────────────────────────────
//  contacts_controller.dart
//  CRUD for the Safety Circle trusted contacts
//  (Name, Phone, Email & Relationship dropdown).
//  Includes offline local storage persistence fallback.
// ─────────────────────────────────────────────
import 'dart:convert';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/contact_model.dart';
import '../services/contacts_service.dart';

class ContactsController extends GetxController {
  final ContactsService _service;
  ContactsController(this._service);

  // ── State ────────────────────────────────────
  final RxList<ContactModel> contacts   = <ContactModel>[].obs;
  final RxBool               isLoading  = false.obs;
  final RxString             errorMsg   = ''.obs;

  // Add-contact form fields
  final RxString nameInput     = ''.obs;
  final RxString phoneInput    = ''.obs;
  final RxString emailInput    = ''.obs;
  final RxString relationInput = 'Family'.obs;

  static const List<String> availableRelationships = [
    'Family',
    'Friend',
    'Parent',
    'Sibling',
    'Partner',
    'Colleague',
    'Neighbor',
    'Other',
  ];

  static const String _kOfflineContactsKey = 'raksha_offline_contacts_v1';

  @override
  void onInit() {
    super.onInit();
    _loadLocalContacts();
    fetchContacts();
  }

  Future<void> _loadLocalContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kOfflineContactsKey);
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List;
        final loaded = list
            .map((e) => ContactModel.fromJson(e as Map<String, dynamic>))
            .toList();
        if (loaded.isNotEmpty && contacts.isEmpty) {
          contacts.assignAll(loaded);
        }
      }
    } catch (_) {}
  }

  Future<void> _saveLocalContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = contacts.map((c) => c.toJson()).toList();
      await prefs.setString(_kOfflineContactsKey, jsonEncode(list));
    } catch (_) {}
  }

  // ── Fetch ────────────────────────────────────

  Future<void> fetchContacts() async {
    isLoading.value = true;
    try {
      final resp = await _service.getContacts();
      final list = resp.data as List? ?? [];
      final loaded = list
          .map((e) => ContactModel.fromJson(e as Map<String, dynamic>))
          .toList();
      contacts.assignAll(loaded);
      await _saveLocalContacts();
    } on DioException catch (e) {
      errorMsg.value = e.message ?? 'Failed to load contacts';
      await _loadLocalContacts();
    } catch (_) {
      await _loadLocalContacts();
    } finally {
      isLoading.value = false;
    }
  }

  // ── Add ──────────────────────────────────────

  Future<void> addContact() async {
    final name = nameInput.value.trim();
    final phone = phoneInput.value.trim();
    final email = emailInput.value.trim();
    final relation = relationInput.value.trim().isEmpty ? 'Family' : relationInput.value.trim();

    if (name.isEmpty || phone.isEmpty) {
      Get.snackbar('Validation Error', 'Name and phone number are required');
      return;
    }

    if (email.isNotEmpty && !GetUtils.isEmail(email)) {
      Get.snackbar('Invalid Email', 'Please enter a valid email address for SOS alerts');
      return;
    }

    isLoading.value = true;
    try {
      final resp = await _service.addContact(
        name: name,
        phone: phone,
        email: email.isNotEmpty ? email : null,
        relation: relation,
      );
      final c = ContactModel.fromJson(resp.data as Map<String, dynamic>);
      contacts.add(c);
      await _saveLocalContacts();
      _clearForm();
      Get.back(); // close add-contact bottom sheet
      Get.snackbar(
        '✅ Contact Added',
        '${c.name} added to your Safety Circle. SOS alerts will be sent to them.',
      );
    } catch (e) {
      // Offline fallback: save locally
      final fallbackId = 'contact_${DateTime.now().millisecondsSinceEpoch}';
      final c = ContactModel(
        id: fallbackId,
        name: name,
        phone: phone,
        email: email.isNotEmpty ? email : null,
        relation: relation,
      );
      contacts.add(c);
      await _saveLocalContacts();
      _clearForm();
      Get.back();
      Get.snackbar(
        'Contact Saved (Offline)',
        '${c.name} added to Safety Circle locally on this device.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ── Delete ───────────────────────────────────

  Future<void> deleteContact(String contactId) async {
    try {
      await _service.deleteContact(contactId);
    } catch (_) {}
    contacts.removeWhere((c) => c.id == contactId);
    await _saveLocalContacts();
    Get.snackbar('Removed', 'Contact removed from Safety Circle');
  }

  void _clearForm() {
    nameInput.value     = '';
    phoneInput.value    = '';
    emailInput.value    = '';
    relationInput.value = 'Family';
  }
}
