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
    expect(find.textContaining('Sinkronisasi BMKG terakhir'), findsOneWidget);
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

    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('Gempa tercatat'), findsOneWidget);
  });
}

class _FakeRepository implements BmkgNotificationRepository {
  _FakeRepository(this.handler);

  final Future<BmkgNotificationFeed> Function(int page) handler;

  @override
  Future<BmkgNotificationFeed> load({required int page}) => handler(page);
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
    );
