import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ranah_web/services/osm_assembly_point_repository.dart';
import 'package:ranah_web/services/ranah_api_client.dart';

void main() {
  test(
    'loads Point and Polygon with GeoJSON longitude latitude ordering',
    () async {
      final repository = OsmAssemblyPointRepository(
        client: RanahApiClient(
          baseUrl: 'https://api.example.test/api',
          client: MockClient((request) async {
            expect(request.url.path, '/api/peta/titik-kumpul-osm');
            return http.Response.bytes(utf8.encode(jsonEncode(_payload)), 200);
          }),
        ),
      );
      addTearDown(repository.close);

      final dataset = await repository.load();

      expect(dataset.features, hasLength(2));
      expect(dataset.features.first.point?.latitude, -0.8771866);
      expect(dataset.features.first.point?.longitude, 100.3833966);
      expect(
        dataset.features.first.attributes['assembly_point_tsunami'],
        isNull,
      );
      expect(dataset.features.first.disasterType, isNull);
      expect(dataset.features.first.verified, isFalse);
      expect(dataset.features.last.geometryType, 'Polygon');
      expect(
        dataset.features.last.rings.single.first,
        dataset.features.last.rings.single.last,
      );
      expect(
        dataset.features.last.displayPosition.latitude,
        closeTo(-0.877, .01),
      );
    },
  );

  test(
    'rejects OSM data represented as verified or linked to a disaster type',
    () {
      final feature = Map<String, dynamic>.from(_pointFeature)
        ..['terverifikasi'] = true;
      expect(() => OsmAssemblyPoint.fromJson(feature), throwsFormatException);
      feature['terverifikasi'] = false;
      feature['jenis_bencana'] = 'tsunami';
      expect(() => OsmAssemblyPoint.fromJson(feature), throwsFormatException);
    },
  );

  test('rejects coordinates outside valid longitude and latitude ranges', () {
    final feature = Map<String, dynamic>.from(_pointFeature)
      ..['geometri'] = {
        'type': 'Point',
        'coordinates': [181, 0],
      };
    expect(() => OsmAssemblyPoint.fromJson(feature), throwsFormatException);
  });
}

final _pointFeature = <String, dynamic>{
  'osm_id': 13457200557,
  'osm_type': 'node',
  'nama': 'Titik Kumpul dan Parkiran',
  'geometri': {
    'type': 'Point',
    'coordinates': [100.3833966, -0.8771866],
  },
  'atribut_sumber': {
    'emergency': 'assembly_point',
    'assembly_point_tsunami': null,
    'operator': null,
    'access': null,
    'source': null,
  },
  'status_verifikasi': 'Referensi OpenStreetMap — Belum Diverifikasi',
  'terverifikasi': false,
  'jenis_bencana': null,
  'url_osm': 'https://www.openstreetmap.org/node/13457200557',
};

final _payload = {
  'success': true,
  'data': {
    'metadata': {
      'jumlah_fitur': 2,
      'sumber': 'OpenStreetMap melalui HOT Export Tool',
      'lisensi': 'ODbL-1.0',
      'atribusi': '© OpenStreetMap contributors',
      'url_lisensi': 'https://www.openstreetmap.org/copyright',
      'cakupan': 'Hanya dua fitur dalam ekspor ini; bukan inventaris seluruh Kota Padang.',
    },
    'features': [
      _pointFeature,
      {
        'osm_id': 1137161464,
        'osm_type': 'way',
        'nama': 'Lapangan Masjid Asyiah',
        'geometri': {
          'type': 'Polygon',
          'coordinates': [
            [
              [100.383, -0.878],
              [100.384, -0.878],
              [100.384, -0.877],
              [100.383, -0.878],
            ],
          ],
        },
        'atribut_sumber': {'emergency': 'assembly_point'},
        'status_verifikasi': 'Referensi OpenStreetMap — Belum Diverifikasi',
        'terverifikasi': false,
        'jenis_bencana': null,
        'url_osm': 'https://www.openstreetmap.org/way/1137161464',
      },
    ],
  },
};
