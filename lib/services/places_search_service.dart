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
  static const String _apiKey = 'AIzaSyAbS02DKq5kL1nN5cNIHBtluCrvSGr633c';

  String _sessionToken = '';

  void startNewSession() {
    _sessionToken = DateTime.now().microsecondsSinceEpoch.toString();
  }

  Future<List<PlaceSearchResult>> searchPlaces(
    String query, {
    double? nearLat,
    double? nearLng,
    String? countryCode, // e.g. HK
  }) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    if (_sessionToken.isEmpty) {
      startNewSession();
    }

    final uri = Uri.parse('https://places.googleapis.com/v1/places:autocomplete');

    final Map<String, dynamic> body = {
      'input': q,
      'sessionToken': _sessionToken,
      'languageCode': 'zh-Hant',
      'regionCode': 'HK',
      if (countryCode != null) 'includedRegionCodes': [countryCode.toUpperCase()],
      if (nearLat != null && nearLng != null)
        'locationBias': {
          'circle': {
            'center': {'latitude': nearLat, 'longitude': nearLng},
            'radius': 30000.0,
          }
        },
    };

    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': _apiKey,
        'X-Goog-FieldMask':
            'suggestions.placePrediction.placeId,'
            'suggestions.placePrediction.text.text,'
            'suggestions.placePrediction.structuredFormat.mainText.text,'
            'suggestions.placePrediction.structuredFormat.secondaryText.text,'
            'suggestions.placePrediction.types',
      },
      body: jsonEncode(body),
    );

    if (res.statusCode != 200) {
      print('[PlacesAutocomplete] ${res.statusCode} ${res.body}');
      return [];
    }

    final map = jsonDecode(res.body) as Map<String, dynamic>;
    final suggestions = (map['suggestions'] as List?) ?? [];

    return suggestions.map((s) {
      final p = (s as Map<String, dynamic>)['placePrediction'] as Map<String, dynamic>;

      final placeId = (p['placeId'] ?? '').toString();
      final mainText = (((p['structuredFormat'] ?? {})['mainText'] ?? {})['text'] ?? '')
          .toString();
      final secondaryText =
          (((p['structuredFormat'] ?? {})['secondaryText'] ?? {})['text'] ?? '')
              .toString();
      final fullText = (((p['text'] ?? {})['text']) ?? '').toString();
      final types = (p['types'] as List?)?.map((e) => e.toString()).toList() ?? const [];

      return PlaceSearchResult(
        placeId: placeId,
        shortName: mainText.isNotEmpty ? mainText : fullText,
        displayName: secondaryText.isNotEmpty
            ? '$mainText, $secondaryText'
            : (fullText.isNotEmpty ? fullText : mainText),
        type: types.isNotEmpty ? types.first : '',
      );
    }).where((e) => e.placeId.isNotEmpty).toList();
  }

  Future<PlaceSearchResult?> getPlaceDetails(String placeId) async {
    if (placeId.isEmpty) return null;

    final uri = Uri.parse('https://places.googleapis.com/v1/places/$placeId');

    final res = await http.get(
      uri,
      headers: {
        'X-Goog-Api-Key': _apiKey,
        'X-Goog-FieldMask':
            'id,displayName,formattedAddress,location,types,addressComponents',
      },
    );

    if (res.statusCode != 200) {
      print('[PlaceDetails] ${res.statusCode} ${res.body}');
      return null;
    }

    final m = jsonDecode(res.body) as Map<String, dynamic>;
    final loc = (m['location'] ?? {}) as Map<String, dynamic>;
    final lat = (loc['latitude'] as num?)?.toDouble();
    final lng = (loc['longitude'] as num?)?.toDouble();

    String? street;
    final comps = (m['addressComponents'] as List?) ?? [];
    for (final c in comps) {
      final cc = c as Map<String, dynamic>;
      final types = (cc['types'] as List?)?.map((e) => e.toString()).toList() ?? [];
      if (types.contains('route')) {
        street = (cc['longText'] ?? cc['shortText'] ?? '').toString().trim();
        break;
      }
    }

    final name = ((m['displayName'] ?? {})['text'] ?? '').toString();
    final formatted = (m['formattedAddress'] ?? '').toString();
    final types = (m['types'] as List?)?.map((e) => e.toString()).toList() ?? const [];

    return PlaceSearchResult(
      placeId: (m['id'] ?? placeId).toString(),
      shortName: name,
      displayName: formatted,
      lat: lat,
      lng: lng,
      type: types.isNotEmpty ? types.first : '',
      streetName: street,
    );
  }

  Future<String?> reverseGeocode(double lat, double lng) async {
    final uri = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json'
      '?latlng=$lat,$lng'
      '&key=$_apiKey'
      '&language=zh-Hant',
    );

    final res = await http.get(uri);
    if (res.statusCode != 200) {
      debugPrint('[ReverseGeocode] ${res.statusCode} ${res.body}');
      return null;
    }

    final m = jsonDecode(res.body) as Map<String, dynamic>;
    final results = (m['results'] as List?) ?? [];
    if (results.isEmpty) return null;

    return (results.first as Map<String, dynamic>)['formatted_address']
        ?.toString();
  }
}