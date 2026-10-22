import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ranah_mobile/app/ranah_app.dart';

void main() {
  testWidgets('Home and primary tab pages render inside the shell', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const RanahApp());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Berita Utama'), findsOneWidget);
    expect(
      find.text('Contoh: Kenali informasi resmi aktivitas gunung api'),
      findsOneWidget,
    );

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

  testWidgets('Featured news arrows and swipe follow the local items', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const RanahApp());
    await tester.pumpAndSettle();

    const firstTitle = 'Contoh: Kenali informasi resmi aktivitas gunung api';
    const secondTitle = 'Contoh: Siapkan kebutuhan untuk keadaan darurat';
    const thirdTitle = 'Contoh: Cari tahu jalur evakuasi di sekitar Anda';

    expect(find.text(firstTitle), findsOneWidget);
    expect(_iconButton(tester, 'Berita utama sebelumnya').onPressed, isNull);

    await tester.tap(find.byTooltip('Berita utama berikutnya'));
    await tester.pumpAndSettle();
    expect(find.text(secondTitle), findsOneWidget);

    await tester.tap(find.byTooltip('Berita utama sebelumnya'));
    await tester.pumpAndSettle();
    expect(find.text(firstTitle), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(find.text(secondTitle), findsOneWidget);

    await tester.tap(find.byTooltip('Berita utama berikutnya'));
    await tester.pumpAndSettle();
    expect(find.text(thirdTitle), findsOneWidget);
    expect(_iconButton(tester, 'Berita utama berikutnya').onPressed, isNull);
    expect(tester.takeException(), isNull);
  });
}

IconButton _iconButton(WidgetTester tester, String tooltip) {
  return tester.widget<IconButton>(
    find.ancestor(
      of: find.byTooltip(tooltip),
      matching: find.byType(IconButton),
    ),
  );
}
