import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ranah_web/models/gunung_data.dart';
import 'package:ranah_web/models/verified_krb_data.dart';

void main() {
  late VerifiedKrbDataset dataset;
  late String source;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    source = await rootBundle.loadString(
      'assets/geojson/ranah_krb_big_terverifikasi.geojson',
    );
    dataset = parseVerifiedKrbGeoJson(source);
  });

  test('parses official BIG metadata and Polygon/MultiPolygon features', () {
    expect(dataset.sourceUrl, bigKrbLayerUrl);
    expect(dataset.spatialReference, 'EPSG:4326');
    expect(dataset.features, hasLength(151));
    expect(
      dataset.features.map((feature) => feature.databaseVolcanoId).toSet(),
      hasLength(27),
    );
    expect(dataset.features.map((feature) => feature.zone).toSet(), {
      'I',
      'II',
      'III',
    });
    expect(dataset.invalidFeatureCount, 0);
  });

  test('matches features by database ID and exact normalized volcano name', () {
    final marapi = GunungRecord(id: 1, nama: 'Gunung Marapi');
    final similarlyNamedDifferentVolcano = GunungRecord(
      id: 1,
      nama: 'Gunung Merapi',
    );
    final merapi = GunungRecord(id: 3, nama: 'Merapi');

    expect(dataset.forGunung(marapi), hasLength(6));
    expect(dataset.forGunung(marapi).map((feature) => feature.zone).toSet(), {
      'I',
      'II',
      'III',
    });
    expect(dataset.forGunung(similarlyNamedDifferentVolcano), isEmpty);
    expect(dataset.forGunung(merapi), hasLength(4));
  });

  test('preserves polygon holes and GeoJSON longitude/latitude order', () {
    final featuresWithHoles = dataset.features.where(
      (feature) => feature.polygons.any(
        (polygon) => polygon.holePointsList?.isNotEmpty ?? false,
      ),
    );
    expect(featuresWithHoles, isNotEmpty);

    final marapiZoneI = dataset
        .forGunung(GunungRecord(id: 1, nama: 'Marapi'))
        .firstWhere((feature) => feature.zone == 'I');
    final point = marapiZoneI.polygons.first.points.first;
    expect(point.latitude, closeTo(-0.417512, 0.000001));
    expect(point.longitude, closeTo(100.428603, 0.000001));
  });

  test('rejects malformed data and simulation data', () {
    expect(() => parseVerifiedKrbGeoJson('{broken'), throwsFormatException);
    expect(
      () => parseVerifiedKrbGeoJson('{"type":"FeatureCollection"}'),
      throwsFormatException,
    );
    expect(
      () => parseVerifiedKrbGeoJson(
        '{"type":"FeatureCollection","metadata":{"status":"SYNTHETIC_DEMO_ONLY"},"features":[]}',
      ),
      throwsFormatException,
    );
  });

  test('a feature with unverified provenance is excluded from rendering', () {
    final decoded = Map<String, dynamic>.from(jsonDecode(source) as Map);
    final features = decoded['features'] as List;
    final first = Map<String, dynamic>.from(features.first as Map);
    final properties = Map<String, dynamic>.from(first['properties'] as Map)
      ..['verification_status'] = 'UNVERIFIED';
    first['properties'] = properties;
    features[0] = first;

    final result = parseVerifiedKrbGeoJson(jsonEncode(decoded));
    expect(result.features, hasLength(150));
    expect(result.invalidFeatureCount, 0);
    expect(result.forGunung(GunungRecord(id: 1, nama: 'Marapi')), hasLength(5));
  });

  test('invalid individual geometry is skipped and counted', () {
    final decoded = Map<String, dynamic>.from(jsonDecode(source) as Map);
    final features = decoded['features'] as List;
    final first = Map<String, dynamic>.from(features.first as Map);
    final geometry = Map<String, dynamic>.from(first['geometry'] as Map)
      ..['coordinates'] = [];
    first['geometry'] = geometry;
    features[0] = first;

    final result = parseVerifiedKrbGeoJson(jsonEncode(decoded));
    expect(result.invalidFeatureCount, 1);
    expect(result.features, hasLength(150));
    expect(result.forGunung(GunungRecord(id: 1, nama: 'Marapi')), hasLength(5));
  });
}
