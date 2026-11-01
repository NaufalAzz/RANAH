import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:ranah_web/services/ranah_api_client.dart';
import 'package:ranah_web/services/route_simulation_repository.dart';

void main() {
  test(
    'posts origin and selected OSM ID and parses GeoJSON lon lat order',
    () async {
      http.Request? request;
      final client = MockClient((value) async {
        request = value;
        return http.Response.bytes(
          utf8.encode(jsonEncode(_payload())),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      final repository = RouteSimulationRepository(
        client: RanahApiClient(
          client: client,
          baseUrl: 'https://ranah.test/api',
        ),
      );
      addTearDown(repository.close);

      final result = await repository.calculate(
        latitude: -0.87,
        longitude: 100.39,
        destinationId: 'node/13457200557',
      );

      expect(request!.url.path, '/api/peta/rute-simulasi');
      expect(jsonDecode(request!.body), {
        'latitude': -0.87,
        'longitude': 100.39,
        'destination_id': 'node/13457200557',
      });
      expect(result.coordinates.first, const LatLng(-0.87, 100.39));
      expect(result.distanceMeters, 1234.5);
      expect(result.distanceKm, 1.23);
      expect(result.durationSeconds, 2585.046);
      expect(result.destinationId, 'node/13457200557');
    },
  );

  test('rejects malformed geometry or an altered warning contract', () {
    final badGeometry = _payload();
    badGeometry['data']['geometri']['type'] = 'Polygon';
    expect(
      () => RouteSimulationResult.fromJson(badGeometry),
      throwsFormatException,
    );

    final badWarning = _payload();
    badWarning['data']['peringatan'] = 'Rute aman';
    expect(
      () => RouteSimulationResult.fromJson(badWarning),
      throwsFormatException,
    );
  });

  test('rejects an out-of-range coordinate and invalid source URL', () {
    final badCoordinate = _payload();
    badCoordinate['data']['geometri']['coordinates'][0][0] = 181.0;
    expect(
      () => RouteSimulationResult.fromJson(badCoordinate),
      throwsFormatException,
    );

    final badUrl = _payload();
    badUrl['data']['url_atribusi'] = 'http://example.test/copyright';
    expect(() => RouteSimulationResult.fromJson(badUrl), throwsFormatException);
  });

  test(
    'surfaces backend unavailable error without inventing a route',
    () async {
      final repository = RouteSimulationRepository(
        client: RanahApiClient(
          client: MockClient(
            (_) async => http.Response(
              jsonEncode({
                'success': false,
                'code': 'ors_not_configured',
                'message':
                    'Routing pejalan kaki ORS belum dikonfigurasi pada server.',
              }),
              503,
            ),
          ),
          baseUrl: 'https://ranah.test/api',
        ),
      );
      addTearDown(repository.close);

      await expectLater(
        repository.calculate(
          latitude: -0.87,
          longitude: 100.39,
          destinationId: 'node/13457200557',
        ),
        throwsA(
          isA<RanahApiException>().having(
            (error) => error.statusCode,
            'statusCode',
            503,
          ),
        ),
      );
    },
  );
}

Map<String, dynamic> _payload() => {
  'success': true,
  'data': {
    'geometri': {
      'type': 'LineString',
      'coordinates': [
        [100.39, -0.87],
        [100.387, -0.874],
        [100.3834, -0.8772],
      ],
    },
    'jarak_meter': 1234.5,
    'jarak_km': 1.23,
    'durasi_detik': 2585.046,
    'sumber_jaringan': 'OpenStreetMap melalui Valhalla demo',
    'atribusi': '© OpenStreetMap contributors',
    'url_atribusi': 'https://www.openstreetmap.org/copyright',
    'metode': 'Valhalla costing pedestrian',
    'peringatan': routeSimulationDisclaimer,
    'tujuan': {
      'id': 'node/13457200557',
      'nama': 'Titik Kumpul dan Parkiran',
      'status_verifikasi': 'Referensi OpenStreetMap — Belum Diverifikasi',
      'url_osm': 'https://www.openstreetmap.org/node/13457200557',
    },
  },
};
