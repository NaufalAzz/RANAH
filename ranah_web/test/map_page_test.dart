import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:ranah_web/pages/map_page.dart';
import 'package:ranah_web/models/gunung_data.dart';
import 'package:ranah_web/services/administrative_area_lookup.dart';
import 'package:ranah_web/services/browser_geolocation.dart';
import 'package:ranah_web/services/hazard_analysis_repository.dart';
import 'package:ranah_web/services/osm_assembly_point_repository.dart';
import 'package:ranah_web/services/ranah_api_client.dart';
import 'package:ranah_web/services/route_simulation_repository.dart';

void main() {
  testWidgets('initial map is interactive and contains no simulated markers', (
    tester,
  ) async {
    var osmRequests = 0;
    await _pumpMap(
      tester,
      osmLoader: () async {
        osmRequests++;
        return _emptyOsmDataset;
      },
    );

    expect(find.text('Peta dan Jalur Evakuasi'), findsOneWidget);
    expect(find.text('PETA INTERAKTIF'), findsOneWidget);
    expect(find.text('Temukan Lokasi Saya'), findsOneWidget);
    expect(
      find.textContaining('Tekan tombol untuk menandai lokasi'),
      findsOneWidget,
    );
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byType(MarkerLayer), findsNothing);
    expect(osmRequests, 0);
    expect(find.text('Contoh level'), findsNothing);
    final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
    expect(map.options.initialCenter, const LatLng(-2.5, 118));
    expect(
      InteractiveFlag.hasDrag(map.options.interactionOptions.flags),
      isTrue,
    );
    expect(
      InteractiveFlag.hasScrollWheelZoom(map.options.interactionOptions.flags),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('main map renders OSM Point and Polygon without recentering', (
    tester,
  ) async {
    await _pumpMap(
      tester,
      location: const BrowserLocation(
        latitude: -0.91,
        longitude: 100.46,
        accuracyMeters: 20,
      ),
      osmLoader: () async => _osmTestDataset,
    );

    final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
    expect(map.options.initialCenter, const LatLng(-0.91, 100.46));
    final polygons = map.children.whereType<PolygonLayer>().single;
    final markers = map.children.whereType<MarkerLayer>().single.markers;
    expect(polygons.polygons, hasLength(1));
    expect(markers, hasLength(3));
    expect(
      markers.map((marker) => marker.point),
      contains(const LatLng(-0.8771866, 100.3833966)),
    );
    expect(
      markers.any(
        (marker) =>
            (marker.point.latitude - (-0.877667)).abs() < 0.00001 &&
            (marker.point.longitude - 100.383667).abs() < 0.00001,
      ),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'route is requested only after explicit selection and leaves location unchanged',
    (tester) async {
      var requests = 0;
      http.Request? sentRequest;
      final routeRepository = RouteSimulationRepository(
        client: RanahApiClient(
          client: MockClient((request) async {
            requests++;
            sentRequest = request;
            return http.Response.bytes(
              utf8.encode(jsonEncode(_routePayload())),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }),
          baseUrl: 'https://ranah.test/api',
        ),
      );
      addTearDown(routeRepository.close);

      await _pumpMap(
        tester,
        location: const BrowserLocation(
          latitude: -0.87718,
          longitude: 100.38339,
          accuracyMeters: 12,
        ),
        osmLoader: () async => _osmTestDataset,
        routeSimulationRepository: routeRepository,
      );

      expect(
        requests,
        0,
        reason: 'Map load must not automatically request a route.',
      );
      final choosePoint = find.byKey(
        const ValueKey('select-route-destination-node/13457200557'),
      );
      await tester.ensureVisible(choosePoint);
      await tester.pumpAndSettle();
      await tester.tap(choosePoint);
      await tester.pumpAndSettle();
      expect(
        requests,
        0,
        reason: 'Selecting a destination is not route consent.',
      );
      await tester.tap(find.byKey(const ValueKey('calculate-selected-route')));
      await tester.pumpAndSettle();

      expect(requests, 0, reason: 'External coordinate sharing needs consent.');
      expect(
        find.textContaining('diteruskan ke Valhalla demo'),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('confirm-route-coordinate-sharing')),
      );
      await tester.pumpAndSettle();

      expect(requests, 1);
      expect(sentRequest!.url.path, '/api/peta/rute-simulasi');
      // ignore: avoid_print
      expect(jsonDecode(sentRequest!.body), {
        'latitude': -0.87718,
        'longitude': 100.38339,
        'destination_id': 'node/13457200557',
      });
      expect(find.byKey(const ValueKey('route-distance')), findsOneWidget);
      expect(
        find.textContaining('Simulasi Jalur Menuju Titik Kumpul'),
        findsOneWidget,
      );
      expect(
        find.text('Perkiraan durasi berjalan kaki: 44 menit'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('device-location-marker')),
        findsOneWidget,
      );
      final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
      final routeLine = map.children
          .whereType<PolylineLayer>()
          .single
          .polylines
          .single;
      expect(routeLine.points.length, 3);
      expect(routeLine.points.first, const LatLng(-0.87718, 100.38339));
      expect(routeLine.points.last, const LatLng(-0.8771866, 100.3833966));
      final markerLayer = map.children.whereType<MarkerLayer>().single;
      expect(markerLayer.markers.last.point, const LatLng(-0.87718, 100.38339));
      expect(
        find.textContaining('Akurasi perangkat: sekitar ±12 meter'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'location plus route consent calculates one nearby Point automatically',
    (tester) async {
      var requests = 0;
      http.Request? sentRequest;
      final routeRepository = RouteSimulationRepository(
        client: RanahApiClient(
          client: MockClient((request) async {
            requests++;
            sentRequest = request;
            return http.Response.bytes(
              utf8.encode(jsonEncode(_routePayload())),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }),
          baseUrl: 'https://ranah.test/api',
        ),
      );
      addTearDown(routeRepository.close);

      await _pumpMap(
        tester,
        locationReader: () async => const BrowserLocation(
          latitude: -0.91,
          longitude: 100.46,
          accuracyMeters: 25,
        ),
        areaLookup: (_) async => const BrowserAdministrativeArea(
          regency: 'Kota Padang',
          province: 'Sumatera Barat',
        ),
        osmLoader: () async => _osmTestDataset,
        routeSimulationRepository: routeRepository,
        hazardAnalysisRepository: _FakeHazardAnalysisRepository(
          () async => const HazardAnalysisResult(
            analyzedAt: null,
            volcano: VolcanoHazardResult(
              status: 'no_data',
              explanation: 'Fixture tanpa data KRB.',
              method: '',
              source: '',
              sourceUrl: '',
              limitations: '',
              features: [],
            ),
          ),
        ),
      );

      final locationButton = find.byKey(const ValueKey('find-device-location'));
      await tester.ensureVisible(locationButton);
      await tester.tap(locationButton);
      await tester.pumpAndSettle();
      expect(requests, 0);
      await tester.tap(find.byKey(const ValueKey('accept-location-and-route')));
      await tester.pumpAndSettle();

      expect(requests, 1);
      expect(sentRequest!.url.path, '/api/peta/rute-simulasi');
      expect(jsonDecode(sentRequest!.body), {
        'latitude': -0.91,
        'longitude': 100.46,
        'destination_id': 'node/13457200557',
      });
      expect(find.byKey(const ValueKey('route-distance')), findsOneWidget);
      expect(find.byKey(const ValueKey('route-warning')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('confirm-route-coordinate-sharing')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('route coordinate sharing can be cancelled without a request', (
    tester,
  ) async {
    var requests = 0;
    final routeRepository = RouteSimulationRepository(
      client: RanahApiClient(
        client: MockClient((_) async {
          requests++;
          return http.Response('{}', 500);
        }),
        baseUrl: 'https://ranah.test/api',
      ),
    );
    addTearDown(routeRepository.close);
    await _pumpMap(
      tester,
      location: const BrowserLocation(
        latitude: -0.87718,
        longitude: 100.38339,
        accuracyMeters: 12,
      ),
      osmLoader: () async => _osmTestDataset,
      routeSimulationRepository: routeRepository,
    );
    final destination = find.byKey(
      const ValueKey('select-route-destination-node/13457200557'),
    );
    await tester.ensureVisible(destination);
    await tester.tap(destination);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('calculate-selected-route')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('cancel-route-coordinate-sharing')),
    );
    await tester.pumpAndSettle();
    expect(requests, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('polygon reference has no route action and sends no request', (
    tester,
  ) async {
    var requests = 0;
    final routeRepository = RouteSimulationRepository(
      client: RanahApiClient(
        client: MockClient((_) async {
          requests++;
          return http.Response('{}', 500);
        }),
        baseUrl: 'https://ranah.test/api',
      ),
    );
    addTearDown(routeRepository.close);

    await _pumpMap(
      tester,
      location: const BrowserLocation(
        latitude: -0.87718,
        longitude: 100.38339,
        accuracyMeters: 12,
      ),
      osmLoader: () async => _osmTestDataset,
      routeSimulationRepository: routeRepository,
    );
    final polygon = find.byKey(
      const ValueKey('select-route-destination-way/1137161464'),
    );
    await tester.ensureVisible(polygon);
    await tester.pumpAndSettle();
    await tester.tap(polygon);
    await tester.pumpAndSettle();

    expect(find.textContaining('area Polygon tidak digunakan'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('calculate-selected-route')),
      findsNothing,
    );
    expect(requests, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens limited OSM references from the map page', (tester) async {
    var opened = false;
    await _pumpMap(
      tester,
      location: const BrowserLocation(
        latitude: -0.87718,
        longitude: 100.38339,
        accuracyMeters: 12,
      ),
      onOpenEvacuation: () => opened = true,
    );

    expect(find.text('Referensi OSM ditampilkan pada peta.'), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const ValueKey('open-osm-evacuation-references')),
    );
    await tester.tap(
      find.byKey(const ValueKey('open-osm-evacuation-references')),
    );
    expect(opened, isTrue);
  });

  testWidgets('requests geolocation only on tap and shows the actual fix', (
    tester,
  ) async {
    var requests = 0;
    var osmRequests = 0;
    await _pumpMap(
      tester,
      locationReader: () async {
        requests++;
        return const BrowserLocation(
          latitude: -0.9147,
          longitude: 100.4668,
          accuracyMeters: 2450,
        );
      },
      osmLoader: () async {
        osmRequests++;
        return _osmTestDataset;
      },
    );
    expect(requests, 0);
    expect(osmRequests, 0);

    await _tapLocationButton(tester);
    expect(requests, 1);
    expect(osmRequests, 1);
    expect(find.text('Lokasi Anda'), findsOneWidget);
    expect(find.textContaining('-0.914700, 100.466800'), findsOneWidget);
    expect(find.textContaining('Akurasi perangkat: sekitar'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('device-location-marker')),
      findsOneWidget,
    );
    expect(find.text('Provinsi belum diidentifikasi.'), findsOneWidget);
    expect(find.text('Referensi OSM ditampilkan pada peta.'), findsOneWidget);
    expect(find.text('Peta KRB resmi'), findsNothing);

    final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
    expect(map.options.initialCenter, const LatLng(-0.9147, 100.4668));
    expect(tester.takeException(), isNull);
  });

  testWidgets('location consent is shown before geolocation is requested', (
    tester,
  ) async {
    var requests = 0;
    await _pumpMap(
      tester,
      locationReader: () async {
        requests++;
        return const BrowserLocation(latitude: -0.91, longitude: 100.46);
      },
    );
    final button = find.byKey(const ValueKey('find-device-location'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.text('Pilih penggunaan lokasi'), findsOneWidget);
    expect(find.byKey(const ValueKey('accept-location-only')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('accept-location-and-route')),
      findsOneWidget,
    );
    expect(requests, 0);
    await tester.tap(find.text('Batalkan'));
    await tester.pumpAndSettle();
    expect(requests, 0);
    expect(find.text('Lokasi Anda'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('refresh uses the latest device fix and recenters the map', (
    tester,
  ) async {
    var requests = 0;
    await _pumpMap(
      tester,
      locationReader: () async {
        requests++;
        return requests == 1
            ? const BrowserLocation(
                latitude: -0.9147,
                longitude: 100.4668,
                accuracyMeters: 2450,
              )
            : const BrowserLocation(
                latitude: -1.2345678,
                longitude: 101.8765432,
                accuracyMeters: 42,
              );
      },
      areaLookup: (_) async =>
          const BrowserAdministrativeArea(province: 'Sumatera Barat'),
    );

    await _tapLocationButton(tester);
    await tester.pumpAndSettle();
    expect(find.text('Sumatera Barat'), findsOneWidget);
    expect(find.textContaining('Tidak tersedia pada data peta'), findsNothing);

    await _tapRefreshLocation(tester);

    final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
    expect(map.options.initialCenter, const LatLng(-1.2345678, 101.8765432));
    expect(find.textContaining('-1.234568, 101.876543'), findsOneWidget);
    expect(find.textContaining('Akurasi perangkat: sekitar'), findsOneWidget);
    expect(find.text('Sumatera Barat'), findsOneWidget);
    expect(requests, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'late area lookup cannot overwrite area for a refreshed location',
    (tester) async {
      final areaResponse = Completer<BrowserAdministrativeArea?>();
      var requests = 0;
      await _pumpMap(
        tester,
        locationReader: () async {
          requests++;
          return BrowserLocation(
            latitude: requests == 1 ? -0.91 : -1.2,
            longitude: requests == 1 ? 100.46 : 101.2,
            accuracyMeters: 80,
          );
        },
        areaLookup: (_) =>
            requests == 1 ? areaResponse.future : Future.value(null),
      );

      await _tapLocationButton(tester);
      await _tapRefreshLocation(tester);
      areaResponse.complete(
        const BrowserAdministrativeArea(province: 'Sumatera Barat'),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('-1.200000, 101.200000'), findsOneWidget);
      expect(find.text('Provinsi: Sumatera Barat'), findsNothing);
      expect(find.text('Mengidentifikasi provinsi...'), findsNothing);
      expect(find.text('Mengambil perkiraan alamat...'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('partial address omits every unavailable address row', (
    tester,
  ) async {
    await _pumpMap(
      tester,
      locationReader: () async => const BrowserLocation(
        latitude: -0.91,
        longitude: 100.46,
        accuracyMeters: 60,
      ),
      areaLookup: (_) async => const BrowserAdministrativeArea(
        regency: 'Kota Padang',
        province: 'Sumatera Barat',
      ),
    );

    await _tapLocationButton(tester);

    expect(find.text('Kota Padang'), findsOneWidget);
    expect(find.text('Provinsi: Sumatera Barat'), findsOneWidget);
    expect(find.textContaining('Tidak tersedia pada data peta'), findsNothing);
    expect(find.text('Mengambil perkiraan alamat...'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('address retry does not request device location again', (
    tester,
  ) async {
    var locationRequests = 0;
    var areaRequests = 0;
    await _pumpMap(
      tester,
      locationReader: () async {
        locationRequests++;
        return const BrowserLocation(
          latitude: -0.91,
          longitude: 100.46,
          accuracyMeters: 60,
        );
      },
      areaLookup: (_) async {
        areaRequests++;
        return areaRequests == 1
            ? null
            : const BrowserAdministrativeArea(province: 'Sumatera Barat');
      },
    );

    await _tapLocationButton(tester);
    expect(locationRequests, 1);
    expect(areaRequests, 1);
    final retry = find.text('Coba Lagi');
    await tester.ensureVisible(retry);
    await tester.tap(retry);
    await tester.pumpAndSettle();

    expect(locationRequests, 1);
    expect(areaRequests, 2);
    expect(find.text('Sumatera Barat'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('stalled address lookup reaches an error state', (tester) async {
    final response = Completer<BrowserAdministrativeArea?>();
    await _pumpMap(
      tester,
      locationReader: () async => const BrowserLocation(
        latitude: -0.91,
        longitude: 100.46,
        accuracyMeters: 60,
      ),
      areaLookup: (_) => response.future,
    );

    await _tapLocationButton(tester);
    expect(find.text('Mengambil perkiraan alamat...'), findsOneWidget);
    await tester.pump(const Duration(seconds: 19));
    await tester.pump();

    expect(find.text('Mengambil perkiraan alamat...'), findsNothing);
    expect(
      find.textContaining('Wilayah belum dapat dimuat.'),
      findsNWidgets(2),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('stalled hazard analysis reaches an error state', (tester) async {
    final response = Completer<HazardAnalysisResult>();
    final repository = _FakeHazardAnalysisRepository(() => response.future);
    await _pumpMap(
      tester,
      locationReader: () async => const BrowserLocation(
        latitude: -0.91,
        longitude: 100.46,
        accuracyMeters: 60,
      ),
      hazardAnalysisRepository: repository,
    );

    await _tapLocationButton(tester);
    expect(repository.calls, 1);
    expect(find.text('Menganalisis Tsunami...'), findsOneWidget);
    await tester.pump(const Duration(seconds: 41));
    await tester.pump();

    expect(find.text('Analisis belum dapat dimuat.'), findsOneWidget);
    expect(find.text('Menganalisis Tsunami...'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('OSM references load after location and can be retried', (
    tester,
  ) async {
    var osmRequests = 0;
    await _pumpMap(
      tester,
      locationReader: () async => const BrowserLocation(
        latitude: -0.91,
        longitude: 100.46,
        accuracyMeters: 60,
      ),
      osmLoader: () async {
        osmRequests++;
        if (osmRequests == 1) throw Exception('temporary failure');
        return _osmTestDataset;
      },
    );
    expect(osmRequests, 0);
    expect(find.byType(MarkerLayer), findsNothing);

    await _tapLocationButton(tester);
    expect(osmRequests, 1);
    expect(find.text('Referensi OSM tidak tersedia.'), findsOneWidget);
    final retry = find.byKey(const ValueKey('retry-map-osm'));
    await tester.ensureVisible(retry);
    await tester.tap(retry);
    await tester.pumpAndSettle();

    expect(osmRequests, 2);
    final markerPoints = tester
        .widget<FlutterMap>(find.byType(FlutterMap))
        .children
        .whereType<MarkerLayer>()
        .single
        .markers
        .map((marker) => marker.point);
    expect(markerPoints, contains(const LatLng(-0.8771866, 100.3833966)));
    expect(
      markerPoints.any(
        (point) =>
            (point.latitude - (-0.877667)).abs() < 0.00001 &&
            (point.longitude - 100.383667).abs() < 0.00001,
      ),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('refresh keeps the selected location visible on the map', (
    tester,
  ) async {
    await _pumpMap(
      tester,
      locationReader: () async => const BrowserLocation(
        latitude: -6.2,
        longitude: 106.8,
        accuracyMeters: 25,
      ),
    );
    await _tapLocationButton(tester);
    expect(
      find.byKey(const ValueKey('device-location-marker')),
      findsOneWidget,
    );

    expect(find.text('Temukan Lokasi Saya'), findsNothing);
    expect(
      find.byKey(const ValueKey('device-location-marker')),
      findsOneWidget,
    );
    final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
    expect(map.options.initialCenter, const LatLng(-6.2, 106.8));
    expect(tester.takeException(), isNull);
  });

  testWidgets('permission denied keeps initial map visible and explains why', (
    tester,
  ) async {
    var osmRequests = 0;
    await _pumpMap(
      tester,
      locationReader: () async => throw const BrowserLocationException(
        BrowserLocationFailure.permissionDenied,
      ),
      osmLoader: () async {
        osmRequests++;
        return _osmTestDataset;
      },
    );
    await _tapLocationButton(tester);
    expect(find.text('Temukan Lokasi Saya'), findsOneWidget);
    expect(find.text('Lokasi Anda'), findsNothing);
    expect(find.textContaining('Izin lokasi ditolak'), findsOneWidget);
    expect(find.byType(MarkerLayer), findsNothing);
    expect(osmRequests, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rejects invalid coordinates and handles timeout', (
    tester,
  ) async {
    await _pumpMap(
      tester,
      locationReader: () async =>
          const BrowserLocation(latitude: 91, longitude: 100),
    );
    await _tapLocationButton(tester);
    expect(find.text('Lokasi Anda'), findsNothing);
    expect(
      find.textContaining('Lokasi perangkat tidak tersedia'),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await _pumpMap(
      tester,
      locationReader: () async =>
          throw const BrowserLocationException(BrowserLocationFailure.timeout),
    );
    await _tapLocationButton(tester);
    expect(find.textContaining('sebelum batas waktu'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('map and details fit phone, tablet, and desktop widths', (
    tester,
  ) async {
    for (final size in const [
      Size(320, 720),
      Size(390, 844),
      Size(768, 900),
      Size(1280, 900),
    ]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await _pumpMap(
        tester,
        locationReader: () async => const BrowserLocation(
          latitude: -0.91,
          longitude: 100.46,
          accuracyMeters: 80,
        ),
      );
      await _tapLocationButton(tester);
      expect(find.byType(FlutterMap), findsOneWidget, reason: '$size');
      expect(find.text('Potensi Bencana di Lokasi'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: '$size');
      await tester.pumpWidget(const SizedBox.shrink());
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('province scoped volcano card opens selected API record', (
    tester,
  ) async {
    GunungRecord? opened;
    await _pumpMap(
      tester,
      locationReader: () async => const BrowserLocation(
        latitude: -0.91,
        longitude: 100.46,
        accuracyMeters: 60,
      ),
      area: const BrowserAdministrativeArea(
        province: 'Sumatera Barat',
        regency: 'Kota Padang',
      ),
      areaLookup: (_) async => const BrowserAdministrativeArea(
        province: 'Sumatera Barat',
        regency: 'Kota Padang',
      ),
      records: [
        const GunungRecord(
          id: 11,
          nama: 'Gunung Marapi',
          provinsi: 'Provinsi Sumatera Barat',
          kabupaten: 'Agam',
          statusAktivitas: 'Level II (Waspada)',
          latitude: -0.38,
          longitude: 100.47,
          statusValidasiKoordinat: 'terverifikasi',
          waktuPengambilan: null,
        ),
        const GunungRecord(
          id: 12,
          nama: 'Gunung Bukan Sumbar',
          provinsi: 'Sumatera Selatan',
          kabupaten: 'Kabupaten X',
        ),
        const GunungRecord(
          id: 13,
          nama: 'Gunung Koordinat Belum Terverifikasi',
          provinsi: 'Sumatera Barat',
          kabupaten: 'Kabupaten Y',
          latitude: -1,
          longitude: 100,
          statusValidasiKoordinat: 'belum terverifikasi',
        ),
      ],
      onOpenReport: (record) => opened = record,
    );

    await _tapLocationButton(tester);
    expect(find.text('Gunung Marapi'), findsOneWidget);
    expect(find.text('Gunung Bukan Sumbar'), findsNothing);
    expect(find.textContaining('Jarak garis lurus:'), findsOneWidget);
    expect(
      find.text('Jarak tidak ditampilkan: koordinat belum terverifikasi.'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.byKey(const ValueKey('map-volcano-11')));
    await tester.tap(find.byKey(const ValueKey('map-volcano-11')));
    expect(opened?.id, 11);
  });

  testWidgets('reverse geocoding runs automatically after location is found', (
    tester,
  ) async {
    var lookups = 0;
    await _pumpMap(
      tester,
      locationReader: () async => const BrowserLocation(
        latitude: -0.91,
        longitude: 100.46,
        accuracyMeters: 50,
      ),
      areaLookup: (location) async {
        lookups++;
        expect(location.latitude, -0.91);
        return const BrowserAdministrativeArea(province: 'Sumatera Barat');
      },
    );
    expect(lookups, 0);
    await _tapLocationButton(tester);
    expect(lookups, 1);
    expect(find.text('Sumatera Barat'), findsOneWidget);
    expect(find.textContaining('OpenStreetMap'), findsNWidgets(2));
  });

  testWidgets(
    'hazard analysis is explicit and displays BIG matches and limits',
    (tester) async {
      final repository = _FakeHazardAnalysisRepository(
        () async => HazardAnalysisResult(
          analyzedAt: DateTime.parse('2026-10-26T10:00:00Z'),
          volcano: const VolcanoHazardResult(
            status: 'hasil_tersedia',
            explanation: 'Titik beririsan dengan fitur KRB.',
            method: 'point-intersects',
            source: 'Badan Informasi Geospasial (BIG)',
            sourceUrl: 'https://big.example/layer',
            limitations: 'Bukan panduan evakuasi.',
            features: [
              KrbFeatureMatch(
                volcanoName: 'MARAPI',
                zone: 'KRB II',
                sourceFeatureId: 278,
                mapYear: 2006,
              ),
            ],
          ),
          tsunami: const RasterHazardResult(
            status: 'klasifikasi_belum_diverifikasi',
            explanation: 'Nilai piksel tersedia.',
            dataset: 'layer_bahaya_tsunami',
            source: 'BNPB InaRISK GIS Services',
            sourceUrl: 'https://gis.bnpb.go.id/tsunami',
            pixelSizeMeters: 100,
            spatialReference: 'EPSG:3395',
            pixelValue: 0.0224382,
            limitations: 'Bukan peringatan kejadian.',
          ),
          flood: const RasterHazardResult(
            status: 'no_data',
            explanation: 'Data bahaya untuk koordinat ini belum tersedia atau tidak dapat dibaca.',
            dataset: 'layer_bahaya_banjir',
            source: 'BNPB InaRISK GIS Services',
            sourceUrl: 'https://gis.bnpb.go.id/flood',
            limitations: 'NoData bukan berarti aman.',
          ),
          earthquake: const RasterHazardResult(
            status: 'klasifikasi_belum_diverifikasi',
            explanation:
                'Nilai indeks bahaya tersedia; kelas belum dapat diverifikasi.',
            dataset: 'INDEKS_BAHAYA_GEMPABUMI',
            valueType:
                'Indeks bahaya gempa ternormalisasi (0â€“1), bukan persentase.',
            dataType: 'Float32',
            queryMethod: 'ArcGIS ImageServer Identify pada titik EPSG:4326.',
            source: 'BNPB InaRISK GIS Services',
            sourceUrl: 'https://gis.bnpb.go.id/earthquake',
            pixelValue: 0.42,
            spatialReference: 'EPSG:3395',
            limitations: 'Bukan prediksi atau peringatan kejadian.',
          ),
        ),
      );
      await _pumpMap(
        tester,
        locationReader: () async => const BrowserLocation(
          latitude: -0.91,
          longitude: 100.46,
          accuracyMeters: 60,
        ),
        hazardAnalysisRepository: repository,
      );

      expect(repository.calls, 0);
      await _tapLocationButton(tester);

      expect(repository.calls, 1);
      expect(find.text('Kawasan Rawan Gunung Api'), findsOneWidget);
      expect(
        find.text(
          'Nilai data tersedia, tetapi klasifikasi bahaya tidak tersedia dan tidak disimpulkan.',
        ),
        findsNWidgets(2),
      );
      expect(find.text('TERINDIKASI PADA DATA YANG DIPERIKSA'), findsOneWidget);
      expect(find.text('BELUM DAPAT DIPASTIKAN'), findsNWidgets(3));
      expect(find.textContaining('Nilai piksel raster (mentah)'), findsNothing);
      expect(find.textContaining('https://big.example/layer'), findsNothing);
      for (final key in const [
        'hazard-details-tsunami',
        'hazard-details-banjir',
        'hazard-details-gempa',
        'hazard-details-krb',
      ]) {
        final detail = find.byKey(ValueKey(key));
        await tester.ensureVisible(detail);
        await tester.tap(detail);
        await tester.pumpAndSettle();
      }
      expect(find.textContaining('Tsunami'), findsOneWidget);
      expect(
        find.textContaining('Nilai piksel raster (mentah): 0.0224382'),
        findsOneWidget,
      );
      expect(find.textContaining('Banjir'), findsOneWidget);
      expect(find.textContaining('MARAPI'), findsOneWidget);
      expect(find.textContaining('Gempa Bumi'), findsOneWidget);
      expect(
        find.textContaining('Nilai piksel raster (mentah): 0.42'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Jenis nilai: Indeks bahaya gempa ternormalisasi'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Dataset: INDEKS_BAHAYA_GEMPABUMI'),
        findsOneWidget,
      );
      expect(
        find.textContaining('BNPB InaRISK GIS Services'),
        findsNWidgets(3),
      );
      expect(
        find.textContaining('Bukan prediksi atau peringatan kejadian.'),
        findsOneWidget,
      );
      expect(find.textContaining('https://big.example/layer'), findsOneWidget);
      expect(find.textContaining('Bukan panduan evakuasi.'), findsOneWidget);
      expect(
        tester
            .widget<FlutterMap>(find.byType(FlutterMap))
            .options
            .initialCenter,
        const LatLng(-0.91, 100.46),
      );
      expect(find.textContaining('-0.910000, 100.460000'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'location refresh requests fresh data without moving map camera',
    (tester) async {
      var locationRequests = 0;
      final repository = _FakeHazardAnalysisRepository(
        () async => const HazardAnalysisResult(
          analyzedAt: null,
          volcano: VolcanoHazardResult(
            status: 'no_data',
            explanation: 'Data KRB belum tersedia.',
            method: 'point-intersects',
            source: 'BIG',
            sourceUrl: 'https://big.example/layer',
            limitations: 'Hasil terbatas.',
            features: [],
          ),
        ),
      );
      await _pumpMap(
        tester,
        locationReader: () async {
          locationRequests++;
          return const BrowserLocation(
            latitude: -0.9147,
            longitude: 100.4668,
            accuracyMeters: 2450,
          );
        },
        hazardAnalysisRepository: repository,
      );

      await _tapLocationButton(tester);
      expect(locationRequests, 1);
      final cameraBefore = MapCamera.of(
        tester.element(find.byType(MarkerLayer)),
      );

      final refresh = find.byKey(const ValueKey('refresh-device-location'));
      await tester.ensureVisible(refresh);
      await tester.tap(refresh);
      await tester.pumpAndSettle();

      final cameraAfter = MapCamera.of(
        tester.element(find.byType(MarkerLayer)),
      );
      expect(repository.calls, 1);
      expect(locationRequests, 2);
      expect(find.textContaining('-0.914700, 100.466800'), findsOneWidget);
      expect(find.textContaining('Akurasi perangkat: sekitar'), findsOneWidget);
      expect(cameraAfter.center, cameraBefore.center);
      expect(cameraAfter.zoom, cameraBefore.zoom);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('request failure remains neutral and can be retried', (
    tester,
  ) async {
    final repository = _FakeHazardAnalysisRepository(
      () async =>
          throw const RanahApiException('Server API merespons HTTP 503.'),
    );
    await _pumpMap(
      tester,
      locationReader: () async => const BrowserLocation(
        latitude: -0.91,
        longitude: 100.46,
        accuracyMeters: 60,
      ),
      hazardAnalysisRepository: repository,
    );

    await _tapLocationButton(tester);
    expect(find.text('Analisis belum dapat dimuat.'), findsOneWidget);
    expect(
      find.textContaining('Server API merespons HTTP 503.'),
      findsOneWidget,
    );
    expect(
      tester.widget<FlutterMap>(find.byType(FlutterMap)).options.initialCenter,
      const LatLng(-0.91, 100.46),
    );

    final retry = find.byKey(const ValueKey('retry-hazard-analysis'));
    await tester.ensureVisible(retry);
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Server API merespons HTTP 503.'),
      findsOneWidget,
    );
    expect(
      tester.widget<FlutterMap>(find.byType(FlutterMap)).options.initialCenter,
      const LatLng(-0.91, 100.46),
    );
    expect(find.textContaining('-0.910000, 100.460000'), findsOneWidget);
    expect(
      find.textContaining('Layanan analisis tidak tersedia.'),
      findsNWidgets(4),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('location card remains readable at larger text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    await _pumpMap(
      tester,
      location: const BrowserLocation(
        latitude: -0.91,
        longitude: 100.46,
        accuracyMeters: 60,
      ),
      area: const BrowserAdministrativeArea(
        street: 'Jalan Contoh yang cukup panjang',
        locality: 'Padang Barat',
        district: 'Padang Barat',
        regency: 'Kota Padang',
        province: 'Sumatera Barat',
      ),
      textScale: 1.7,
    );

    expect(
      find.byKey(const ValueKey('current-device-location')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('analysis response for an old location is discarded', (
    tester,
  ) async {
    final firstResult = Completer<HazardAnalysisResult>();
    final secondResult = Completer<HazardAnalysisResult>();
    var locationRequests = 0;
    late final _FakeHazardAnalysisRepository repository;
    repository = _FakeHazardAnalysisRepository(() {
      return repository.calls == 1 ? firstResult.future : secondResult.future;
    });
    await _pumpMap(
      tester,
      locationReader: () async {
        locationRequests++;
        return locationRequests == 1
            ? const BrowserLocation(
                latitude: -0.91,
                longitude: 100.46,
                accuracyMeters: 60,
              )
            : const BrowserLocation(
                latitude: -1.2,
                longitude: 101.2,
                accuracyMeters: 40,
              );
      },
      hazardAnalysisRepository: repository,
    );

    await _tapLocationButton(tester);
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const ValueKey('refresh-device-location')),
    );
    await tester.tap(find.byKey(const ValueKey('refresh-device-location')));
    await tester.pumpAndSettle();
    expect(repository.calls, 2);
    firstResult.complete(
      HazardAnalysisResult(
        analyzedAt: DateTime.utc(2026, 10, 26),
        volcano: const VolcanoHazardResult(
          status: 'hasil_tersedia',
          explanation: 'Hasil untuk koordinat lama.',
          method: 'point-intersects',
          source: 'BIG',
          sourceUrl: 'https://big.example/layer',
          limitations: 'Uji.',
          features: [],
        ),
        tsunami: const RasterHazardResult(
          status: 'klasifikasi_belum_diverifikasi',
          explanation: 'Data untuk koordinat lama.',
          pixelValue: 0.9,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('-1.200000, 101.200000'), findsOneWidget);
    expect(find.text('Hasil untuk koordinat lama.'), findsNothing);
    expect(find.text('Data untuk koordinat lama.'), findsNothing);
    expect(find.text('Menganalisis Tsunami...'), findsOneWidget);
    secondResult.complete(
      const HazardAnalysisResult(
        analyzedAt: null,
        volcano: VolcanoHazardResult(
          status: 'no_data',
          explanation: 'Hasil untuk koordinat baru.',
          method: '',
          source: '',
          sourceUrl: '',
          limitations: '',
          features: [],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Data KRB untuk lokasi ini belum ditemukan. Ini bukan bukti bahwa lokasi aman.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _tapLocationButton(WidgetTester tester) async {
  final button = find.byKey(const ValueKey('find-device-location'));
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
  final accept = find.byKey(const ValueKey('accept-location-only'));
  if (accept.evaluate().isNotEmpty) {
    await tester.tap(accept);
    await tester.pumpAndSettle();
  }
}

Future<void> _tapRefreshLocation(WidgetTester tester) async {
  final button = find.byKey(const ValueKey('refresh-device-location'));
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> _pumpMap(
  WidgetTester tester, {
  BrowserLocationReader? locationReader,
  BrowserLocation? location,
  BrowserAdministrativeArea? area,
  List<GunungRecord> records = const [],
  ValueChanged<GunungRecord>? onOpenReport,
  VoidCallback? onOpenEvacuation,
  AdministrativeAreaLookup? areaLookup,
  HazardAnalysisRepository? hazardAnalysisRepository,
  MapOsmReferenceLoader? osmLoader,
  RouteSimulationRepository? routeSimulationRepository,
  double textScale = 1,
}) async {
  var currentLocation = location;
  var currentArea = area;
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => MapPage(
              onActivityTap: () {},
              currentLocation: currentLocation,
              currentArea: currentArea,
              onLocationChanged: (location) =>
                  setState(() => currentLocation = location),
              onAreaChanged: (value) => setState(() => currentArea = value),
              gunung: records,
              gunungLoading: false,
              gunungError: null,
              onRetryGunung: () {},
              onOpenReport: onOpenReport ?? (_) {},
              onOpenEvacuation: onOpenEvacuation,
              areaLookup: areaLookup ?? (_) async => null,
              hazardAnalysisRepository: hazardAnalysisRepository,
              osmLoader: osmLoader ?? () async => _emptyOsmDataset,
              routeSimulationRepository: routeSimulationRepository,
              locationReader:
                  locationReader ??
                  () async => throw const BrowserLocationException(
                    BrowserLocationFailure.unsupported,
                  ),
              tilesEnabled: false,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Map<String, dynamic> _routePayload() => {
  'success': true,
  'data': {
    'geometri': {
      'type': 'LineString',
      'coordinates': [
        [100.38339, -0.87718],
        [100.3834, -0.87719],
        [100.3833966, -0.8771866],
      ],
    },
    'jarak_meter': 123.4,
    'jarak_km': 0.12,
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

const _emptyOsmDataset = OsmAssemblyPointDataset(
  metadata: {'jumlah_fitur': 0},
  features: [],
);

const _osmTestDataset = OsmAssemblyPointDataset(
  metadata: {'jumlah_fitur': 2},
  features: [
    OsmAssemblyPoint(
      osmId: 13457200557,
      osmType: 'node',
      name: 'Titik Kumpul dan Parkiran',
      geometryType: 'Point',
      point: LatLng(-0.8771866, 100.3833966),
      rings: [],
      attributes: {'emergency': 'assembly_point'},
      status: 'Referensi OpenStreetMap â€” Belum Diverifikasi',
      verified: false,
      disasterType: null,
      osmUrl: 'https://www.openstreetmap.org/node/13457200557',
    ),
    OsmAssemblyPoint(
      osmId: 1137161464,
      osmType: 'way',
      name: 'Lapangan Masjid Asyiah',
      geometryType: 'Polygon',
      point: null,
      rings: [
        [
          LatLng(-0.878, 100.383),
          LatLng(-0.878, 100.384),
          LatLng(-0.877, 100.384),
          LatLng(-0.878, 100.383),
        ],
      ],
      attributes: {'emergency': 'assembly_point'},
      status: 'Referensi OpenStreetMap â€” Belum Diverifikasi',
      verified: false,
      disasterType: null,
      osmUrl: 'https://www.openstreetmap.org/way/1137161464',
    ),
  ],
);

class _FakeHazardAnalysisRepository extends HazardAnalysisRepository {
  _FakeHazardAnalysisRepository(this._result)
    : super(client: RanahApiClient(baseUrl: 'https://api.example.test/api'));

  final Future<HazardAnalysisResult> Function() _result;
  int calls = 0;

  @override
  Future<HazardAnalysisResult> analyze({
    required double latitude,
    required double longitude,
  }) {
    calls++;
    return _result();
  }
}
