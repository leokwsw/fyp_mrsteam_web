import 'dart:async';
import 'package:dio/dio.dart';

/// Represents a single search result from the places search API.
class PlaceSearchResult {
  final String displayName;
  final String shortName;
  final String type;
  final double lat;
  final double lng;

  PlaceSearchResult({
    required this.displayName,
    required this.shortName,
    required this.type,
    required this.lat,
    required this.lng,
  });
}

/// Service for searching places using the Nominatim (OpenStreetMap) API.
class PlacesSearchService {
  static final PlacesSearchService _instance = PlacesSearchService._internal();
  factory PlacesSearchService() => _instance;
  PlacesSearchService._internal();

  // ── DO NOT set User-Agent here ─────────────────────────────────────────
  // Browsers forbid overriding User-Agent via XMLHttpRequest.
  // The browser sends its own User-Agent automatically, which Nominatim accepts.
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://nominatim.openstreetmap.org',
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: {
      'Accept': 'application/json',
    },
  ));

  // ── Forward geocode (text → coordinates) ───────────────────────────────
  Future<List<PlaceSearchResult>> searchPlaces(
    String query, {
    double? nearLat,
    double? nearLng,
    String? countryCode,
    int limit = 8,
  }) async {
    if (query.trim().isEmpty) return [];

    try {
      final params = <String, dynamic>{
        'q': query.trim(),
        'format': 'json',
        'limit': limit,
        'addressdetails': 1,
      };

      if (countryCode != null && countryCode.isNotEmpty) {
        params['countrycodes'] = countryCode;
      }

      if (nearLat != null && nearLng != null) {
        params['viewbox'] =
            '${nearLng - 0.5},${nearLat + 0.5},${nearLng + 0.5},${nearLat - 0.5}';
        params['bounded'] = 0;
      }

      print('[PlacesSearch] Querying: "$query" params=$params');

      final response = await _dio.get(
        '/search',
        queryParameters: params,
        // NO User-Agent header — browser handles it automatically
        options: Options(
          headers: {
            'Accept-Language': 'en',
          },
        ),
      );

      print('[PlacesSearch] Status: ${response.statusCode}, '
          'results: ${(response.data is List) ? (response.data as List).length : 'N/A'}');

      if (response.data is List) {
        return (response.data as List).map<PlaceSearchResult>((item) {
          final full = item['display_name'] as String? ?? '';
          final parts = full.split(', ');
          final short = parts.take(3).join(', ');

          return PlaceSearchResult(
            displayName: full,
            shortName: short,
            type: _friendlyType(
              item['type'] as String?,
              item['class'] as String?,
            ),
            lat: double.tryParse(item['lat']?.toString() ?? '') ?? 0,
            lng: double.tryParse(item['lon']?.toString() ?? '') ?? 0,
          );
        }).toList();
      }

      print('[PlacesSearch] Unexpected response type: ${response.data.runtimeType}');
      return [];
    } on DioException catch (e) {
      print('[PlacesSearch] DioException: ${e.type} — ${e.message}');
      if (e.response != null) {
        print('[PlacesSearch] Response status: ${e.response?.statusCode}');
        print('[PlacesSearch] Response data: ${e.response?.data}');
      }
      return [];
    } catch (e, stack) {
      print('[PlacesSearch] Unexpected error: $e');
      print('[PlacesSearch] Stack: $stack');
      return [];
    }
  }

  // ── Reverse geocode (coordinates → address text) ───────────────────────
  Future<String?> reverseGeocode(double lat, double lng) async {
    try {
      final response = await _dio.get(
        '/reverse',
        queryParameters: {
          'lat': lat.toString(),
          'lon': lng.toString(),
          'format': 'json',
          'addressdetails': 1,
          'zoom': 18,
        },
        // NO User-Agent header
        options: Options(
          headers: {
            'Accept-Language': 'en',
          },
        ),
      );

      if (response.data != null && response.data['display_name'] != null) {
        return response.data['display_name'] as String;
      }
      return null;
    } on DioException catch (e) {
      print('[ReverseGeocode] DioException: ${e.type} — ${e.message}');
      return null;
    } catch (e) {
      print('[ReverseGeocode] Error: $e');
      return null;
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────
  String _friendlyType(String? type, String? cls) {
    final t = type ?? '';
    final c = cls ?? '';

    const map = {
      'school': '🏫 School',
      'university': '🎓 University',
      'college': '🎓 College',
      'kindergarten': '💒 Kindergarten',
      'building': '🏢 Building',
      'house': '🏠 Address',
      'residential': '🏠 Residential',
      'commercial': '🏢 Commercial',
      'industrial': '🏭 Industrial',
      'retail': '🏪 Retail',
      'restaurant': '🍽️ Restaurant',
      'cafe': '☕ Cafe',
      'fast_food': '🍔 Fast Food',
      'hospital': '🏥 Hospital',
      'clinic': '🏥 Clinic',
      'pharmacy': '💊 Pharmacy',
      'bus_stop': '🚌 Bus Stop',
      'station': '🚉 Station',
      'subway_entrance': '🚇 Subway',
      'park': '🌳 Park',
      'library': '📚 Library',
      'place_of_worship': '🛕 Place of Worship',
      'mall': '🛍️ Mall',
      'supermarket': '🛒 Supermarket',
      'bank': '🏦 Bank',
      'hotel': '🏨 Hotel',
      'cinema': '🎬 Cinema',
      'museum': '🏛️ Museum',
      'sports_centre': '🏟️ Sports Centre',
      'swimming_pool': '🏊 Swimming Pool',
      'road': '🛣️ Road',
      'street': '🛣️ Street',
      'suburb': '📍 Area',
      'city': '🏙️ City',
      'town': '🏘️ Town',
      'village': '🏘️ Village',
      'neighbourhood': '📍 Neighbourhood',
      'administrative': '📍 Area',
    };

    if (map.containsKey(t)) return map[t]!;
    if (map.containsKey(c)) return map[c]!;

    if (t.isNotEmpty) {
      return t
          .replaceAll('_', ' ')
          .split(' ')
          .map((w) =>
              w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
          .join(' ');
    }
    return '';
  }
}