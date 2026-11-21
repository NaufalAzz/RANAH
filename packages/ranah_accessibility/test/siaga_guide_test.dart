import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ranah_accessibility/ranah_accessibility.dart';
import 'package:shared_preferences/shared_preferences.dart';

const guide = SiagaGuide(
  id: 71,
  name: 'Marapi',
  status: 'Level II (Waspada)',
  recommendation: 'Ikuti arahan petugas setempat.',
  period: '20 November 2026',
  source: 'MAGMA Indonesia',
  retrievedAt: null,
);

class _Voice extends VoiceEngine {
  String? spoken;
  @override
  Future<void> speak(String text) async {
    spoken = text;
  }

  @override
  Future<void> stopSpeaking() async {}
  @override
  Future<void> cancel() async {}
  @override
  Future<void> listen({
    required void Function(String, bool) onText,
    required void Function(String) onError,
    required void Function() onDone,
  }) async {}
}

void main() {
  test(
    'period dates are localized once and numbered recommendations keep decimal distances intact',
    () {
      const report = SiagaGuide(
        id: 1,
        name: 'Marapi',
        status: 'Level II (Waspada)',
        period:
            '2026-11-20T00:00:00.000000Z · 2026-11-20T00:00:00.000000Z · 00:00-24:00 WIB',
        recommendation:
            '1. Jarak contoh 3.5 km tetap utuh. 2. Ikuti arahan petugas. 3. Pantau informasi resmi.',
        retrievedAt: null,
      );
      expect(report.displayPeriod, '20 November 2026 · 00:00-24:00 WIB');
      expect(report.recommendationParagraphs, [
        '1. Jarak contoh 3.5 km tetap utuh.',
        '2. Ikuti arahan petugas.',
        '3. Pantau informasi resmi.',
      ]);
      expect(report.displayRetrievedAt, 'Waktu belum tersedia');
      expect(
        formatSiagaTimestamp(DateTime(2026, 11, 21, 21, 36)),
        matches(
          r'^21 November 2026, 21\.36 (WIB|WITA|WIT|UTC(?:[+-]\d\d:\d\d)?)$',
        ),
      );
    },
  );

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'stored guide keeps identity, source and recommendation and restores as a copy',
    () async {
      await SiagaGuideStore().save(guide);
      final restored = await SiagaGuideStore().read();
      expect(restored?.name, 'Marapi');
      expect(restored?.id, 71);
      expect(restored?.recommendation, 'Ikuti arahan petugas setempat.');
      expect(restored?.source, 'MAGMA Indonesia');
      expect(restored?.fromCache, isTrue);
      expect(restored?.retrievedAt, isNull);
    },
  );

  test(
    'corrupt stored data is ignored and invalid locations are rejected',
    () async {
      SharedPreferences.setMockInitialValues({
        'ranah_siaga_guide_v1': '{broken',
      });
      expect(await SiagaGuideStore().read(), isNull);
      expect(const SiagaLocation(100, 100, 10).isValid, isFalse);
      expect(const SiagaLocation(-0.381, 100.473, -1).isValid, isFalse);
      const location = SiagaLocation(-0.381, 100.473, null);
      expect(location.isValid, isTrue);
      expect(location.accuracyLabel, 'Akurasi belum tersedia');
      expect(location.nearest.name, 'Marapi');
      expect(location.distanceKm(location.nearest), closeTo(0, .001));
    },
  );

  testWidgets(
    'GPS denial leaves manual selection usable and does not fetch a report',
    (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: SiagaLocationPage(
            loadGuide: (_) async {
              calls++;
              return guide;
            },
            readLocation: () async => throw StateError('denied'),
            contacts: const [],
            onOpenReport: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gunakan Lokasi Saya'));
      await tester.pumpAndSettle();
      expect(
        find.text('Lokasi belum dapat dibaca. Pilih gunung secara manual.'),
        findsOneWidget,
      );
      expect(calls, 0);
      final selector = tester.widget<DropdownButtonFormField<String>>(
        find.byType(DropdownButtonFormField<String>),
      );
      selector.onChanged!('Marapi');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tampilkan Panduan'));
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(find.text('Ikuti arahan petugas setempat.'), findsOneWidget);
    },
  );

  testWidgets(
    'guide is read aloud, saved and restored without network on a phone',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final voice = _Voice();
      Widget page(Future<SiagaGuide> Function(String) loader) => MaterialApp(
        home: SiagaLocationPage(
          initialLocation: const SiagaLocation(-0.381, 100.473, 15),
          loadGuide: loader,
          readLocation: () async => const SiagaLocation(-0.381, 100.473, 15),
          contacts: const [],
          onOpenReport: (_) {},
          voiceEngine: voice,
        ),
      );
      await tester.pumpWidget(page((_) async => guide));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Tampilkan Panduan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tampilkan Panduan'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Dengarkan Rekomendasi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dengarkan Rekomendasi'));
      await tester.pumpAndSettle();
      expect(voice.spoken, contains('Ikuti arahan petugas setempat.'));
      await tester.ensureVisible(find.text('Simpan Panduan Offline'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Simpan Panduan Offline'));
      await tester.pumpAndSettle();
      expect((await SiagaGuideStore().read())?.name, 'Marapi');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(page((_) async => throw StateError('offline')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Buka Panduan Tersimpan · Marapi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Buka Panduan Tersimpan · Marapi'));
      await tester.pumpAndSettle();
      expect(find.text('Ikuti arahan petugas setempat.'), findsOneWidget);
      expect(
        find.text('Salinan tersimpan; belum memastikan kondisi terbaru.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'report identity mismatch is rejected and another volcano copy is not reused',
    (tester) async {
      await SiagaGuideStore().save(guide);
      await tester.pumpWidget(
        MaterialApp(
          home: SiagaLocationPage(
            initialLocation: const SiagaLocation(-7.54, 110.446, 10),
            loadGuide: (_) async => guide,
            readLocation: () async => const SiagaLocation(-7.54, 110.446, 10),
            contacts: const [],
            onOpenReport: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tampilkan Panduan'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Laporan belum dapat dimuat. Periksa koneksi atau pilih gunung lain.',
        ),
        findsOneWidget,
      );
      expect(find.text('Ikuti arahan petugas setempat.'), findsNothing);
    },
  );
}
