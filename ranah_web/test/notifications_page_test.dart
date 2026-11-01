import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ranah_web/models/bmkg_notification.dart';
import 'package:ranah_web/pages/notifications_page.dart';
import 'package:ranah_web/services/notifications_repository.dart';

void main() {
  testWidgets(
    'back button sits below the notification title on small and wide layouts',
    (tester) async {
      var didGoBack = false;
      final repository = _FakeRepository((_) async => _feed());
      for (final size in [const Size(390, 844), const Size(1280, 900)]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(
          MaterialApp(
            home: NotificationsPage(
              onBack: () => didGoBack = true,
              repository: repository,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final title = tester.getRect(find.text('Notifikasi'));
        final back = tester.getRect(find.byTooltip('Kembali'));
        final contentHeading = tester.getRect(
          find.text('Notifikasi BMKG · Sumatera Barat'),
        );
        expect(back.top, greaterThan(title.bottom));
        expect(contentHeading.top, greaterThan(back.bottom));
        expect(back.left, greaterThan(0));
        await tester.tap(find.byTooltip('Kembali'));
        expect(didGoBack, isTrue);
        didGoBack = false;
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );

  testWidgets('shows loading then live API fields and source sync time', (
    tester,
  ) async {
    final completer = Completer<BmkgNotificationFeed>();
    final repository = _FakeRepository((_) => completer.future);
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationsPage(onBack: () {}, repository: repository),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(_feed());
    await tester.pumpAndSettle();
    expect(find.text('Gempa tercatat'), findsOneWidget);
    expect(find.text('Agam, Sumatera Barat'), findsOneWidget);
    expect(find.text('BMKG'), findsOneWidget);
    expect(find.text('Pemeriksaan sumber BMKG'), findsOneWidget);
    expect(find.textContaining('terakhir berhasil'), findsWidgets);
    expect(find.textContaining('DATA SIMULASI'), findsNothing);
  });

  testWidgets('shows an explicit empty state for an empty successful feed', (
    tester,
  ) async {
    final repository = _FakeRepository((_) async => _feed(items: const []));
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationsPage(onBack: () {}, repository: repository),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Tidak ada informasi aktif'), findsOneWidget);
    expect(find.textContaining('gagal dimuat'), findsNothing);
  });

  testWidgets('shows API error and retries without sample data', (
    tester,
  ) async {
    var calls = 0;
    final repository = _FakeRepository((_) async {
      calls++;
      if (calls == 1) throw Exception('Server API merespons HTTP 503.');
      return _feed();
    });
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationsPage(onBack: () {}, repository: repository),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Notifikasi BMKG belum dapat dimuat.'), findsOneWidget);
    expect(find.textContaining('Contoh'), findsNothing);

    final retry = find.text('Coba lagi');
    await tester.ensureVisible(retry);
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('Gempa tercatat'), findsOneWidget);
  });

  testWidgets('category chips request the matching server-side feed', (
    tester,
  ) async {
    final repository = _FakeRepository((_) async => _feed());
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationsPage(onBack: () {}, repository: repository),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Peringatan'));
    await tester.pumpAndSettle();

    expect(repository.requestedKinds.last, 'peringatan');
  });

  testWidgets('weather pilot requires explicit area selection', (tester) async {
    final forecasts = _FakeForecastRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationsPage(
          onBack: () {},
          repository: _FakeRepository((_) async => _feed(items: const [])),
          forecastRepository: forecasts,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Cuaca'));
    await tester.pumpAndSettle();

    expect(forecasts.forecastRequests, isEmpty);
    final areaDropdown = find.byType(DropdownButtonFormField<String>);
    await tester.ensureVisible(areaDropdown);
    await tester.tap(areaDropdown);
    await tester.pumpAndSettle();
    final pilotArea = find.text('Pasar Ambacang · Kuranji, Kota Padang').last;
    await tester.ensureVisible(pilotArea);
    await tester.tap(pilotArea);
    await tester.pumpAndSettle();

    expect(forecasts.forecastRequests, ['13.71.09.1001']);
    expect(
      find.text('Prakiraan Cuaca — Pasar Ambacang, Kuranji, Kota Padang'),
      findsOneWidget,
    );
    expect(
      find.text('Prakiraan wilayah, bukan pengamatan cuaca langsung.'),
      findsOneWidget,
    );
    expect(find.text('Hujan Ringan'), findsOneWidget);
  });
}

class _FakeRepository implements BmkgNotificationRepository {
  _FakeRepository(this.handler);

  final Future<BmkgNotificationFeed> Function(int page) handler;
  final requestedKinds = <String?>[];

  @override
  Future<BmkgNotificationFeed> load({required int page, String? kind}) {
    requestedKinds.add(kind);
    return handler(page);
  }
}

class _FakeForecastRepository implements BmkgForecastRepository {
  final forecastRequests = <String>[];

  @override
  Future<List<BmkgWeatherArea>> loadWeatherAreas() async => const [
    BmkgWeatherArea(
      adm4: '13.71.09.1001',
      village: 'Pasar Ambacang',
      district: 'Kuranji',
      city: 'Kota Padang',
      province: 'Sumatera Barat',
    ),
  ];

  @override
  Future<BmkgWeatherForecast> loadWeatherForecast(String adm4) async {
    forecastRequests.add(adm4);
    return BmkgWeatherForecast(
      area: const BmkgWeatherArea(
        adm4: '13.71.09.1001',
        village: 'Pasar Ambacang',
        district: 'Kuranji',
        city: 'Kota Padang',
        province: 'Sumatera Barat',
      ),
      intervals: [
        BmkgWeatherInterval(
          localTime: DateTime(2026, 10, 30, 12),
          utcTime: DateTime.utc(2026, 10, 30, 5),
          condition: 'Hujan Ringan',
          temperature: 24,
          humidity: 92,
          windSpeed: 0.4,
        ),
      ],
      status: 'tersedia',
      isStale: false,
      analysisAt: DateTime.utc(2026, 10, 30, 4),
    );
  }
}

BmkgNotificationFeed _feed({List<BmkgNotification>? items}) =>
    BmkgNotificationFeed(
      items:
          items ??
          [
            BmkgNotification(
              id: '1',
              title: 'Gempa tercatat',
              category: 'Gempa bumi',
              summary: 'Ringkasan dari BMKG.',
              kind: 'kejadian',
              status: 'informasi',
              region: 'Agam, Sumatera Barat',
              source: 'BMKG',
              eventAt: DateTime.parse('2026-10-25T01:00:00Z'),
            ),
          ],
      currentPage: 1,
      lastPage: 1,
      perPage: 30,
      total: items?.length ?? 1,
      sourceUpdatedAt: DateTime.parse('2026-10-25T01:03:00Z'),
      sourceStatuses: {
        'gempa': BmkgSyncState(
          status: 'berhasil',
          lastSuccessAt: DateTime.utc(2026, 10, 25, 1, 3),
        ),
        'prakiraan_cuaca': BmkgSyncState(
          status: 'berhasil',
          lastSuccessAt: DateTime.utc(2026, 10, 25, 1, 3),
        ),
        'peringatan_dini_cuaca': BmkgSyncState(
          status: 'berhasil',
          lastSuccessAt: DateTime.utc(2026, 10, 25, 1, 3),
        ),
      },
    );
