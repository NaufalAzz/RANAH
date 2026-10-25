import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ranah_mobile/widgets/volcano_interactive_map.dart';

void main() {
  late String simulationGeoJson;
  late String officialGeoJson;
  late List<VolcanoSimulationPolygon> simulationPolygons;
  late List<VolcanoSimulationPolygon> officialPolygons;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    simulationGeoJson = await rootBundle.loadString(
      'assets/geojson/ranah_krb_simulasi.geojson',
    );
    officialGeoJson = await rootBundle.loadString(
      'assets/geojson/ranah_krb_big_terverifikasi.geojson',
    );
    simulationPolygons = parseSimulatedKrbGeoJson(simulationGeoJson);
    officialPolygons = parseOfficialKrbGeoJson(officialGeoJson);
  });

  test('only verified in-range coordinates become markers', () {
    expect(volcanoMapMarkerFrom(_item(1, latitude: null)), isNull);
    expect(volcanoMapMarkerFrom(_item(1, latitude: 95)), isNull);
    expect(volcanoMapMarkerFrom(_item(1, validated: false)), isNull);
    expect(volcanoMapMarkerFrom(_item(1)), isNotNull);
  });

  test('MAGMA levels and unknown status map to separate marker colors', () {
    expect(
      volcanoMapMarkerFrom(_item(1, status: 'Level I (Normal)'))!.levelKey,
      'i',
    );
    expect(
      volcanoMapMarkerFrom(_item(2, status: 'Level II (Waspada)'))!.levelKey,
      'ii',
    );
    expect(
      volcanoMapMarkerFrom(_item(3, status: 'Level III (Siaga)'))!.levelKey,
      'iii',
    );
    expect(
      volcanoMapMarkerFrom(_item(4, status: 'Level IV (Awas)'))!.levelKey,
      'iv',
    );
    expect(
      volcanoMapMarkerFrom(_item(5, status: null))!.color,
      const Color(0xFF9AA7B5),
    );
  });

  test('simulation GeoJSON uses longitude then latitude and zones', () {
    expect(simulationPolygons, hasLength(6));

    final marapiZoneI = simulationPolygons.firstWhere(
      (entry) => entry.volcano == 'Marapi' && entry.zone == 'I',
    );
    expect(marapiZoneI.polygon.points.first.latitude, -0.3736);
    expect(marapiZoneI.polygon.points.first.longitude, 100.5536);
    expect(simulationPolygons.map((entry) => entry.zone).toSet(), {
      'I',
      'II',
      'III',
    });
    expect(simulationPolygons.map((entry) => entry.volcano).toSet(), {
      'Marapi',
      'Talang',
    });
  });

  test('official BIG GeoJSON contains only verified and valid zones', () {
    expect(officialPolygons, isNotEmpty);
    expect(officialPolygons.every((entry) => entry.official), isTrue);
    expect(
      officialPolygons.map((entry) => entry.volcano).toSet(),
      hasLength(27),
    );
    expect(officialPolygons.map((entry) => entry.zone).toSet(), {
      'I',
      'II',
      'III',
    });
    expect(
      officialPolygons
          .where((entry) => entry.volcano == 'Marapi')
          .map((entry) => entry.zone)
          .toSet(),
      {'I', 'II', 'III'},
    );
    expect(
      officialPolygons
          .where((entry) => entry.volcano == 'Talang')
          .map((entry) => entry.zone)
          .toSet(),
      {'I', 'II', 'III'},
    );
    expect(
      officialPolygons
          .where((entry) => entry.volcano == 'Tandikat')
          .map((entry) => entry.zone)
          .toSet(),
      {'I', 'II', 'III'},
    );
  });

  test('simulation parser rejects malformed or untrusted GeoJSON', () {
    expect(() => parseSimulatedKrbGeoJson('{broken'), throwsFormatException);
    expect(
      () => parseSimulatedKrbGeoJson('{"type":"FeatureCollection"}'),
      throwsFormatException,
    );
  });

  test('official parser rejects simulation-only and malformed data', () {
    expect(
      () => parseOfficialKrbGeoJson('{"type":"FeatureCollection"}'),
      throwsFormatException,
    );
    expect(
      () => parseOfficialKrbGeoJson(simulationGeoJson),
      throwsFormatException,
    );
  });

  testWidgets('map lists markers, legend, and selected marker information', (
    tester,
  ) async {
    var openedId = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VolcanoInteractiveMap(
            items: [
              _item(1, name: 'Marapi', status: 'Level II (Waspada)'),
              _item(2, name: 'Gunung Uji', status: 'Level IV (Awas)'),
              _item(3, name: 'Tidak valid', validated: false),
            ],
            selectedId: 1,
            tilesEnabled: false,
            officialPolygonsForTest: Future.value(officialPolygons),
            simulationPolygonsForTest: Future.value(simulationPolygons),
            onOpenDetail: (item) => openedId = item['id'] as int,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Level I · Normal'), findsOneWidget);
    expect(find.text('Level IV · Awas'), findsOneWidget);
    expect(find.text('KRB I · BIG'), findsOneWidget);
    expect(find.text('KRB II · BIG'), findsOneWidget);
    expect(find.text('KRB III · BIG'), findsOneWidget);
    expect(find.text(simulatedKrbWarning), findsNothing);
    expect(find.text('Zona I simulasi'), findsNothing);
    expect(find.byType(PolygonLayer), findsOneWidget);
    expect(find.byType(MarkerLayer), findsOneWidget);
    expect(
      find.textContaining(
        '2 dari 3 gunung memiliki koordinat BIG yang terverifikasi.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('volcano-marker-3')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('volcano-marker-2')));
    await tester.pumpAndSettle();
    expect(find.text('Gunung Uji'), findsOneWidget);
    expect(find.text('Level IV (Awas)'), findsOneWidget);
    await tester.tap(find.text('Buka laporan gunung'));
    expect(openedId, 2);
  });

  testWidgets(
    'simulation overlay keeps explicit warning when no official data',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VolcanoInteractiveMap(
              items: [_item(1, name: 'Marapi')],
              selectedId: 1,
              tilesEnabled: false,
              officialPolygonsForTest: Future.value(const []),
              simulationPolygonsForTest: Future.value(simulationPolygons),
              onOpenDetail: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Zona I simulasi'), findsOneWidget);
      expect(find.text(simulatedKrbWarning), findsOneWidget);
      expect(find.text('KRB I · BIG'), findsNothing);
    },
  );
}

Map<String, dynamic> _item(
  int id, {
  String name = 'Marapi',
  String? status = 'Level II (Waspada)',
  double? latitude = -0.3736333,
  double longitude = 100.5435707,
  bool validated = true,
}) => {
  'id': id,
  'nama': name,
  'provinsi': 'Sumatera Barat',
  'kabupaten': 'Tanah Datar',
  'latitude': latitude,
  'longitude': longitude,
  'status_aktivitas': status,
  'waktu_pengambilan': '2026-10-25T00:00:00Z',
  'status_validasi_koordinat': validated ? 'terverifikasi' : 'perlu_verifikasi',
};
