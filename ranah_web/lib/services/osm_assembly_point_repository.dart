import 'package:latlong2/latlong.dart';

import 'ranah_api_client.dart';

class OsmAssemblyPoint {
  const OsmAssemblyPoint({
    required this.osmId,
    required this.osmType,
    required this.name,
    required this.geometryType,
    required this.point,
    required this.rings,
    required this.attributes,
    required this.status,
    required this.verified,
    required this.disasterType,
    required this.osmUrl,
  });

  final int osmId;
  final String osmType;
  final String? name;
  final String geometryType;
  final LatLng? point;
  final List<List<LatLng>> rings;
  final Map<String, dynamic> attributes;
  final String status;
  final bool verified;
  final String? disasterType;
  final String osmUrl;

  String get id => '$osmType/$osmId';

  /// A display-only representative location for selecting a polygon.
  /// It does not describe an entrance or an access point.
  LatLng get displayPosition {
    if (point case final position?) return position;
    final outerRing = rings.first;
    final vertices = outerRing.length > 1
        ? outerRing.take(outerRing.length - 1)
        : outerRing;
    var latitude = 0.0;
    var longitude = 0.0;
    var count = 0;
    for (final vertex in vertices) {
      latitude += vertex.latitude;
      longitude += vertex.longitude;
      count++;
    }
    return LatLng(latitude / count, longitude / count);
  }

  factory OsmAssemblyPoint.fromJson(Map<String, dynamic> json) {
    final osmId = _integer(json['osm_id']);
    final osmType = _text(json['osm_type']);
    final rawName = json['nama']?.toString().trim();
    final geometry = json['geometri'];
    final attributes = json['atribut_sumber'];
    final status = _text(json['status_verifikasi']);
    final osmUrl = _text(json['url_osm']);
    if (osmId == null ||
        osmId < 1 ||
        (osmType != 'node' && osmType != 'way') ||
        geometry is! Map ||
        attributes is! Map ||
        status.isEmpty ||
        osmUrl.isEmpty) {
      throw const FormatException('Fitur referensi OSM tidak lengkap.');
    }

    final geometryType = _text(geometry['type']);
    final rawCoordinates = geometry['coordinates'];
    LatLng? point;
    List<List<LatLng>> rings = const [];
    if (geometryType == 'Point') {
      point = _position(rawCoordinates);
    } else if (geometryType == 'Polygon' &&
        rawCoordinates is List &&
        rawCoordinates.isNotEmpty) {
      rings = List.unmodifiable(
        rawCoordinates.map((rawRing) {
          if (rawRing is! List || rawRing.length < 4) {
            throw const FormatException('Ring Polygon OSM tidak valid.');
          }
          final ring = rawRing.map(_position).toList(growable: false);
          if (ring.first != ring.last) {
            throw const FormatException('Ring Polygon OSM tidak tertutup.');
          }
          return List<LatLng>.unmodifiable(ring);
        }),
      );
    } else {
      throw const FormatException('Geometri OSM tidak didukung.');
    }

    if (json['terverifikasi'] != false) {
      throw const FormatException(
        'Data OSM tidak boleh ditandai terverifikasi.',
      );
    }
    if (json['jenis_bencana'] != null) {
      throw const FormatException(
        'Jenis bencana tidak tersedia pada sumber OSM.',
      );
    }

    return OsmAssemblyPoint(
      osmId: osmId,
      osmType: osmType,
      name: rawName == null || rawName.isEmpty ? null : rawName,
      geometryType: geometryType,
      point: point,
      rings: rings,
      attributes: Map.unmodifiable(Map<String, dynamic>.from(attributes)),
      status: status,
      verified: false,
      disasterType: null,
      osmUrl: osmUrl,
    );
  }
}

class OsmAssemblyPointDataset {
  const OsmAssemblyPointDataset({
    required this.metadata,
    required this.features,
  });

  final Map<String, dynamic> metadata;
  final List<OsmAssemblyPoint> features;

  factory OsmAssemblyPointDataset.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    if (json['success'] != true ||
        data is! Map ||
        data['metadata'] is! Map ||
        data['features'] is! List) {
      throw const FormatException(
        'Respons referensi OSM dari API tidak valid.',
      );
    }
    final metadata = Map<String, dynamic>.from(data['metadata'] as Map);
    final rawFeatures = data['features'] as List;
    final features = rawFeatures
        .map((feature) {
          if (feature is! Map) {
            throw const FormatException(
              'Fitur referensi OSM bukan objek JSON.',
            );
          }
          return OsmAssemblyPoint.fromJson(Map<String, dynamic>.from(feature));
        })
        .toList(growable: false);
    if (metadata['jumlah_fitur'] != features.length) {
      throw const FormatException('Jumlah fitur referensi OSM tidak cocok.');
    }
    return OsmAssemblyPointDataset(
      metadata: Map.unmodifiable(metadata),
      features: List.unmodifiable(features),
    );
  }
}

class OsmAssemblyPointRepository {
  OsmAssemblyPointRepository({RanahApiClient? client})
    : _client = client ?? RanahApiClient();

  final RanahApiClient _client;

  Future<OsmAssemblyPointDataset> load() async =>
      OsmAssemblyPointDataset.fromJson(
        await _client.getJson('peta/titik-kumpul-osm'),
      );

  void close() => _client.close();
}

LatLng _position(dynamic raw) {
  if (raw is! List || raw.length < 2 || raw[0] is! num || raw[1] is! num) {
    throw const FormatException('Koordinat GeoJSON OSM tidak valid.');
  }
  final longitude = (raw[0] as num).toDouble();
  final latitude = (raw[1] as num).toDouble();
  if (!longitude.isFinite ||
      !latitude.isFinite ||
      longitude < -180 ||
      longitude > 180 ||
      latitude < -90 ||
      latitude > 90) {
    throw const FormatException('Koordinat GeoJSON OSM di luar rentang.');
  }
  return LatLng(latitude, longitude);
}

int? _integer(dynamic value) => value is int ? value : int.tryParse('$value');

String _text(dynamic value) => value?.toString().trim() ?? '';
