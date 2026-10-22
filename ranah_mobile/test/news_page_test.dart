import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ranah_mobile/app/ranah_app.dart';

void main() {
  testWidgets('news search, category filter, detail and back work', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const RanahApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Berita'));
    await tester.pumpAndSettle();

    expect(find.text('Berita dan Event'), findsOneWidget);
    expect(
      find.text('Contoh: Kenali informasi resmi aktivitas gunung api'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField), 'kebutuhan');
    await tester.pumpAndSettle();
    expect(
      find.text('Contoh: Siapkan kebutuhan untuk keadaan darurat'),
      findsOneWidget,
    );
    expect(
      find.text('Contoh: Kenali informasi resmi aktivitas gunung api'),
      findsNothing,
    );

    await tester.tap(find.text('Erupsi'));
    await tester.pumpAndSettle();
    expect(
      find.text('Berita tidak ditemukan. Coba kata kunci atau kategori lain.'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    expect(
      find.text('Contoh: Kenali informasi resmi aktivitas gunung api'),
      findsOneWidget,
    );
    expect(
      find.text('Contoh: Siapkan kebutuhan untuk keadaan darurat'),
      findsNothing,
    );

    await tester.enterText(find.byType(TextField), 'resmi');
    await tester.pumpAndSettle();
    await tester.tap(
      find.text('Contoh: Kenali informasi resmi aktivitas gunung api'),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Sumber berita: belum tersedia pada data contoh.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Artikel ini merupakan contoh konten edukasi'),
      findsOneWidget,
    );

    await tester.tap(find.text('Kembali'));
    await tester.pumpAndSettle();
    expect(find.text('Berita dan Event'), findsOneWidget);
    expect(
      find.text('Contoh: Kenali informasi resmi aktivitas gunung api'),
      findsOneWidget,
    );
    expect(
      find.text('Contoh: Siapkan kebutuhan untuk keadaan darurat'),
      findsNothing,
    );
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'resmi',
    );
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pengungsian'));
    await tester.pumpAndSettle();
    expect(
      find.text('Contoh: Siapkan kebutuhan untuk keadaan darurat'),
      findsOneWidget,
    );
    expect(
      find.text('Contoh: Cari tahu jalur evakuasi di sekitar Anda'),
      findsNothing,
    );

    await tester.drag(find.byType(ListView).last, const Offset(-180, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bantuan'));
    await tester.pumpAndSettle();
    expect(
      find.text('Contoh: Cari tahu jalur evakuasi di sekitar Anda'),
      findsOneWidget,
    );
    expect(
      find.text('Contoh: Siapkan kebutuhan untuk keadaan darurat'),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}
