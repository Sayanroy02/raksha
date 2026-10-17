// ─────────────────────────────────────────────
//  geoapify_service.dart
//  Geoapify Geolocation Services:
//  • Reverse Geocoding (Lat/Lng -> Formatted Address)
//  • IP Geolocation (Instant fallback when GPS satellites unavailable)
//  • Nearby Safe Places (Police stations, Hospitals)
//  • Map Tile URLs (OSM Bright & Dark Matter for flutter_map)
//  • Static Map Generator
// ─────────────────────────────────────────────

import 'package:dio/dio.dart';
import '../utils/constants.dart';

class GeoapifyAddress {
  final String formatted;
  final String street;
  final String suburb;
  final String city;
  final String state;
  final String postcode;
  final String country;
  final double lat;
  final double lon;

  const GeoapifyAddress({
    required this.formatted,
    this.street = '',
    this.suburb = '',
    this.city = '',
    this.state = '',
    this.postcode = '',
    this.country = '',
    required this.lat,
    required this.lon,
  });

  factory GeoapifyAddress.fromGeoapifyJson(Map<String, dynamic> json, double fallbackLat, double fallbackLon) {
    return GeoapifyAddress(
      formatted: json['formatted'] as String? ?? '$fallbackLat, $fallbackLon',
      street: json['street'] as String? ?? '',
      suburb: json['suburb'] as String? ?? '',
      city: json['city'] as String? ?? json['town'] as String? ?? '',
      state: json['state'] as String? ?? '',
      postcode: json['postcode'] as String? ?? '',
      country: json['country'] as String? ?? 'India',
      lat: (json['lat'] as num?)?.toDouble() ?? fallbackLat,
      lon: (json['lon'] as num?)?.toDouble() ?? fallbackLon,
    );
  }
}

class GeoapifyService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
  ));

  String get _apiKey => AppConstants.geoapifyApiKey;

  /// Returns tile URL template for flutter_map raster tile layer
  String getTileUrlTemplate({bool dark = true}) {
    if (_apiKey.isNotEmpty) {
      final style = dark ? 'dark-matter' : 'osm-bright';
      return 'https://maps.geoapify.com/v1/tile/$style/{z}/{x}/{y}.png?apiKey=$_apiKey';
    }
    // Reliable OpenStreetMap fallback if no custom Geoapify key entered
    return dark
        ? 'https://basemaps.cartocdn.com/rastertiles/dark_all/{z}/{x}/{y}.png'
        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  }

  /// Generates a static map preview image URL
  String getStaticMapUrl(double lat, double lon, {int width = 600, int height = 350, int zoom = 15}) {
    if (_apiKey.isNotEmpty) {
      return 'https://maps.geoapify.com/v1/staticmap?'
          'style=osm-bright&width=$width&height=$height'
          '&center=lonlat:$lon,$lat&zoom=$zoom'
          '&marker=lonlat:$lon,$lat;color:%23ff0055;size:large'
          '&apiKey=$_apiKey';
    }
    return 'https://static-maps.yandex.ru/1.x/?ll=$lon,$lat&z=$zoom&l=map&pt=$lon,$lat,pm2rdm';
  }

  /// Reverse geocode Lat/Lng into a human-readable street address
  Future<GeoapifyAddress> reverseGeocode(double lat, double lon) async {
    if (_apiKey.isNotEmpty) {
      try {
        final resp = await _dio.get(
          'https://api.geoapify.com/v1/geocode/reverse',
          queryParameters: {
            'lat': lat,
            'lon': lon,
            'format': 'json',
            'apiKey': _apiKey,
          },
        );

        if (resp.statusCode == 200) {
          final results = resp.data['results'] as List? ?? [];
          if (results.isNotEmpty) {
            return GeoapifyAddress.fromGeoapifyJson(
              results.first as Map<String, dynamic>,
              lat,
              lon,
            );
          }
        }
      } catch (_) {}
    }

    // Try backend proxy fallback
    try {
      final backendResp = await _dio.get(
        '${AppConstants.apiBaseUrl}/places/reverse-geocode',
        queryParameters: {'lat': lat, 'lng': lon},
      );
      if (backendResp.statusCode == 200 && backendResp.data is Map) {
        final d = backendResp.data as Map<String, dynamic>;
        return GeoapifyAddress(
          formatted: d['formatted'] as String? ?? '$lat, $lon',
          street: d['street'] as String? ?? '',
          suburb: d['suburb'] as String? ?? '',
          city: d['city'] as String? ?? '',
          state: d['state'] as String? ?? '',
          postcode: d['postcode'] as String? ?? '',
          country: d['country'] as String? ?? '',
          lat: lat,
          lon: lon,
        );
      }
    } catch (_) {}

    return GeoapifyAddress(
      formatted: '${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}',
      city: 'Current Location',
      country: 'India',
      lat: lat,
      lon: lon,
    );
  }

  /// Fast IP-based Geolocation when GPS has no lock
  Future<Map<String, dynamic>> getIpLocation() async {
    if (_apiKey.isNotEmpty) {
      try {
        final resp = await _dio.get(
          'https://api.geoapify.com/v1/ipinfo',
          queryParameters: {'apiKey': _apiKey},
        );
        if (resp.statusCode == 200) {
          final d = resp.data as Map<String, dynamic>;
          final loc = d['location'] as Map<String, dynamic>?;
          return {
            'lat': (loc?['latitude'] as num?)?.toDouble() ?? 26.7271,
            'lng': (loc?['longitude'] as num?)?.toDouble() ?? 88.3953,
            'city': d['city']?['name'] as String? ?? 'Siliguri',
            'country': d['country']?['name'] as String? ?? 'India',
          };
        }
      } catch (_) {}
    }

    return {'lat': 26.7271, 'lng': 88.3953, 'city': 'Siliguri', 'country': 'India'};
  }

  /// Fetch nearby emergency places (police, hospitals)
  Future<List<Map<String, dynamic>>> getNearbyPlaces({
    required double lat,
    required double lon,
    String category = 'service.police',
    int radiusMeters = 3000,
  }) async {
    if (_apiKey.isNotEmpty) {
      try {
        final resp = await _dio.get(
          'https://api.geoapify.com/v2/places',
          queryParameters: {
            'categories': category,
            'filter': 'circle:$lon,$lat,$radiusMeters',
            'bias': 'proximity:$lon,$lat',
            'limit': 20,
            'apiKey': _apiKey,
          },
        );

        if (resp.statusCode == 200) {
          final features = resp.data['features'] as List? ?? [];
          return features.map((f) {
            final props = (f as Map<String, dynamic>)['properties'] as Map<String, dynamic>? ?? {};
            final geom = f['geometry'] as Map<String, dynamic>? ?? {};
            final coords = geom['coordinates'] as List? ?? [lon, lat];
            return {
              'name': props['name'] ?? props['formatted'] ?? 'Emergency Service',
              'address': props['formatted'] ?? props['address_line2'] ?? '',
              'lat': (coords.length > 1 ? coords[1] : lat) as double,
              'lng': (coords.isNotEmpty ? coords[0] : lon) as double,
              'distance': props['distance'] ?? 0,
            };
          }).toList();
        }
      } catch (_) {}
    }

    return [];
  }
}
