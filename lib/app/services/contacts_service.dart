// ─────────────────────────────────────────────
//  contacts_service.dart
//  API calls for Safety Circle (trusted contacts)
// ─────────────────────────────────────────────
import 'package:dio/dio.dart';
import 'api_service.dart';

class ContactsService {
  final ApiService _api;
  ContactsService(this._api);

  /// Fetch all contacts in the user's safety circle
  /// GET /contacts
  Future<Response> getContacts() => _api.dio.get('/contacts');

  /// Add a new contact to the safety circle
  /// POST /contacts
  Future<Response> addContact({
    required String name,
    required String phone,
    required String relation,
  }) {
    return _api.dio.post('/contacts', data: {
      'name': name,
      'phone': phone,
      'relation': relation,
    });
  }

  /// Remove a contact from the safety circle
  /// DELETE /contacts/{contact_id}
  Future<Response> deleteContact(String contactId) {
    return _api.dio.delete('/contacts/$contactId');
  }
}
