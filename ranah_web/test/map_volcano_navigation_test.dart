import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ranah_web/app/ranah_app.dart';
import 'package:ranah_web/services/browser_location.dart';
import 'package:ranah_web/services/gunung_repository.dart';
import 'package:ranah_web/services/news_repository.dart';
import 'package:ranah_web/services/ranah_api_client.dart';
import 'package:ranah_web/services/hazard_analysis_repository.dart';
import 'package:ranah_web/services/osm_assembly_point_repository.dart';

void main() {
  testWidgets('map lookups run once and survive navigation away and back', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var locationRequests = 0;
    var areaRequests = 0;
    var gunungRequests = 0;
    var newsRequests = 0;
    var osmRequests = 0;
    final hazard = _CountingHazardRepository();
    final api = MockClient((request) async {
      if (request.url.path.endsWith('/berita')) newsRequests++;
      if (request.url.path.endsWith('/gunung')) gunungRequests++;
      final data = request.url.path.endsWith('/gunung')
          ? [
              {'id': 1, 'nama': 'Marapi', 'provinsi': 'Sumatera Barat'},
            ]
          : <Object>[];
      return http.Response(
        jsonEncode({'success': true, 'data': data}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    RanahApiClient client() =>
        RanahApiClient(baseUrl: 'https://api.example.test/api', client: api);

    await tester.pumpWidget(
      MaterialApp(
        home: RanahShell(
          newsRepository: NewsRepository(client: client()),
          gunungRepository: GunungRepository(client: client()),
          hazardAnalysisRepository: hazard,
          osmLoader: () async {
            osmRequests++;
            return const OsmAssemblyPointDataset(
              metadata: {'jumlah_fitur': 0},
              features: [],
            );
          },
          volcanoMapTilesEnabled: false,
          locationReader: () async {
            locationRequests++;
            return const BrowserLocation(
              latitude: -0.91,
              longitude: 100.46,
              accuracyMeters: 40,
            );
          },
          areaLookup: (_) async {
            areaRequests++;
            return const BrowserAdministrativeArea(province: 'Sumatera Barat');
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('ranah-nav-map')));
    await tester.pumpAndSettle();
    await _tapLocationButton(tester);
    expect(find.text('Marapi'), findsOneWidget);
    expect(locationRequests, 1);
    expect(areaRequests, 1);
    expect(hazard.calls, 1);
    expect(gunungRequests, 1);
    expect(osmRequests, 1);

    await tester.tap(find.byKey(const ValueKey('ranah-nav-news')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('ranah-nav-map')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('current-device-location')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('device-location-street')))
          .data,
      'Sumatera Barat',
    );
    expect(find.text('Potensi Bencana di Lokasi'), findsOneWidget);
    expect(locationRequests, 1);
    expect(areaRequests, 1);
    expect(hazard.calls, 1);
    expect(gunungRequests, 1);
    expect(newsRequests, 1);
    expect(osmRequests, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'map volcano opens matching Laravel report and retains location on return',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var locationRequests = 0;
      var areaRequests = 0;
      final volcano = <String, dynamic>{
        'id': 52,
        'nama': 'Gunung Talang',
        'provinsi': 'Sumatera Barat',
        'kabupaten': 'Solok',
        'status_aktivitas': 'Level I (Normal)',
        'latitude': -0.978,
        'longitude': 100.679,
        'status_validasi_koordinat': 'terverifikasi',
        'waktu_pengambilan': '2026-10-25T12:00:00Z',
      };
      final payload = MockClient((request) async {
        final path = request.url.path;
        final data = path.endsWith('/gunung/52')
            ? {'gunung': volcano, 'laporan': <Object>[]}
            : path.endsWith('/gunung')
            ? [
                volcano,
                {
                  'id': 53,
                  'nama': 'Bukan Sumbar',
                  'provinsi': 'Sumatera Selatan',
                },
              ]
            : <Object>[];
        return http.Response(
          jsonEncode({'success': true, 'data': data}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      RanahApiClient client() => RanahApiClient(
        baseUrl: 'https://api.example.test/api',
        client: payload,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: RanahShell(
            gunungRepository: GunungRepository(client: client()),
            newsRepository: NewsRepository(client: client()),
            volcanoMapTilesEnabled: false,
            locationReader: () async {
              locationRequests++;
              return const BrowserLocation(
                latitude: -0.91,
                longitude: 100.46,
                accuracyMeters: 80,
              );
            },
            areaLookup: (_) async {
              areaRequests++;
              return const BrowserAdministrativeArea(
                province: 'Sumatera Barat',
                regency: 'Kota Padang',
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Peta').first);
      await tester.pumpAndSettle();
      await _tapLocationButton(tester);

      expect(areaRequests, 1);
      expect(find.text('Gunung Talang'), findsOneWidget);
      expect(find.text('Bukan Sumbar'), findsNothing);
      final card = find.byKey(const ValueKey('map-volcano-52'));
      await tester.ensureVisible(card);
      await tester.tap(card);
      for (var frame = 0; frame < 20; frame++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('Laporan Gunung Api'), findsOneWidget);
      expect(find.text('Gunung Talang'), findsOneWidget);

      await tester.tap(find.byTooltip('Kembali'));
      for (var frame = 0; frame < 12; frame++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(
        find.byKey(const ValueKey('current-device-location')),
        findsOneWidget,
      );
      expect(find.text('Provinsi: Sumatera Barat'), findsOneWidget);
      expect(locationRequests, 1);
      expect(tester.takeException(), isNull);
    },
  );
}

class _CountingHazardRepository extends HazardAnalysisRepository {
  _CountingHazardRepository()
    : super(client: RanahApiClient(baseUrl: 'https://api.example.test/api'));

  int calls = 0;

  @override
  Future<HazardAnalysisResult> analyze({
    required double latitude,
    required double longitude,
  }) async {
    calls++;
    return const HazardAnalysisResult(
      analyzedAt: null,
      volcano: VolcanoHazardResult(
        status: 'no_data',
        explanation: 'Data belum tersedia.',
        method: '',
        source: '',
        sourceUrl: '',
        limitations: '',
        features: [],
      ),
    );
  }
}

Future<void> _tapLocationButton(WidgetTester tester) async {
  final button = find.byKey(const ValueKey('find-device-location'));
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
  final accept = find.byKey(
    const ValueKey('accept-location-and-route'),
  );
  if (accept.evaluate().isNotEmpty) {
    await tester.tap(accept);
    await tester.pumpAndSettle();
  }
}
