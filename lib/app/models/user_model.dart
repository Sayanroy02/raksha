// ─────────────────────────────────────────────
//  user_model.dart
//  Represents a logged-in user returned by
//  /auth/me or embedded in JWT responses.
// ─────────────────────────────────────────────
import 'dart:convert';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? avatarUrl;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id:        json['_id']       as String? ?? json['id'] as String? ?? '',
        name:      json['name']      as String? ?? '',
        email:     json['email']     as String? ?? '',
        phone:     json['phone']     as String? ?? '',
        avatarUrl: json['avatar_url'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'avatar_url': avatarUrl,
      };

  /// Serialize to a JSON string for storage
  String toJsonString() => jsonEncode(toJson());

  /// Deserialize from a stored JSON string
  factory UserModel.fromJsonString(String s) =>
      UserModel.fromJson(jsonDecode(s) as Map<String, dynamic>);

  /// Helper — first name only (for greeting "Hello, Priya 👋")
  String get firstName => name.split(' ').first;
}
