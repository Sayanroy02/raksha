// ─────────────────────────────────────────────
//  contact_model.dart
//  Represents a single trusted contact in the
//  user's Safety Circle.
// ─────────────────────────────────────────────

class ContactModel {
  final String id;
  final String name;
  final String phone;
  final String relation; // e.g. "Family", "Friend", "Primary Contact"

  const ContactModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.relation,
  });

  factory ContactModel.fromJson(Map<String, dynamic> json) => ContactModel(
        id:       json['_id']      as String? ?? json['id'] as String? ?? '',
        name:     json['name']     as String? ?? '',
        phone:    json['phone']    as String? ?? '',
        relation: json['relation'] as String? ?? 'Contact',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'relation': relation,
      };

  /// First letter(s) used as avatar initials
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
  }
}
