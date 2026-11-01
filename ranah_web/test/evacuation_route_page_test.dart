import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:ranah_web/pages/evacuation_route_page.dart';
import 'package:ranah_web/services/browser_location.dart';
import 'package:ranah_web/services/osm_assembly_point_repository.dart';

void main() {
  testWidgets('renders OSM references without changing the user location', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const userLocation = BrowserLocation(
      latitude: -0.87718,
      longitude: 100.38339,
      accuracyMeters: 12,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EvacuationRoutePage(
            onBack: () {},
            currentLocation: userLocation,
            tilesEnabled: false,
            dataLoader: () async => _dataset(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('osm-assembly-points-map')),
      findsOneWidget,
    );
    expect(find.textContaining('Simulasi Rute Akademik'), findsOneWidget);
    expect(
      find.textContaining('Rute hanya dapat diminta secara eksplisit'),
      findsOneWidget,
    );
    expect(
      find.text('Referensi OpenStreetMap — Belum Diverifikasi'),
      findsWidgets,
    );
    expect(find.text('ID OSM: node/13457200557'), findsOneWidget);
    expect(find.textContaining('Bukan Jalur Evakuasi Resmi'), findsOneWidget);
    expect(find.textContaining('ODbL-1.0'), findsOneWidget);
    expect(
      find.textContaining('bukan inventaris seluruh Kota Padang'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('device-location-marker')),
      findsOneWidget,
    );
    _expectUserMarkerPosition(tester);
    expect(find.textContaining('km'), findsNothing);
    expect(tester.takeException(), isNull);

    final polygonSelection = find.byKey(
      const ValueKey('select-osm-reference-way/1137161464'),
    );
    await tester.ensureVisible(polygonSelection);
    await tester.tap(polygonSelection);
    await tester.pumpAndSettle();
    expect(find.text('Lapangan Masjid Asyiah'), findsWidgets);
    expect(
      find.textContaining('bukan pintu masuk atau akses resmi'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('device-location-marker')),
      findsOneWidget,
    );
    _expectUserMarkerPosition(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('handles narrow, tablet, and desktop widths without overflow', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final size in [
      const Size(360, 800),
      const Size(768, 1024),
      const Size(1280, 900),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EvacuationRoutePage(
              onBack: () {},
              currentLocation: null,
              tilesEnabled: false,
              dataLoader: () async => _dataset(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'viewport $size');
    }
  });

  testWidgets('shows a retry state when the Laravel data request fails', (
    tester,
  ) async {
    var requests = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EvacuationRoutePage(
            onBack: () {},
            currentLocation: null,
            tilesEnabled: false,
            dataLoader: () async {
              requests++;
              if (requests == 1) throw Exception('API unavailable');
              return _dataset();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Referensi OpenStreetMap tidak dapat dimuat.'),
      findsOneWidget,
    );
    final retry = find.byKey(const ValueKey('retry-osm-references'));
    await tester.ensureVisible(retry);
    await tester.tap(retry);
    await tester.pumpAndSettle();

    expect(requests, 2);
    expect(find.text('Titik Kumpul dan Parkiran'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

void _expectUserMarkerPosition(WidgetTester tester) {
  final map = tester.widget<FlutterMap>(
    find.byKey(const ValueKey('osm-assembly-points-map')),
  );
  final markerLayer = map.children.whereType<MarkerLayer>().single;
  expect(markerLayer.markers.last.point, const LatLng(-0.87718, 100.38339));
}

OsmAssemblyPointDataset _dataset() => OsmAssemblyPointDataset(
  metadata: const {
    'jumlah_fitur': 2,
    'sumber': 'OpenStreetMap melalui HOT Export Tool',
    'atribusi': '© OpenStreetMap contributors',
    'lisensi': 'ODbL-1.0',
    'url_lisensi': 'https://www.openstreetmap.org/copyright',
    'cakupan': 'Hanya dua fitur dalam ekspor ini; bukan inventaris seluruh Kota Padang.',
    'tanggal_export': null,
  },
  features: [
    OsmAssemblyPoint.fromJson({
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
      },
      'status_verifikasi': 'Referensi OpenStreetMap — Belum Diverifikasi',
      'terverifikasi': false,
      'jenis_bencana': null,
      'url_osm': 'https://www.openstreetmap.org/node/13457200557',
    }),
    OsmAssemblyPoint.fromJson({
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
    }),
  ],
);
