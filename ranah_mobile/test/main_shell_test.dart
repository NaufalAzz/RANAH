import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ranah_mobile/app/ranah_app.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('Home and primary tab pages render inside the shell', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      RanahApp(
        mapTilesEnabled: false,
        internetStatusMonitor: createTestInternetStatusMonitor(),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.text(
        'Berita belum dapat dimuat dari server. Periksa koneksi lalu coba lagi.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Contoh:'), findsNothing);

    await tester.drag(find.byType(ListView).first, const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('Berita Terbaru'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Peta'));
    await tester.pumpAndSettle();
    expect(find.text('Peta dan Zona Bencana'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Berita').last);
    await tester.pumpAndSettle();
    expect(find.text('Berita dan Event'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Menu').last);
    await tester.pumpAndSettle();
    expect(find.text('Layanan RANAH'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Unavailable API does not show local example stories as news', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      RanahApp(
        mapTilesEnabled: false,
        internetStatusMonitor: createTestInternetStatusMonitor(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Contoh:'), findsNothing);
    expect(find.text('Belum ada berita yang dipublikasikan.'), findsNothing);
    expect(
      find.textContaining('Berita belum dapat dimuat dari server'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('News tab shows an empty server error without local examples', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      RanahApp(
        mapTilesEnabled: false,
        internetStatusMonitor: createTestInternetStatusMonitor(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Berita').last);
    await tester.pumpAndSettle();
    expect(find.text('Berita dan Event'), findsOneWidget);
    expect(
      find.textContaining('Berita belum dapat dimuat dari server'),
      findsOneWidget,
    );
    expect(find.textContaining('Contoh:'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
