import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'gunung_data.dart';

const bigKrbLayerUrl =
    'https://kspservices.big.go.id/satupeta/rest/services/PUBLIK/'
    'SUMBER_DAYA_ALAM_DAN_LINGKUNGAN/MapServer/11';

const _zoneColors = <String, int>{
  'I': 0xFF39A9DB,
  'II': 0xFF9566D9,
  'III': 0xFFE85D9E,
};

const _zoneFills = <String, int>{
  'I': 0x5539A9DB,
  'II': 0x559566D9,
  'III': 0x55E85D9E,
};

class VerifiedKrbFeature {
  const VerifiedKrbFeature({
    required this.databaseVolcanoId,
    required this.databaseVolcanoName,
    required this.zone,
    required this.polygons,
    required this.sourceFeatureId,
    required this.sourceYear,
    required this.sourceName,
    required this.sourceUrl,
    required this.verificationBasis,
  });

  final int databaseVolcanoId;
  final String databaseVolcanoName;
  final String zone;
  final List<Polygon> polygons;
  final int sourceFeatureId;
  final int? sourceYear;
  final String sourceName;
  final String sourceUrl;
  final String? verificationBasis;

  int get fillColor => _zoneFills[zone]!;
  int get borderColor => _zoneColors[zone]!;

  bool matches(GunungRecord gunung) =>
      databaseVolcanoId == gunung.id &&
      _normalizeName(databaseVolcanoName) == _normalizeName(gunung.nama);
}

class VerifiedKrbDataset {
  const VerifiedKrbDataset({
    required this.features,
    required this.sourceName,
    required this.sourceUrl,
    required this.accessDate,
    required this.spatialReference,
    required this.notice,
    required this.invalidFeatureCount,
  });

  final List<VerifiedKrbFeature> features;
  final String sourceName;
  final String sourceUrl;
  final String accessDate;
  final String spatialReference;
  final String notice;
  final int invalidFeatureCount;

  List<VerifiedKrbFeature> forGunung(GunungRecord gunung) => features
      .where((feature) => feature.matches(gunung))
      .toList(growable: false);
}

VerifiedKrbDataset parseVerifiedKrbGeoJson(String source) {
  final decoded = jsonDecode(source);
  if (decoded is! Map<String, dynamic> ||
      decoded['type'] != 'FeatureCollection') {
    throw const FormatException('KRB GeoJSON is not a FeatureCollection.');
  }

  final metadata = decoded['metadata'];
  if (metadata is! Map<String, dynamic> ||
      metadata['status'] != 'OFFICIAL_BIG_LAYER_GEOMETRY' ||
      metadata['source_url'] != bigKrbLayerUrl ||
      metadata['spatial_reference'] != 'EPSG:4326' ||
      metadata['zone_attribute'] != 'indga (1=KRB I, 2=KRB II, 3=KRB III)') {
    throw const FormatException(
      'KRB GeoJSON metadata does not identify the verified BIG layer.',
    );
  }

  final sourceName = _requiredText(metadata['source_name']);
  final accessDate = _requiredText(metadata['access_date']);
  final notice = _requiredText(metadata['notice']);
  final rawFeatures = decoded['features'];
  if (rawFeatures is! List) {
    throw const FormatException('KRB GeoJSON features must be a list.');
  }

  final features = <VerifiedKrbFeature>[];
  var invalidFeatureCount = 0;
  for (final rawFeature in rawFeatures) {
    try {
      final feature = _parseFeature(rawFeature);
      if (feature != null) features.add(feature);
    } on FormatException {
      invalidFeatureCount++;
    }
  }
  if (features.isEmpty && rawFeatures.isNotEmpty) {
    throw const FormatException('No valid verified KRB features were found.');
  }

  return VerifiedKrbDataset(
    features: List.unmodifiable(features),
    sourceName: sourceName,
    sourceUrl: bigKrbLayerUrl,
    accessDate: accessDate,
    spatialReference: 'EPSG:4326',
    notice: notice,
    invalidFeatureCount: invalidFeatureCount,
  );
}

VerifiedKrbFeature? _parseFeature(dynamic rawFeature) {
  if (rawFeature is! Map<String, dynamic> || rawFeature['type'] != 'Feature') {
    throw const FormatException('KRB feature is malformed.');
  }
  final properties = rawFeature['properties'];
  final geometry = rawFeature['geometry'];
  if (properties is! Map<String, dynamic> ||
      geometry is! Map<String, dynamic>) {
    throw const FormatException('KRB feature has no properties or geometry.');
  }
  if (properties['verification_status'] != 'VERIFIED_NAME_AND_LOCATION' ||
      properties['coordinate_validation_status']?.toString().toLowerCase() !=
          'terverifikasi' ||
      properties['source_url'] != bigKrbLayerUrl ||
      properties['spatial_reference'] != 'EPSG:4326') {
    return null;
  }

  final id = _integer(properties['database_volcano_id']);
  final name = _requiredText(properties['database_volcano_name']);
  final sourceFeatureId = _integer(properties['source_feature_id']);
  final zone = switch (_integer(properties['indga'])) {
    1 => 'I',
    2 => 'II',
    3 => 'III',
    _ => null,
  };
  final geometryType = geometry['type'];
  final rawCoordinates = geometry['coordinates'];
  if (id == null ||
      name.isEmpty ||
      sourceFeatureId == null ||
      zone == null ||
      geometryType != 'Polygon' && geometryType != 'MultiPolygon' ||
      rawCoordinates is! List ||
      rawCoordinates.isEmpty) {
    throw const FormatException('KRB feature identity or geometry is invalid.');
  }
  final objectId = _integer(properties['objectid']);
  final featureId = _integer(rawFeature['id']);
  if (objectId != sourceFeatureId ||
      (featureId != null && featureId != sourceFeatureId)) {
    throw const FormatException('KRB source feature IDs do not agree.');
  }

  final polygonCoordinates = geometryType == 'Polygon'
      ? [rawCoordinates]
      : rawCoordinates;
  final polygons = <Polygon>[];
  for (final rawPolygon in polygonCoordinates) {
    if (rawPolygon is! List || rawPolygon.isEmpty) {
      throw const FormatException('KRB polygon has no coordinate rings.');
    }
    final rings = rawPolygon.map(_parseRing).toList(growable: false);
    if (rings.any((ring) => ring == null)) {
      throw const FormatException(
        'KRB polygon has an invalid coordinate ring.',
      );
    }
    final validRings = rings.cast<List<LatLng>>();
    polygons.add(
      Polygon(
        points: validRings.first,
        holePointsList: validRings.length > 1
            ? validRings.skip(1).toList(growable: false)
            : null,
        color: Color(_zoneFills[zone]!),
        borderColor: Color(_zoneColors[zone]!),
        borderStrokeWidth: 2,
      ),
    );
  }
  if (polygons.isEmpty) {
    throw const FormatException('KRB feature produced no polygons.');
  }

  return VerifiedKrbFeature(
    databaseVolcanoId: id,
    databaseVolcanoName: name,
    zone: zone,
    polygons: List.unmodifiable(polygons),
    sourceFeatureId: sourceFeatureId,
    sourceYear:
        _integer(properties['source_data_year']) ??
        _integer(properties['thterbit']),
    sourceName: _requiredText(properties['source_name']),
    sourceUrl: bigKrbLayerUrl,
    verificationBasis: _optionalText(properties['verification_basis']),
  );
}

List<LatLng>? _parseRing(dynamic coordinates) {
  if (coordinates is! List || coordinates.length < 4) return null;
  final points = <LatLng>[];
  for (final coordinate in coordinates) {
    if (coordinate is! List || coordinate.length < 2) return null;
    final longitude = coordinate[0];
    final latitude = coordinate[1];
    if (longitude is! num || latitude is! num) return null;
    final lat = latitude.toDouble();
    final lon = longitude.toDouble();
    if (!lat.isFinite ||
        !lon.isFinite ||
        lat < -90 ||
        lat > 90 ||
        lon < -180 ||
        lon > 180) {
      return null;
    }
    points.add(LatLng(lat, lon));
  }
  if (points.first != points.last) return null;
  return List.unmodifiable(points);
}

int? _integer(dynamic value) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');

String _requiredText(dynamic value) {
  final text = _optionalText(value);
  if (text == null) {
    throw const FormatException('Required KRB metadata is missing.');
  }
  return text;
}

String? _optionalText(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

String _normalizeName(String value) => value
    .trim()
    .toLowerCase()
    .replaceFirst(RegExp(r'^(gunung|gn)\.?\s*'), '')
    .replaceAll(RegExp(r'[^a-z0-9]'), '');
