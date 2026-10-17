// ─────────────────────────────────────────────
//  location_log_model.dart
//  A single location point shown in Location
//  History timeline.
// ─────────────────────────────────────────────

class LocationLogModel {
  final String id;
  final double latitude;
  final double longitude;
  final String address;    // Reverse-geocoded human-readable address
  final DateTime timestamp;

  const LocationLogModel({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.timestamp,
  });

  factory LocationLogModel.fromJson(Map<String, dynamic> json) =>
      LocationLogModel(
        id:        json['id'] ?? json['_id'] as String? ?? '',
        latitude:  (json['latitude']  as num?)?.toDouble() ?? 0.0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
        address:   json['address']   as String? ?? 'Unknown location',
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'latitude': latitude,
    'longitude': longitude,
    'address': address,
    'timestamp': timestamp.toIso8601String(),
  };
}
