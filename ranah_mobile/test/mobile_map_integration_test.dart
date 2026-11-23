import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:ranah_accessibility/ranah_accessibility.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:ranah_mobile/models/gunung_snapshot.dart';
import 'package:ranah_mobile/models/mobile_map_data.dart';
import 'package:ranah_mobile/pages/map_page.dart';
import 'package:ranah_mobile/services/gunung_repository.dart';
import 'package:ranah_mobile/services/mobile_location_provider.dart';
import 'package:ranah_mobile/services/mobile_map_repository.dart';

void main() {
  testWidgets(
    'Siaga preview resolves the selected server ID and displays the recommendation',
    (tester) async {
      final repository = _SiagaRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: MapPage(
            repository: _FakeMapRepository(),
            locationProvider: const _MarapiLocationProvider(),
            gunungRepository: repository,
            tilesEnabled: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Temukan Lokasi Saya'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Temukan Lokasi Saya'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Siaga Erupsi · Marapi'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Siaga Erupsi · Marapi'), findsOneWidget);
      expect(repository.requestedId, 1);
      expect(
        find.textContaining('Arahan resmi untuk uji mobile.'),
        findsOneWidget,
      );
      expect(find.textContaining('Sumber: MAGMA Indonesia'), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, -260));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Buka Panduan Siaga Lengkap'));
      await tester.tap(find.text('Buka Panduan Siaga Lengkap'));
      await tester.pumpAndSettle();
      expect(find.text('Siaga di Lokasi Saya'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'overview tap opens the matching server record with no device location',
    (tester) async {
      Map<String, dynamic>? opened;
      await tester.pumpWidget(
        MaterialApp(
          home: MapPage(
            repository: _FakeMapRepository(),
            locationProvider: const _FakeLocationProvider(),
            gunungRepository: _FakeGunungRepository(),
            tilesEnabled: false,
            onOpenReport: (record) => opened = record,
          ),
        ),
      );
      await tester.pumpAndSettle();
      MapController.of(tester.element(find.byType(MarkerLayer)))
          .move(const LatLng(-0.381, 100.473), 10);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('overview-volcano-marapi')));
      await tester.pumpAndSettle();
      expect(opened?['id'], 1);
      expect(opened?['nama'], 'Marapi');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'initial map shows 69 small volcano icons without KRB or permission',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = _FakeMapRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: MapPage(
            repository: repository,
            locationProvider: const _FakeLocationProvider(),
            gunungRepository: _FakeGunungRepository(),
            tilesEnabled: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final markers = tester
          .widget<MarkerLayer>(find.byType(MarkerLayer))
          .markers;
      expect(markers, hasLength(69));
      expect(find.byType(PolygonLayer), findsNothing);
      for (final reference in volcanoReferences.values) {
        expect(
          markers.map((marker) => marker.point),
          contains(LatLng(reference.latitude, reference.longitude)),
        );
      }
      final tooltip = markers.first.child as Tooltip;
      expect(tooltip.triggerMode, TooltipTriggerMode.manual);
      expect(
        (((tooltip.child as Semantics).child as GestureDetector).child as Icon)
            .size,
        18,
      );
      final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
      expect(map.options.initialCameraFit, isNotNull);
      final camera = MapCamera.of(tester.element(find.byType(MarkerLayer)));
      expect(camera.visibleBounds.contains(const LatLng(5, 95)), isTrue);
      expect(camera.visibleBounds.contains(const LatLng(-9, 140)), isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'GeoJSON Point and Polygon coordinates use longitude, latitude order',
    () {
      final point = MapOsmFeature.fromJson(
        _osmFeature(id: 1, type: 'Point', coordinates: [100.46, -0.91]),
      );
      expect(point.point, const LatLng(-0.91, 100.46));

      final polygon = MapOsmFeature.fromJson(
        _osmFeature(
          id: 2,
          type: 'Polygon',
          coordinates: [
            [
              [100.4, -0.9],
              [100.5, -0.9],
              [100.5, -1.0],
              [100.4, -0.9],
            ],
          ],
        ),
      );
      expect(polygon.rings.single.first, const LatLng(-0.9, 100.4));
      expect(polygon.status, 'Referensi OpenStreetMap — Belum Diverifikasi');
    },
  );

  test('invalid OSM coordinates are rejected', () {
    expect(
      () => MapOsmFeature.fromJson(
        _osmFeature(id: 3, type: 'Point', coordinates: [300, 100]),
      ),
      throwsFormatException,
    );
  });

  testWidgets('approved location plus route calculates one Laravel route', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _FakeMapRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: MapPage(
          repository: repository,
          locationProvider: const _FakeLocationProvider(),
          gunungRepository: _FakeGunungRepository(),
          tilesEnabled: false,
        ),
      ),
    );
    expect(find.byType(MapPage), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);

    final locationButton = find.text('Temukan Lokasi Saya');
    await tester.tap(locationButton);
    await tester.pumpAndSettle();

    expect(repository.addressCalls, 1);
    expect(repository.hazardCalls, 1);
    expect(repository.osmCalls, 1);
    expect(repository.routeCalls, 1);
    expect(find.textContaining('1.50 km'), findsOneWidget);
    expect(find.textContaining('bukan panduan evakuasi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, skip: true);
}

Map<String, dynamic> _osmFeature({
  required int id,
  required String type,
  required dynamic coordinates,
}) => {
  'osm_id': id,
  'osm_type': type == 'Point' ? 'node' : 'way',
  'nama': 'Titik uji',
  'geometri': {'type': type, 'coordinates': coordinates},
  'status_verifikasi': 'Referensi OpenStreetMap — Belum Diverifikasi',
  'terverifikasi': false,
  'url_osm':
      'https://www.openstreetmap.org/${type == 'Point' ? 'node' : 'way'}/$id',
};

class _FakeLocationProvider implements MobileLocationProvider {
  const _FakeLocationProvider();
  @override
  Future<DeviceLocationFix> currentFix() async => DeviceLocationFix(
    latitude: -0.91,
    longitude: 100.46,
    accuracyMeters: 12,
    measuredAt: DateTime.utc(2026),
  );
}

class _FakeMapRepository implements MobileMapRepository {
  int addressCalls = 0;
  int hazardCalls = 0;
  int osmCalls = 0;
  int routeCalls = 0;

  @override
  Future<MapAddress> lookupAddress(DeviceCoordinates location) async {
    addressCalls++;
    return const MapAddress(regency: 'Kota Padang', province: 'Sumatera Barat');
  }

  @override
  Future<MapHazardResult> analyze(DeviceCoordinates location) async {
    hazardCalls++;
    return const MapHazardResult(
      items: [
        MapHazardItem(
          name: 'Gempa bumi',
          status: 'no_data',
          explanation: 'Data tidak tersedia.',
        ),
      ],
    );
  }

  @override
  Future<MapOsmDataset> loadOsm() async {
    osmCalls++;
    return MapOsmDataset(
      features: [
        MapOsmFeature.fromJson(
          _osmFeature(
            id: 13457200557,
            type: 'Point',
            coordinates: [100.46, -0.91],
          ),
        ),
        MapOsmFeature.fromJson(
          _osmFeature(
            id: 1137161464,
            type: 'Polygon',
            coordinates: [
              [
                [100.4, -0.9],
                [100.5, -0.9],
                [100.5, -1.0],
                [100.4, -0.9],
              ],
            ],
          ),
        ),
      ],
    );
  }

  @override
  Future<WalkingRoute> route(
    DeviceCoordinates location,
    MapOsmFeature destination,
  ) async {
    routeCalls++;
    return WalkingRoute(
      coordinates: const [LatLng(-0.91, 100.46), LatLng(-0.92, 100.47)],
      distanceMeters: 1500,
      durationSeconds: 1200,
      destinationId: destination.id,
      destinationName: destination.name,
      warning: 'Simulasi rute; bukan panduan evakuasi.',
    );
  }

  @override
  void close() {}
}

class _FakeGunungRepository extends GunungRepository {
  @override
  Future<GunungListSnapshot> syncGunung() async => const GunungListSnapshot(
    items: [
      {
        'id': 1,
        'nama': 'Marapi',
        'provinsi': 'Sumatera Barat',
        'status_aktivitas': 'Level II (Waspada)',
      },
    ],
    lastCheckedAt: null,
    isFromCache: false,
  );
}

class _SiagaRepository extends _FakeGunungRepository {
  int? requestedId;
  @override
  Future<GunungDetailSnapshot> syncDetail(int id) async {
    requestedId = id;
    return const GunungDetailSnapshot(
      data: {
        'gunung': {
          'id': 1,
          'nama': 'Marapi',
          'status_aktivitas': 'Level II (Waspada)',
        },
        'laporan': [
          {
            'rekomendasi': 'Panduan lama dari data lokal.',
            'sumber': 'Data lokal',
          },
          {
            'rekomendasi': 'Arahan resmi untuk uji mobile.',
            'sumber': 'MAGMA Indonesia',
            'periode_waktu': '00:00-24:00 WIB',
          },
        ],
      },
      lastCheckedAt: null,
      isFromCache: false,
    );
  }
}

class _MarapiLocationProvider implements MobileLocationProvider {
  const _MarapiLocationProvider();
  @override
  Future<DeviceLocationFix> currentFix() async => DeviceLocationFix(
    latitude: -0.381,
    longitude: 100.473,
    accuracyMeters: 15,
    measuredAt: DateTime.now(),
  );
}
