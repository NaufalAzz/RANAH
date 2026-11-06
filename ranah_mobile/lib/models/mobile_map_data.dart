import 'package:latlong2/latlong.dart';

const mobileRouteDisclaimer =
    'Simulasi Jalur Menuju Titik Kumpul — Bukan Jalur Evakuasi Resmi. Jalur mengikuti data jalan OpenStreetMap; keamanan jalur dan status tujuan belum diverifikasi.';

class MapAddress {
  const MapAddress({
    this.displayName,
    this.street,
    this.locality,
    this.district,
    this.regency,
    this.province,
    this.source,
    this.retrievedAt,
  });

  final String? displayName;
  final String? street;
  final String? locality;
  final String? district;
  final String? regency;
  final String? province;
  final String? source;
  final DateTime? retrievedAt;

  String get shortLabel => [street, locality, district, regency, province]
      .whereType<String>()
      .where((value) => value.trim().isNotEmpty)
      .toSet()
      .join(', ');

  factory MapAddress.fromEnvelope(Map<String, dynamic> envelope) {
    final data = envelope['data'];
    final rawAddress = data is Map ? data['address'] : null;
    if (envelope['success'] != true || data is! Map || rawAddress is! Map) {
      throw const FormatException('Respons alamat dari API tidak valid.');
    }
    final address = Map<String, dynamic>.from(rawAddress);
    return MapAddress(
      displayName: _text(data['display_name']),
      street: _first(address, const [
        'road',
        'pedestrian',
        'residential',
        'footway',
      ]),
      locality: _first(address, const [
        'suburb',
        'village',
        'neighbourhood',
        'hamlet',
      ]),
      district: _first(address, const ['district', 'city_district']),
      regency: _first(address, const [
        'city',
        'town',
        'county',
        'municipality',
      ]),
      province: _first(address, const ['state', 'province', 'region']),
      source: _text(data['sumber']),
      retrievedAt: DateTime.tryParse(
        data['waktu_pengambilan']?.toString() ?? '',
      ),
    );
  }
}

class MapOsmFeature {
  const MapOsmFeature({
    required this.id,
    required this.name,
    required this.geometryType,
    required this.point,
    required this.rings,
    required this.status,
    required this.osmUrl,
  });

  final String id;
  final String? name;
  final String geometryType;
  final LatLng? point;
  final List<List<LatLng>> rings;
  final String status;
  final String osmUrl;

  factory MapOsmFeature.fromJson(Map<String, dynamic> json) {
    final osmId = json['osm_id']?.toString().trim() ?? '';
    final osmType = json['osm_type']?.toString().trim() ?? '';
    final geometry = json['geometri'];
    final status = json['status_verifikasi']?.toString().trim() ?? '';
    final url = json['url_osm']?.toString().trim() ?? '';
    if (int.tryParse(osmId) == null ||
        !const {'node', 'way'}.contains(osmType) ||
        geometry is! Map ||
        status.isEmpty ||
        url.isEmpty ||
        json['terverifikasi'] != false) {
      throw const FormatException('Fitur OSM tidak memenuhi kontrak.');
    }
    final type = geometry['type']?.toString();
    final coordinates = geometry['coordinates'];
    LatLng? point;
    List<List<LatLng>> rings = const [];
    if (type == 'Point') {
      point = _position(coordinates);
    } else if (type == 'Polygon' &&
        coordinates is List &&
        coordinates.isNotEmpty) {
      rings = List.unmodifiable(
        coordinates.map((rawRing) {
          if (rawRing is! List || rawRing.length < 4) {
            throw const FormatException('Ring polygon OSM tidak valid.');
          }
          final ring = rawRing.map(_position).toList(growable: false);
          if (ring.first != ring.last) {
            throw const FormatException('Ring polygon OSM tidak tertutup.');
          }
          return List<LatLng>.unmodifiable(ring);
        }),
      );
    } else {
      throw const FormatException('Jenis geometri OSM tidak didukung.');
    }
    if ((type == 'Point' && osmType != 'node') ||
        (type == 'Polygon' && osmType != 'way')) {
      throw const FormatException('Jenis geometri tidak cocok dengan ID OSM.');
    }
    return MapOsmFeature(
      id: '$osmType/$osmId',
      name: _text(json['nama']),
      geometryType: type!,
      point: point,
      rings: rings,
      status: status,
      osmUrl: url,
    );
  }
}

class MapOsmDataset {
  const MapOsmDataset({required this.features, this.attribution});
  final List<MapOsmFeature> features;
  final String? attribution;

  factory MapOsmDataset.fromEnvelope(Map<String, dynamic> envelope) {
    final data = envelope['data'];
    if (envelope['success'] != true ||
        data is! Map ||
        data['features'] is! List) {
      throw const FormatException('Respons fitur OSM dari API tidak valid.');
    }
    final features = (data['features'] as List)
        .map((feature) {
          if (feature is! Map) {
            throw const FormatException('Fitur OSM tidak valid.');
          }
          return MapOsmFeature.fromJson(Map<String, dynamic>.from(feature));
        })
        .toList(growable: false);
    final metadata = data['metadata'];
    final expectedCount = metadata is Map
        ? int.tryParse(metadata['jumlah_fitur']?.toString() ?? '')
        : null;
    if (expectedCount != null && expectedCount != features.length) {
      throw const FormatException(
        'Jumlah fitur OSM tidak cocok dengan metadata.',
      );
    }
    return MapOsmDataset(
      features: List.unmodifiable(features),
      attribution: metadata is Map ? _text(metadata['atribusi']) : null,
    );
  }
}

class MapHazardResult {
  const MapHazardResult({required this.items, this.analyzedAt});
  final List<MapHazardItem> items;
  final DateTime? analyzedAt;

  factory MapHazardResult.fromEnvelope(Map<String, dynamic> envelope) {
    final data = envelope['data'];
    final hazards = data is Map ? data['bahaya'] : null;
    if (envelope['success'] != true || data is! Map || hazards is! Map) {
      throw const FormatException('Respons analisis bahaya tidak valid.');
    }
    const names = <String, String>{
      'tsunami': 'Tsunami',
      'banjir': 'Banjir',
      'gempa_bumi': 'Gempa bumi',
      'letusan_gunung_api': 'Kawasan rawan gunung api',
    };
    final items = <MapHazardItem>[];
    for (final entry in names.entries) {
      final result = hazards[entry.key];
      if (result is! Map) {
        items.add(
          MapHazardItem(
            name: entry.value,
            status: 'belum_dapat_ditentukan',
            explanation: 'Data bahaya belum tersedia.',
          ),
        );
      } else {
        items.add(
          MapHazardItem(
            name: entry.value,
            status: result['status']?.toString() ?? 'belum_dapat_ditentukan',
            explanation:
                result['penjelasan']?.toString() ??
                'Hasil belum dapat ditentukan.',
          ),
        );
      }
    }
    return MapHazardResult(
      items: List.unmodifiable(items),
      analyzedAt: DateTime.tryParse(data['waktu_analisis']?.toString() ?? ''),
    );
  }
}

class MapHazardItem {
  const MapHazardItem({
    required this.name,
    required this.status,
    required this.explanation,
  });
  final String name;
  final String status;
  final String explanation;
}

class WalkingRoute {
  const WalkingRoute({
    required this.coordinates,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.destinationId,
    required this.destinationName,
    required this.warning,
  });
  final List<LatLng> coordinates;
  final double distanceMeters;
  final double? durationSeconds;
  final String destinationId;
  final String? destinationName;
  final String warning;

  factory WalkingRoute.fromEnvelope(Map<String, dynamic> envelope) {
    final data = envelope['data'];
    final geometry = data is Map ? data['geometri'] : null;
    final destination = data is Map ? data['tujuan'] : null;
    if (envelope['success'] != true ||
        data is! Map ||
        geometry is! Map ||
        geometry['type'] != 'LineString' ||
        geometry['coordinates'] is! List ||
        destination is! Map) {
      throw const FormatException('Respons rute tidak valid.');
    }
    final points = (geometry['coordinates'] as List)
        .map(_position)
        .toList(growable: false);
    final distance = _number(data['jarak_meter']);
    final id = destination['id']?.toString() ?? '';
    final warning = data['peringatan']?.toString() ?? '';
    if (points.length < 2 || distance == null || distance <= 0 || id.isEmpty) {
      throw const FormatException('Geometri atau metadata rute tidak lengkap.');
    }
    if (warning != mobileRouteDisclaimer) {
      throw const FormatException('Peringatan pada rute tidak sesuai kontrak.');
    }
    return WalkingRoute(
      coordinates: List.unmodifiable(points),
      distanceMeters: distance,
      durationSeconds: _number(data['durasi_detik']),
      destinationId: id,
      destinationName: _text(destination['nama']),
      warning: warning,
    );
  }
}

LatLng _position(dynamic raw) {
  if (raw is! List || raw.length < 2) {
    throw const FormatException('Koordinat GeoJSON tidak valid.');
  }
  final longitude = _number(raw[0]);
  final latitude = _number(raw[1]);
  if (longitude == null ||
      latitude == null ||
      longitude < -180 ||
      longitude > 180 ||
      latitude < -90 ||
      latitude > 90) {
    throw const FormatException('Koordinat GeoJSON di luar rentang.');
  }
  return LatLng(latitude, longitude);
}

double? _number(dynamic value) {
  if (value is num && value.isFinite) return value.toDouble();
  final parsed = double.tryParse(value?.toString() ?? '');
  return parsed != null && parsed.isFinite ? parsed : null;
}

String? _text(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

String? _first(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = _text(map[key]);
    if (value != null) return value;
  }
  return null;
}
