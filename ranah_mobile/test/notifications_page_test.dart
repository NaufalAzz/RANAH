import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ranah_mobile/app/ranah_app.dart';
import 'package:ranah_mobile/pages/notifications_page.dart';

void main() {
  testWidgets('notification types open their matching destinations safely', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const RanahApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Notifikasi'));
    await tester.pumpAndSettle();
    expect(find.text('Semua Notifikasi'), findsOneWidget);
    expect(find.text('Rincian gempa belum tersedia'), findsOneWidget);
    expect(find.text('Pembaruan aktivitas belum tersedia'), findsOneWidget);
    expect(find.text('SIMULASI DATA'), findsAtLeastNWidgets(1));
    expect(tester.takeException(), isNull);

    await _tapVisible(tester, find.text('Rincian gempa belum tersedia'));
    await tester.pumpAndSettle();
    expect(find.text('Peta dan Zona Bencana'), findsOneWidget);
    expect(
      find.text(
        'Peta masih berupa ilustrasi; rincian gempa resmi belum tersedia.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Notifikasi'));
    await tester.pumpAndSettle();
    expect(find.text('Semua Notifikasi'), findsOneWidget);
    await _tapVisible(tester, find.text('Pembaruan aktivitas belum tersedia'));
    await tester.pumpAndSettle();
    expect(
      find.text('Detail laporan aktivitas gunung api belum tersedia.'),
      findsOneWidget,
    );

    await _tapVisible(tester, find.text('Informasi status belum tersedia'));
    await tester.pumpAndSettle();
    expect(
      find.text('Informasi status gunung api belum tersedia.'),
      findsOneWidget,
    );

    await _tapVisible(
      tester,
      find.text('Contoh: Siapkan kebutuhan untuk keadaan darurat'),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Artikel ini contoh konten kesiapsiagaan'),
      findsOneWidget,
    );

    await tester.tap(find.text('Kembali'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Notifikasi'));
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.text('Informasi evakuasi belum tersedia'));
    await tester.pumpAndSettle();
    expect(find.text('Peta dan Zona Bencana'), findsOneWidget);
    expect(
      find.text(
        'Peta masih berupa ilustrasi; rute dan titik aman resmi belum tersedia.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('notification without a matching data target is handled safely', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const RanahApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Notifikasi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pembaruan aktivitas belum tersedia'));
    await tester.pumpAndSettle();

    expect(find.text('Semua Notifikasi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('notification bell toggles back to the selected page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const RanahApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Notifikasi'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Notifikasi'));
    await tester.pumpAndSettle();

    expect(find.text('Berita Utama'), findsOneWidget);
    expect(find.text('Semua Notifikasi'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    180,
    scrollable: find.descendant(
      of: find.byType(NotificationsPage),
      matching: find.byType(Scrollable),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
