// ─────────────────────────────────────────────
//  contacts_controller.dart
//  CRUD for the Safety Circle trusted contacts
//  (Name, Phone, Email & Relationship dropdown).
// ─────────────────────────────────────────────
import 'package:get/get.dart';
import 'package:dio/dio.dart';
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

  @override
  void onInit() {
    super.onInit();
    fetchContacts();
  }

  // ── Fetch ────────────────────────────────────

  Future<void> fetchContacts() async {
    isLoading.value = true;
    try {
      final resp = await _service.getContacts();
      final list = resp.data as List? ?? [];
      contacts.value = list
          .map((e) => ContactModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      errorMsg.value = e.message ?? 'Failed to load contacts';
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
      _clearForm();
      Get.back(); // close add-contact bottom sheet
      Get.snackbar(
        '✅ Contact Added',
        '${c.name} added to your Safety Circle. SOS alerts will be sent to them.',
      );
    } on DioException catch (e) {
      Get.snackbar('Error', e.message ?? 'Could not add contact');
    } finally {
      isLoading.value = false;
    }
  }

  // ── Delete ───────────────────────────────────

  Future<void> deleteContact(String contactId) async {
    try {
      await _service.deleteContact(contactId);
      contacts.removeWhere((c) => c.id == contactId);
      Get.snackbar('Removed', 'Contact removed from Safety Circle');
    } catch (_) {
      Get.snackbar('Error', 'Could not remove contact');
    }
  }

  void _clearForm() {
    nameInput.value     = '';
    phoneInput.value    = '';
    emailInput.value    = '';
    relationInput.value = 'Family';
  }
}
