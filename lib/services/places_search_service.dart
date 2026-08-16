import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class PlaceSearchResult {
  final String placeId;
  final String shortName;
  final String displayName;
  final double? lat;
  final double? lng;
  final String type;
  final String? streetName;

  PlaceSearchResult({
    required this.placeId,
    required this.shortName,
    required this.displayName,
    this.lat,
    this.lng,
    this.type = '',
    this.streetName,
  });
}

class PlacesSearchService {
  static const String _photonBaseUrl = 'https://photon.komoot.io';
  final Map<String, PlaceSearchResult> _resultCache = {};

  void startNewSession() => _resultCache.clear();

  Future<List<PlaceSearchResult>> searchPlaces(
    String query, {
    double? nearLat,
    double? nearLng,
    String? countryCode, // e.g. HK
  }) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    final queryParameters = <String, String>{
      'q': q,
      'limit': '8',
      'lang': 'en',
      if (nearLat != null) 'lat': nearLat.toString(),
      if (nearLng != null) 'lon': nearLng.toString(),
      if (countryCode != null && countryCode.toLowerCase() == 'hk')
        'bbox': '113.825,22.140,114.440,22.571',
    };
    final uri = Uri.parse('$_photonBaseUrl/api')
        .replace(queryParameters: queryParameters);
    try {
      final res = await http.get(uri);
      if (res.statusCode != 200) {
        debugPrint('[PhotonSearch] ${res.statusCode} ${res.body}');
        return [];
      }

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final features = (body['features'] as List?) ?? const [];
      final results = features
          .map((item) => _resultFromFeature(item as Map<String, dynamic>))
          .whereType<PlaceSearchResult>()
          .toList();

      _resultCache.addEntries(
        results.map((result) => MapEntry(result.placeId, result)),
      );
      return results;
    } catch (e) {
      debugPrint('[PhotonSearch] Exception: $e');
      return [];
    }
  }

  Future<PlaceSearchResult?> getPlaceDetails(String placeId) async {
    return _resultCache[placeId];
  }

  Future<String?> reverseGeocode(double lat, double lng) async {
    final uri = Uri.parse('$_photonBaseUrl/reverse').replace(
      queryParameters: {
        'lat': lat.toString(),
        'lon': lng.toString(),
        'limit': '1',
        'lang': 'en',
      },
    );

    try {
      final res = await http.get(uri);
      debugPrint('[ReverseGeocode] HTTP ${res.statusCode}');
      if (res.statusCode != 200) {
        debugPrint('[ReverseGeocode] Error body: ${res.body}');
        return null;
      }

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final features = (body['features'] as List?) ?? const [];
      if (features.isEmpty) return null;

      final result = _resultFromFeature(
        features.first as Map<String, dynamic>,
      );
      final address = result?.displayName;
      debugPrint('[ReverseGeocode] Address: $address');
      return address;
    } catch (e) {
      debugPrint('[ReverseGeocode] Exception: $e');
      return null;
    }
  }

  PlaceSearchResult? _resultFromFeature(Map<String, dynamic> feature) {
    final properties =
        (feature['properties'] as Map<String, dynamic>?) ?? const {};
    final geometry = (feature['geometry'] as Map<String, dynamic>?) ?? const {};
    final coordinates = (geometry['coordinates'] as List?) ?? const [];
    if (coordinates.length < 2) return null;

    final name = (properties['name'] ?? properties['street'] ?? '').toString();
    final street = properties['street']?.toString();
    final addressParts = <String>[
      if (name.isNotEmpty) name,
      if (street != null && street.isNotEmpty && street != name) street,
      if (properties['housenumber'] != null)
        properties['housenumber'].toString(),
      if (properties['district'] != null) properties['district'].toString(),
      if (properties['city'] != null) properties['city'].toString(),
      if (properties['state'] != null) properties['state'].toString(),
      if (properties['country'] != null) properties['country'].toString(),
    ];
    final osmType = (properties['osm_type'] ?? '').toString();
    final osmId = (properties['osm_id'] ?? '').toString();
    final placeId = '$osmType$osmId';
    if (placeId.isEmpty) return null;

    return PlaceSearchResult(
      placeId: placeId,
      shortName: name.isNotEmpty
          ? name
          : (addressParts.isNotEmpty ? addressParts.first : ''),
      displayName: addressParts.toSet().join(', '),
      lat: (coordinates[1] as num?)?.toDouble(),
      lng: (coordinates[0] as num?)?.toDouble(),
      type: (properties['osm_value'] ?? '').toString(),
      streetName: street,
    );
  }
}
