// ─────────────────────────────────────────────
//  contact_model.dart
//  Represents a single trusted contact in the
//  user's Safety Circle with Name, Phone, Email & Relation.
// ─────────────────────────────────────────────

class ContactModel {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String relation; // e.g. "Family", "Friend", "Parent", "Partner", "Other"

  const ContactModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.relation,
  });

  factory ContactModel.fromJson(Map<String, dynamic> json) => ContactModel(
        id: json['_id'] as String? ?? json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        email: json['email'] as String?,
        relation: json['relationship'] as String? ?? json['relation'] as String? ?? 'Family',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        if (email != null && email!.isNotEmpty) 'email': email,
        'relation': relation,
        'relationship': relation,
      };

  /// First letter(s) used as avatar initials
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name.substring(0, name.length.clamp(0, 2)).toUpperCase() : 'C';
  }
}
