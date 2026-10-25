import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ranah_mobile/app/ranah_app.dart';
import 'package:ranah_mobile/models/news_item.dart';
import 'package:ranah_mobile/pages/news_page.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('news search, category filter, detail and back work', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      RanahApp(internetStatusMonitor: createTestInternetStatusMonitor()),
    );
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

    await tester.tap(find.byKey(const ValueKey('news-category-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Erupsi').last);
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
    final exampleTitle = find.text(
      'Contoh: Kenali informasi resmi aktivitas gunung api',
    );
    await tester.scrollUntilVisible(
      exampleTitle,
      180,
      scrollable: _newsScrollable().first,
    );
    await tester.tap(exampleTitle);
    await tester.pumpAndSettle();
    expect(find.text('Sumber berita: belum dicantumkan.'), findsOneWidget);
    expect(
      find.textContaining('Artikel ini merupakan contoh konten edukasi'),
      findsOneWidget,
    );

    await tester.tap(find.text('Kembali'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, 600));
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

    await tester.tap(find.byKey(const ValueKey('news-category-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pengungsian').last);
    await tester.pumpAndSettle();
    expect(
      find.text('Contoh: Siapkan kebutuhan untuk keadaan darurat'),
      findsOneWidget,
    );
    expect(
      find.text('Contoh: Cari tahu jalur evakuasi di sekitar Anda'),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('news-category-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bantuan').last);
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
  testWidgets('category, region and date filters combine against news data', (
    tester,
  ) async {
    final items = [
      _filterItem('1', 'Banjir Agam 5 Mei', 'Banjir', 'Agam', 5),
      _filterItem('2', 'Banjir Padang 5 Mei', 'Banjir', 'Padang', 5),
      _filterItem('3', 'Longsor Agam 5 Mei', 'Longsor', 'Agam', 5),
      _filterItem('4', 'Banjir Agam 6 Mei', 'Banjir', 'Agam', 6),
    ];
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: NewsPage(items: items)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('news-category-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Banjir').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('news-region-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agam').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('news-date-start')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('06/05/2026').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('news-date-end')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('06/05/2026').last);
    await tester.pumpAndSettle();

    expect(find.text('Banjir Agam 6 Mei'), findsOneWidget);
    expect(find.text('Banjir Padang 5 Mei'), findsNothing);
    expect(find.text('Longsor Agam 5 Mei'), findsNothing);
    expect(find.text('Banjir Agam 5 Mei'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('news-clear-filters')));
    await tester.pumpAndSettle();
    expect(find.text('Banjir Agam 5 Mei'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Longsor Agam 5 Mei'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Longsor Agam 5 Mei'), findsOneWidget);
  });
}

NewsItem _filterItem(
  String id,
  String title,
  String category,
  String region,
  int day,
) => NewsItem(
  id: id,
  category: category,
  title: title,
  summary: 'Ringkasan $title',
  body: title,
  publishedAt: 'Contoh data',
  icon: Icons.newspaper,
  accent: Colors.orange,
  contentType: 'kejadian',
  region: region,
  eventAt: DateTime(2026, 5, day),
);

Finder _newsScrollable() => find.descendant(
  of: find.byKey(const PageStorageKey('news-list-scroll')),
  matching: find.byType(Scrollable),
);
