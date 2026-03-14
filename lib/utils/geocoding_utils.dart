import 'dart:convert';
import 'dart:io';

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Simple geocoding via the Google Geocoding REST API.
/// Uses dart:io HttpClient so no native plugin registration is needed.
class GeocodingUtils {
  static const _apiKey = String.fromEnvironment(
    'MAPS_API_KEY',
  );

  static final Map<String, String> _reverseCache = <String, String>{};
  static final Map<String, Future<String?>> _reverseInFlight =
      <String, Future<String?>>{};

  static bool get _hasApiKey => _apiKey.trim().isNotEmpty;

  /// Geocode an address string and return the first result as a [LatLng].
  /// Returns null if no results found or on error.
  static Future<LatLng?> geocodeAddress(String address) async {
    final query = address.trim();
    if (query.isEmpty) return null;

    try {
      if (_hasApiKey) {
        final fromGoogle = await _geocodeWithGoogle(query);
        if (fromGoogle != null) return fromGoogle;
      }

      final fromNominatim = await _geocodeWithNominatim(query);
      if (fromNominatim != null) return fromNominatim;

      return null;
    } catch (_) {
      return null;
    }
  }

  /// Reverse geocode coordinates into a human-readable place label.
  ///
  /// Results are cached by rounded coordinate cell to reduce API calls for
  /// frequently refreshed activity points.
  static Future<String?> reverseGeocodeCoordinates(
    double latitude,
    double longitude, {
    int precision = 4,
  }) {
    if (!latitude.isFinite || !longitude.isFinite) {
      return Future.value(null);
    }

    final latCell = latitude.toStringAsFixed(precision);
    final lngCell = longitude.toStringAsFixed(precision);
    final cacheKey = '$latCell,$lngCell';

    final cached = _reverseCache[cacheKey];
    if (cached != null) {
      return Future.value(cached);
    }

    final pending = _reverseInFlight[cacheKey];
    if (pending != null) {
      return pending;
    }

    final future = _resolveReverseLabel(latitude, longitude)
        .then((label) {
          if (label != null && label.trim().isNotEmpty) {
            _reverseCache[cacheKey] = label;
          }
          return label;
        })
        .whenComplete(() {
          _reverseInFlight.remove(cacheKey);
        });

    _reverseInFlight[cacheKey] = future;
    return future;
  }

  static Future<String?> _resolveReverseLabel(double lat, double lng) async {
    try {
      if (_hasApiKey) {
        final fromGoogle = await _reverseWithGoogle(lat, lng);
        if (fromGoogle != null && fromGoogle.isNotEmpty) return fromGoogle;
      }

      final fromNominatim = await _reverseWithNominatim(lat, lng);
      if (fromNominatim != null && fromNominatim.isNotEmpty) {
        return fromNominatim;
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> _reverseWithGoogle(double lat, double lng) async {
    final uri = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json'
      '?latlng=$lat,$lng&key=$_apiKey',
    );

    final json = await _getJson(uri);
    if (json == null) return null;

    final status = (json['status'] as String?)?.toUpperCase();
    if (status != 'OK') return null;

    final results = json['results'] as List<dynamic>?;
    if (results == null || results.isEmpty) return null;

    final first = results.first;
    if (first is! Map<String, dynamic>) return null;
    final address = first['formatted_address'] as String?;
    return address?.trim().isEmpty ?? true ? null : address!.trim();
  }

  static Future<String?> _reverseWithNominatim(double lat, double lng) async {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse'
      '?lat=$lat&lon=$lng&format=jsonv2&zoom=18&addressdetails=1',
    );

    final json = await _getJson(uri);
    if (json is! Map<String, dynamic>) return null;

    final address = json['address'];
    if (address is Map<String, dynamic>) {
      // 1. Prioritize POIs over general street names.
      final poiKeys = [
        'amenity', 'building', 'shop', 'office', 'leisure',
        'tourism', 'historic', 'club', 'healthcare',
      ];
      String? poiName;
      for (final key in poiKeys) {
        if (address[key] != null && address[key].toString().trim().isNotEmpty) {
          poiName = address[key].toString().trim();
          break;
        }
      }

      final parts = <String>[
        ?poiName,
        (address['road'] as String?)?.trim() ?? '',
        (address['suburb'] as String?)?.trim() ??
            (address['neighbourhood'] as String?)?.trim() ?? '',
        (address['city'] as String?)?.trim() ??
            (address['town'] as String?)?.trim() ??
            (address['village'] as String?)?.trim() ?? '',
      ].where((value) => value.isNotEmpty).toList();

      if (parts.isNotEmpty) {
        // If we have a POI, and it's redundant with the road or suburb, we might just show POI, Road.
        // For now, joining them cleanly is best.
        return parts.join(', ');
      }
    }

    final display = (json['display_name'] as String?)?.trim();
    if (display == null || display.isEmpty) return null;
    return display;
  }

  static Future<LatLng?> _geocodeWithGoogle(String query) async {
    final encoded = Uri.encodeComponent(query);
    final uri = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json'
      '?address=$encoded&key=$_apiKey',
    );

    final json = await _getJson(uri);
    if (json == null) return null;

    final status = (json['status'] as String?)?.toUpperCase();
    if (status != 'OK') return null;

    final results = json['results'] as List<dynamic>?;
    if (results == null || results.isEmpty) return null;

    final geometry = results.first['geometry'] as Map<String, dynamic>?;
    final location = geometry?['location'] as Map<String, dynamic>?;
    final lat = (location?['lat'] as num?)?.toDouble();
    final lng = (location?['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;

    return LatLng(lat, lng);
  }

  static Future<LatLng?> _geocodeWithNominatim(String query) async {
    final encoded = Uri.encodeComponent(query);
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/search'
      '?q=$encoded&format=jsonv2&limit=1',
    );

    final json = await _getJson(uri);
    if (json is! List || json.isEmpty) return null;

    final first = json.first;
    if (first is! Map<String, dynamic>) return null;

    final lat = double.tryParse('${first['lat']}');
    final lng = double.tryParse('${first['lon']}');
    if (lat == null || lng == null) return null;

    return LatLng(lat, lng);
  }

  static Future<dynamic> _getJson(Uri uri) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      request.headers.set(
        HttpHeaders.userAgentHeader,
        'relapse_flutter/1.0 (contact: support@relapse.app)',
      );
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');

      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final body = await response.transform(utf8.decoder).join();
      return jsonDecode(body);
    } finally {
      client.close(force: true);
    }
  }
}
