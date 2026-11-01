import 'dart:math' as math;

import '../models/gunung_data.dart';
import 'browser_location.dart';
import 'ranah_api_client.dart';

typedef AdministrativeAreaLookup = Future<BrowserAdministrativeArea?> Function(
  BrowserLocation location,
);

final _defaultLookup = OpenStreetMapAreaLookup();

Future<BrowserAdministrativeArea?> lookupBrowserAdministrativeArea(
  BrowserLocation location,
) => _defaultLookup.call(location);

/// One reverse lookup per coordinate for this browser session.
/// Coordinates are sent only after the user explicitly requests identification.
class OpenStreetMapAreaLookup {
  OpenStreetMapAreaLookup({RanahApiClient? client})
    : _client = client ?? RanahApiClient();

  final RanahApiClient _client;
  final Map<String, BrowserAdministrativeArea?> _cache = {};
  final Map<String, Future<BrowserAdministrativeArea?>> _inFlight = {};
  DateTime? _lastRequestAt;

  Future<BrowserAdministrativeArea?> call(BrowserLocation location) {
    final key =
        '${location.latitude.toStringAsFixed(5)},'
        '${location.longitude.toStringAsFixed(5)}';
    if (_cache.containsKey(key)) return Future.value(_cache[key]);
    return _inFlight.putIfAbsent(key, () => _lookup(key, location));
  }

  Future<BrowserAdministrativeArea?> _lookup(
    String key,
    BrowserLocation location,
  ) async {
    try {
      final previous = _lastRequestAt;
      if (previous != null) {
        final wait =
            const Duration(seconds: 1) - DateTime.now().difference(previous);
        if (wait > Duration.zero) await Future<void>.delayed(wait);
      }
      _lastRequestAt = DateTime.now();
      final response = await _client.getJson(
        'peta/alamat',
        queryParameters: {
          'latitude': location.latitude.toString(),
          'longitude': location.longitude.toString(),
        },
      );
      if (response['success'] != true || response['data'] is! Map) {
        throw const FormatException('Format data wilayah tidak dikenal.');
      }
      final data = Map<String, dynamic>.from(response['data'] as Map);
      final rawAddress = data['address'];
      if (rawAddress is! Map) {
        throw const FormatException('Alamat dari layanan peta tidak valid.');
      }
      final address = Map<String, dynamic>.from(rawAddress);
      final province = _firstText(address, const [
        'state',
        'province',
        'region',
      ]);
      final street = _firstText(address, const [
        'road',
        'pedestrian',
        'residential',
        'footway',
      ]);
      final locality = _firstText(address, const [
        'suburb',
        'village',
        'neighbourhood',
        'hamlet',
      ]);
      final regency = _firstText(address, const [
        'city',
        'town',
        'county',
        'municipality',
      ]);
      final result = BrowserAdministrativeArea(
        province: province,
        regency: regency,
        locality: locality,
        street: street,
        village: _firstText(address, const ['village']),
        district: _firstText(address, const ['district']),
        displayName: _nullableText(data['display_name']),
        source: _nullableText(data['sumber']),
        retrievedAt: DateTime.tryParse(
          data['waktu_pengambilan']?.toString() ?? '',
        ),
      );
      if ([
        province,
        street,
        locality,
        regency,
        result.displayName,
      ].every((value) => value == null || value.isEmpty)) {
        _cache[key] = null;
        return null;
      }
      _cache[key] = result;
      return result;
    } finally {
      _inFlight.remove(key);
    }
  }

  void close() => _client.close();
}

List<NearbyVolcano> volcanoesForProvince({
  required List<GunungRecord> records,
  required String province,
  required BrowserLocation origin,
}) {
  final key = _provinceKey(province);
  if (key == null) return const [];
  final matching = records.where(
    (record) => _provinceKey(record.provinsi) == key,
  );
  final nearby = matching.map((record) {
    final verified =
        record.statusValidasiKoordinat?.toLowerCase() == 'terverifikasi';
    final latitude = record.latitude;
    final longitude = record.longitude;
    double? distanceKm;
    if (verified &&
        latitude != null &&
        longitude != null &&
        latitude.isFinite &&
        longitude.isFinite &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180) {
      distanceKm = _haversineKm(
        origin.latitude,
        origin.longitude,
        latitude,
        longitude,
      );
    }
    return NearbyVolcano(record: record, distanceKm: distanceKm);
  }).toList();
  nearby.sort((a, b) {
    if (a.distanceKm == null && b.distanceKm != null) return 1;
    if (a.distanceKm != null && b.distanceKm == null) return -1;
    if (a.distanceKm != null && b.distanceKm != null) {
      return a.distanceKm!.compareTo(b.distanceKm!);
    }
    return a.record.nama.toLowerCase().compareTo(b.record.nama.toLowerCase());
  });
  return List.unmodifiable(nearby);
}

class NearbyVolcano {
  const NearbyVolcano({required this.record, required this.distanceKm});
  final GunungRecord record;
  final double? distanceKm;
}

double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const radius = 6371.0088;
  final dLat = _radians(lat2 - lat1);
  final dLon = _radians(lon2 - lon1);
  final sinLat = math.sin(dLat / 2);
  final sinLon = math.sin(dLon / 2);
  final a =
      sinLat * sinLat +
      math.cos(_radians(lat1)) * math.cos(_radians(lat2)) * sinLon * sinLon;
  return 2 * radius * _asin(_sqrt(a.clamp(0.0, 1.0).toDouble()));
}

double _radians(double degrees) => degrees * 0.017453292519943295;
double _asin(double value) => math.asin(value);
double _sqrt(double value) => math.sqrt(value);

String? _firstText(Map<String, dynamic> values, List<String> keys) {
  for (final key in keys) {
    final value = values[key]?.toString().trim();
    if (value != null && value.isNotEmpty) return value;
  }
  return null;
}

String? _nullableText(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

String? _provinceKey(String? value) {
  if (value == null) return null;
  var normalized = value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  normalized = normalized.replaceFirst(RegExp(r'^(provinsi|province)\s+'), '');
  const aliases = {
    'nanggroe aceh darussalam': 'aceh',
    'sumbar': 'sumatera barat',
    'west sumatra': 'sumatera barat',
    'sumatera barat': 'sumatera barat',
    'north sumatra': 'sumatera utara',
    'sumatera utara': 'sumatera utara',
    'south sumatra': 'sumatera selatan',
    'sumatera selatan': 'sumatera selatan',
    'jambi': 'jambi',
    'riau': 'riau',
    'bengkulu': 'bengkulu',
    'lampung': 'lampung',
    'riau islands': 'kepulauan riau',
    'kepulauan riau': 'kepulauan riau',
    'bangka belitung islands': 'kepulauan bangka belitung',
    'bangka belitung': 'kepulauan bangka belitung',
    'kepulauan bangka belitung': 'kepulauan bangka belitung',
    'west java': 'jawa barat',
    'jawa barat': 'jawa barat',
    'central java': 'jawa tengah',
    'jawa tengah': 'jawa tengah',
    'east java': 'jawa timur',
    'jawa timur': 'jawa timur',
    'banten': 'banten',
    'dki jakarta': 'jakarta',
    'daerah khusus ibukota jakarta': 'jakarta',
    'jakarta raya': 'jakarta',
    'jakarta': 'jakarta',
    'di yogyakarta': 'yogyakarta',
    'daerah istimewa yogyakarta': 'yogyakarta',
    'special region of yogyakarta': 'yogyakarta',
    'bali': 'bali',
    'west nusa tenggara': 'nusa tenggara barat',
    'nusa tenggara barat': 'nusa tenggara barat',
    'east nusa tenggara': 'nusa tenggara timur',
    'nusa tenggara timur': 'nusa tenggara timur',
    'west kalimantan': 'kalimantan barat',
    'kalimantan barat': 'kalimantan barat',
    'central kalimantan': 'kalimantan tengah',
    'kalimantan tengah': 'kalimantan tengah',
    'south kalimantan': 'kalimantan selatan',
    'kalimantan selatan': 'kalimantan selatan',
    'east kalimantan': 'kalimantan timur',
    'kalimantan timur': 'kalimantan timur',
    'north kalimantan': 'kalimantan utara',
    'kalimantan utara': 'kalimantan utara',
    'maluku': 'maluku',
    'north sulawesi': 'sulawesi utara',
    'sulawesi utara': 'sulawesi utara',
    'central sulawesi': 'sulawesi tengah',
    'sulawesi tengah': 'sulawesi tengah',
    'south sulawesi': 'sulawesi selatan',
    'sulawesi selatan': 'sulawesi selatan',
    'southeast sulawesi': 'sulawesi tenggara',
    'sulawesi tenggara': 'sulawesi tenggara',
    'west sulawesi': 'sulawesi barat',
    'sulawesi barat': 'sulawesi barat',
    'gorontalo': 'gorontalo',
    'north maluku': 'maluku utara',
    'maluku utara': 'maluku utara',
    'west papua': 'papua barat',
    'papua barat': 'papua barat',
    'southwest papua': 'papua barat daya',
    'papua barat daya': 'papua barat daya',
    'central papua': 'papua tengah',
    'papua tengah': 'papua tengah',
    'highland papua': 'papua pegunungan',
    'papua pegunungan': 'papua pegunungan',
    'south papua': 'papua selatan',
    'papua selatan': 'papua selatan',
    'papua': 'papua',
    'aceh': 'aceh',
    'daerah istimewa aceh': 'aceh',
  };
  return aliases[normalized] ?? normalized;
}
