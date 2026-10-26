import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ranah_web/models/gunung_data.dart';
import 'package:ranah_web/models/verified_krb_data.dart';
import 'package:ranah_web/widgets/volcano_interactive_map.dart';

void main() {
  late VerifiedKrbDataset dataset;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final source = await rootBundle.loadString(
      'assets/geojson/ranah_krb_big_terverifikasi.geojson',
    );
    dataset = parseVerifiedKrbGeoJson(source);
  });

  testWidgets('shows only the selected gunung marker and matched BIG KRB', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VolcanoInteractiveMap(
            gunung: _marapi(),
            showKrb: true,
            tilesEnabled: false,
            krbDataset: Future.value(dataset),
          ),
        ),
      ),
    );
    await _pumpFrames(tester);

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byType(PolygonLayer), findsOneWidget);
    expect(find.byType(MarkerLayer), findsOneWidget);
    expect(find.byKey(const ValueKey('web-volcano-marker-1')), findsOneWidget);
    expect(find.textContaining('BIG'), findsWidgets);
    expect(find.textContaining('Tahun 2006'), findsOneWidget);
    expect(find.text('Legenda Kawasan Rawan Bencana (KRB)'), findsOneWidget);
    expect(find.textContaining('Sumber data: '), findsOneWidget);
    expect(find.textContaining('ID fitur sumber'), findsNothing);
    expect(find.textContaining('https://kspservices.big.go.id'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('web-volcano-marker-1')));
    await tester.pumpAndSettle();
    expect(find.text('Gunung Marapi'), findsOneWidget);
    expect(find.textContaining('Koordinat terverifikasi'), findsOneWidget);
  });

  testWidgets('does not draw an unverified marker or unmatched KRB', (
    tester,
  ) async {
    final unverified = GunungRecord(
      id: 999,
      nama: 'Gunung Belum Cocok',
      latitude: -0.37,
      longitude: 100.54,
      statusValidasiKoordinat: 'perlu_verifikasi',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VolcanoInteractiveMap(
            gunung: unverified,
            showKrb: true,
            tilesEnabled: false,
            krbDataset: Future.value(dataset),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MarkerLayer), findsNothing);
    expect(find.byType(PolygonLayer), findsNothing);
    expect(
      find.textContaining('Lokasi gunung belum dapat diverifikasi'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Data poligon KRB terverifikasi belum tersedia untuk gunung ini.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('can hide KRB polygons without hiding the verified marker', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VolcanoInteractiveMap(
            gunung: _marapi(),
            showKrb: false,
            tilesEnabled: false,
            krbDataset: Future.value(dataset),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PolygonLayer), findsNothing);
    expect(find.byKey(const ValueKey('web-volcano-marker-1')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('map remains responsive and supports pan and pinch zoom', (
    tester,
  ) async {
    final controller = MapController();
    addTearDown(controller.dispose);
    tester.view.physicalSize = const Size(375, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VolcanoInteractiveMap(
            gunung: _marapi(),
            showKrb: false,
            tilesEnabled: false,
            mapController: controller,
            krbDataset: Future.value(dataset),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final initialCenter = controller.camera.center;
    final mapRect = tester.getRect(find.byType(FlutterMap));
    await tester.drag(
      find.byType(FlutterMap),
      const Offset(45, 25),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    expect(controller.camera.center, isNot(initialCenter));

    final zoomBeforePinch = controller.camera.zoom;
    final center = mapRect.center;
    final first = await tester.startGesture(
      Offset(center.dx - 24, center.dy),
      pointer: 1,
    );
    final second = await tester.startGesture(
      Offset(center.dx + 24, center.dy),
      pointer: 2,
    );
    await first.moveTo(Offset(center.dx - 45, center.dy));
    await second.moveTo(Offset(center.dx + 45, center.dy));
    await tester.pump(const Duration(milliseconds: 100));
    await first.up();
    await second.up();
    await tester.pumpAndSettle();
    expect(controller.camera.zoom, greaterThan(zoomBeforePinch));
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop mouse drag pans and wheel zooms inside the map', (
    tester,
  ) async {
    final controller = MapController();
    addTearDown(controller.dispose);
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VolcanoInteractiveMap(
            gunung: _marapi(),
            showKrb: true,
            tilesEnabled: false,
            mapController: controller,
            krbDataset: Future.value(dataset),
          ),
        ),
      ),
    );
    await _pumpFrames(tester);

    final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
    final flags = map.options.interactionOptions.flags;
    expect(InteractiveFlag.hasDrag(flags), isTrue);
    expect(InteractiveFlag.hasScrollWheelZoom(flags), isTrue);

    final rect = tester.getRect(find.byType(FlutterMap));
    final initialCenter = controller.camera.center;
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: rect.center);
    await mouse.down(rect.center);
    await mouse.moveTo(rect.center + const Offset(80, 40));
    await tester.pump(const Duration(milliseconds: 100));
    await mouse.up();
    await mouse.removePointer();
    await _pumpFrames(tester, 4);
    expect(controller.camera.center, isNot(initialCenter));

    final zoomBefore = controller.camera.zoom;
    tester.binding.handlePointerEvent(
      PointerScrollEvent(
        position: rect.center,
        scrollDelta: const Offset(0, -180),
        device: 1,
      ),
    );
    await _pumpFrames(tester, 4);
    expect(controller.camera.zoom, greaterThan(zoomBefore));
    expect(tester.takeException(), isNull);
  });

  testWidgets('map footer and controls fit supported web widths', (
    tester,
  ) async {
    for (final size in const [
      Size(320, 720),
      Size(375, 800),
      Size(768, 900),
      Size(1280, 900),
      Size(1440, 900),
    ]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VolcanoInteractiveMap(
              gunung: _marapi(),
              showKrb: true,
              tilesEnabled: false,
              krbDataset: Future.value(dataset),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(FlutterMap), findsOneWidget, reason: 'viewport $size');
      expect(tester.takeException(), isNull, reason: 'viewport $size');
      await tester.pumpWidget(const SizedBox.shrink());
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('an unreadable KRB asset keeps a verified location usable', (
    tester,
  ) async {
    final completer = Completer<VerifiedKrbDataset>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VolcanoInteractiveMap(
            gunung: _marapi(),
            showKrb: true,
            tilesEnabled: false,
            krbDataset: completer.future,
          ),
        ),
      ),
    );
    completer.completeError(const FormatException('fixture parse failure'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('web-volcano-marker-1')), findsOneWidget);
    expect(find.byType(PolygonLayer), findsNothing);
    expect(find.textContaining('gagal dibaca'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpFrames(WidgetTester tester, [int count = 8]) async {
  for (var index = 0; index < count; index++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

GunungRecord _marapi() => const GunungRecord(
  id: 1,
  nama: 'Gunung Marapi',
  provinsi: 'Sumatera Barat',
  kabupaten: 'Agam dan Tanah Datar',
  statusAktivitas: 'Level II (Waspada)',
  sumberData: 'MAGMA Indonesia',
  latitude: -0.3736333,
  longitude: 100.5435707,
  statusValidasiKoordinat: 'terverifikasi',
  sumberKoordinat: 'BIG',
);
