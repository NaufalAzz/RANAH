import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:ranah_mobile/models/gunung_snapshot.dart';
import 'package:ranah_mobile/models/mobile_map_data.dart';
import 'package:ranah_mobile/pages/map_page.dart';
import 'package:ranah_mobile/services/gunung_repository.dart';
import 'package:ranah_mobile/services/mobile_location_provider.dart';
import 'package:ranah_mobile/services/mobile_map_repository.dart';

void main() {
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
    expect(repository.routeCalls, 0);
    await tester.tap(find.text('Lokasi + simulasi jalur'));
    await tester.pumpAndSettle();

    expect(repository.addressCalls, 1);
    expect(repository.hazardCalls, 1);
    expect(repository.osmCalls, 1);
    expect(repository.routeCalls, 1);
    expect(find.textContaining('1.50 km'), findsOneWidget);
    expect(find.textContaining('bukan panduan evakuasi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('location-only consent never sends coordinates to routing', (
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
    await tester.tap(find.text('Gunakan lokasi saja'));
    await tester.pumpAndSettle();
    expect(repository.addressCalls, 1);
    expect(repository.hazardCalls, 1);
    expect(repository.osmCalls, 1);
    expect(repository.routeCalls, 0);
    expect(tester.takeException(), isNull);
  });
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
