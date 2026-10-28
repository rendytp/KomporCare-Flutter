import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Hasil geocoding balik (koordinat -> alamat) dari OpenStreetMap Nominatim.
class ReverseResult {
  ReverseResult({required this.fullAddress, required this.city, this.postalCode});

  final String fullAddress;
  final String city;
  final String? postalCode;
}

/// Hasil pencarian tempat.
class PlaceHit {
  PlaceHit({required this.name, required this.lat, required this.lng});

  final String name;
  final double lat;
  final double lng;
}

/// Layanan geocoding gratis (OpenStreetMap Nominatim). Tanpa API key.
/// Kebijakan Nominatim: maksimal ~1 permintaan/detik dan wajib User-Agent;
/// karena itu pemanggil memakai debounce. Untuk produksi sebaiknya pakai
/// layanan geocoding sendiri/berbayar.
class GeoService {
  GeoService._();
  static final GeoService instance = GeoService._();

  static const _host = 'nominatim.openstreetmap.org';
  static const _headers = {
    'User-Agent': 'KomporCare/1.0 (aplikasi servis kompor)',
    'Accept': 'application/json',
  };

  Future<ReverseResult?> reverse(double lat, double lng) async {
    try {
      final uri = Uri.https(_host, '/reverse', {
        'format': 'jsonv2',
        'lat': '$lat',
        'lon': '$lng',
        'zoom': '18',
        'addressdetails': '1',
        'accept-language': 'id',
      });
      final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (json['error'] != null) return null;

      final a = (json['address'] as Map?)?.cast<String, dynamic>() ?? {};
      String? pick(List<String> keys) {
        for (final k in keys) {
          final v = a[k];
          if (v is String && v.trim().isNotEmpty) return v.trim();
        }
        return null;
      }

      final road = pick(['road', 'pedestrian', 'footway', 'path']);
      final number = pick(['house_number']);
      final parts = <String>[
        if (road != null) (number != null ? '$road No. $number' : road),
        if (pick(['neighbourhood', 'hamlet', 'quarter']) != null)
          pick(['neighbourhood', 'hamlet', 'quarter'])!,
        if (pick(['village', 'suburb']) != null) pick(['village', 'suburb'])!,
        if (pick(['city_district', 'district']) != null) pick(['city_district', 'district'])!,
      ];

      var full = parts.join(', ');
      if (full.isEmpty) {
        // fallback: nama tempat / display_name tanpa negara
        full = ((json['name'] as String?) ?? '').trim();
        if (full.isEmpty) {
          full = ((json['display_name'] as String?) ?? '').split(',').take(3).join(',').trim();
        }
      }

      final city = pick(['city', 'town', 'municipality', 'county', 'regency', 'state_district']) ?? '';

      return ReverseResult(
        fullAddress: full,
        city: city,
        postalCode: pick(['postcode']),
      );
    } on TimeoutException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<PlaceHit>> search(String query) async {
    try {
      final uri = Uri.https(_host, '/search', {
        'format': 'jsonv2',
        'q': query,
        'countrycodes': 'id',
        'limit': '6',
        'accept-language': 'id',
      });
      final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return [];
      final list = jsonDecode(res.body) as List;
      return list.map((e) {
        final m = e as Map<String, dynamic>;
        return PlaceHit(
          name: (m['display_name'] as String?) ?? '',
          lat: double.parse('${m['lat']}'),
          lng: double.parse('${m['lon']}'),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }
}
