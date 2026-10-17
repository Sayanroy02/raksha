// ─────────────────────────────────────────────
//  user_model.dart
//  Represents a logged-in user with personal
//  profile and medical/emergency information.
// ─────────────────────────────────────────────
import 'dart:convert';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? avatarUrl;
  final String? bloodGroup;
  final String? medicalNotes;
  final String? emergencyNotes;
  final String? homeAddress;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.avatarUrl,
    this.bloodGroup,
    this.medicalNotes,
    this.emergencyNotes,
    this.homeAddress,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['_id'] as String? ?? json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        avatarUrl: json['avatar_url'] as String?,
        bloodGroup: json['blood_group'] as String?,
        medicalNotes: json['medical_notes'] as String?,
        emergencyNotes: json['emergency_notes'] as String?,
        homeAddress: json['home_address'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (bloodGroup != null) 'blood_group': bloodGroup,
        if (medicalNotes != null) 'medical_notes': medicalNotes,
        if (emergencyNotes != null) 'emergency_notes': emergencyNotes,
        if (homeAddress != null) 'home_address': homeAddress,
      };

  /// Serialize to a JSON string for storage
  String toJsonString() => jsonEncode(toJson());

  /// Deserialize from a stored JSON string
  factory UserModel.fromJsonString(String s) =>
      UserModel.fromJson(jsonDecode(s) as Map<String, dynamic>);

  /// Helper — first name only (for greeting "Hello, Priya 👋")
  String get firstName => name.isNotEmpty ? name.split(' ').first : 'User';
}
