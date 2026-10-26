import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ranah_web/models/gunung_data.dart';
import 'package:ranah_web/pages/volcano_report_page.dart';
import 'package:ranah_web/services/gunung_repository.dart';

void main() {
  testWidgets('report panel collapses and expands while retaining the report', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mapController = MapController();
    addTearDown(mapController.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VolcanoReportPage(
            gunungId: 1,
            onBack: () {},
            tilesEnabled: false,
            mapController: mapController,
            repository: _FixtureRepository(),
          ),
        ),
      ),
    );
    await _pumpFrames(tester);

    expect(find.text('Lokasi Administratif dan Geografis'), findsOneWidget);
    expect(find.text('Agam dan Tanah Datar, Sumatera Barat'), findsOneWidget);
    expect(find.text('Gunung Marapi'), findsOneWidget);

    final mapRect = tester.getRect(find.byType(FlutterMap));
    final panelRect = tester.getRect(
      find.byKey(const ValueKey('report-panel-1')),
    );
    expect(panelRect.bottom, lessThan(mapRect.bottom));
    final centerWithPanelOpen = mapController.camera.center;
    await _dragMouse(tester, mapRect.center + const Offset(420, 20));
    expect(mapController.camera.center, isNot(centerWithPanelOpen));

    await tester.tap(find.byKey(const ValueKey('report-panel-toggle-1')));
    await _pumpFrames(tester, 4);
    expect(find.text('Gunung Marapi'), findsOneWidget);
    expect(find.text('Lokasi Administratif dan Geografis'), findsNothing);
    expect(tester.takeException(), isNull);

    final centerWithPanelClosed = mapController.camera.center;
    await _dragMouse(tester, mapRect.topLeft + const Offset(64, 150));
    expect(mapController.camera.center, isNot(centerWithPanelClosed));

    await tester.tap(find.byKey(const ValueKey('report-panel-toggle-1')));
    await _pumpFrames(tester, 4);
    expect(find.text('Lokasi Administratif dan Geografis'), findsOneWidget);
    expect(find.text('Agam dan Tanah Datar, Sumatera Barat'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpFrames(WidgetTester tester, [int count = 8]) async {
  for (var index = 0; index < count; index++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _dragMouse(WidgetTester tester, Offset start) async {
  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await mouse.addPointer(location: start);
  await mouse.down(start);
  await mouse.moveTo(start + const Offset(65, 35));
  await tester.pump(const Duration(milliseconds: 80));
  await mouse.up();
  await mouse.removePointer();
  await _pumpFrames(tester, 4);
}

class _FixtureRepository implements GunungDataRepository {
  @override
  Future<List<GunungRecord>> loadGunung() async => const [];

  @override
  Future<GunungDetailRecord> loadDetail(int id) async => GunungDetailRecord(
    gunung: const GunungRecord(
      id: 1,
      nama: 'Gunung Marapi',
      provinsi: 'Sumatera Barat',
      kabupaten: 'Agam dan Tanah Datar',
      statusAktivitas: 'Level II (Waspada)',
    ),
    laporan: const [],
  );
}
