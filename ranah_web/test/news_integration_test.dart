import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ranah_web/app/ranah_app.dart';
import 'package:ranah_web/data/home_stories.dart';
import 'package:ranah_web/pages/home_page.dart';
import 'package:ranah_web/pages/news_page.dart';
import 'package:ranah_web/services/news_repository.dart';
import 'package:ranah_web/services/ranah_api_client.dart';

void main() {
  final stories = [
    _story(
      '101',
      'Kabar banjir Padang',
      'Banjir',
      DateTime(2026, 10, 24),
      region: 'Kota Padang',
    ),
    _story(
      '102',
      'Penanganan longsor',
      'Longsor',
      DateTime(2026, 10, 25),
      region: 'Kabupaten Agam',
    ),
  ];

  testWidgets('shell loads API news once and keeps detail/back navigation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var requests = 0;
    final repository = NewsRepository(
      client: RanahApiClient(
        client: MockClient((request) async {
          requests++;
          expect(request.url.path, '/api/berita');
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [_apiStory()],
            }),
            200,
          );
        }),
        baseUrl: 'http://localhost:8000/api',
      ),
    );
    await tester.pumpWidget(
      MaterialApp(home: RanahShell(newsRepository: repository)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Kabar banjir Padang'), findsWidgets);
    expect(requests, 1);

    await tester.tap(find.text('Berita').first);
    await tester.pumpAndSettle();
    expect(find.text('Berita dan Event'), findsOneWidget);
    expect(find.text('Kabar banjir Padang'), findsOneWidget);
    expect(requests, 1);

    await tester.tap(find.text('Kabar banjir Padang').last);
    await tester.pumpAndSettle();
    expect(find.text('Isi berita API untuk detail.'), findsOneWidget);
    expect(find.text('Sumber: BNPB'), findsOneWidget);
    expect(find.textContaining('Kota Padang'), findsOneWidget);
    expect(find.textContaining('CONTOH'), findsNothing);

    await tester.tap(find.text('Kembali'));
    await tester.pumpAndSettle();
    expect(find.text('Berita dan Event'), findsOneWidget);
  });

  testWidgets('existing category, date and search filters use API stories', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: NewsPage(stories: stories, onStoryTap: (_) {}),
      ),
    );
    expect(find.text('Kabar banjir Padang'), findsOneWidget);
    expect(find.text('Penanganan longsor'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('web-news-category-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Banjir').last);
    await tester.pumpAndSettle();
    expect(find.text('Kabar banjir Padang'), findsOneWidget);
    expect(find.text('Penanganan longsor'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('web-news-clear-filters')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('web-news-date-start')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('25/10/2026').last);
    await tester.pumpAndSettle();
    expect(find.text('Penanganan longsor'), findsOneWidget);
    expect(find.text('Kabar banjir Padang'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('web-news-clear-filters')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Padang');
    await tester.pumpAndSettle();
    expect(find.text('Kabar banjir Padang'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('web-news-clear-filters')));
    await tester.pumpAndSettle();
    expect(find.text('Penanganan longsor'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'region filter combines with category, resets, and shows empty state',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NewsPage(stories: stories, onStoryTap: (_) {}),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('web-news-region-filter')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kota Padang').last);
      await tester.pumpAndSettle();
      expect(find.text('Kabar banjir Padang'), findsOneWidget);
      expect(find.text('Penanganan longsor'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('web-news-category-filter')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Longsor').last);
      await tester.pumpAndSettle();
      expect(
        find.text('Tidak ada berita yang sesuai dengan filter.'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('web-news-clear-filters')));
      await tester.pumpAndSettle();
      expect(find.text('Kabar banjir Padang'), findsOneWidget);
      expect(find.text('Penanganan longsor'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('carousel safely displays one item and empty feed', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(stories: [stories.first], onStoryTap: (_) {}),
      ),
    );
    expect(find.text('Kabar banjir Padang'), findsWidgets);
    await tester.tap(find.byIcon(Icons.chevron_right).first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(stories: stories, onStoryTap: (_) {}),
      ),
    );
    expect(find.byKey(const ValueKey('home-highlight-101')), findsOneWidget);
    await tester.tap(find.byIcon(Icons.chevron_right).first);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('home-highlight-102')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(stories: const [], onStoryTap: (_) {}),
      ),
    );
    expect(find.text('Belum ada berita utama.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty, loading and error states never substitute demo news', (
    tester,
  ) async {
    var retries = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: NewsPage(
          stories: const [],
          isLoading: true,
          onStoryTap: (_) {},
          onRetry: () => retries++,
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.textContaining('Contoh Berita:'), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        home: NewsPage(
          stories: const [],
          error: 'API unavailable',
          onStoryTap: (_) {},
          onRetry: () => retries++,
        ),
      ),
    );
    expect(find.textContaining('Berita belum dapat dimuat'), findsOneWidget);
    await tester.tap(find.text('Coba lagi'));
    expect(retries, 1);

    await tester.pumpWidget(
      MaterialApp(
        home: NewsPage(stories: const [], onStoryTap: (_) {}),
      ),
    );
    expect(find.text('Belum ada berita tersedia dari server.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('news layout fits phone and desktop widths', (tester) async {
    for (final size in [const Size(390, 844), const Size(1280, 900)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        MaterialApp(
          home: NewsPage(stories: stories, onStoryTap: (_) {}),
        ),
      );
      expect(find.text('Kabar banjir Padang'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        MaterialApp(
          home: HomePage(stories: stories, onStoryTap: (_) {}),
        ),
      );
      expect(find.byKey(const ValueKey('home-highlight-101')), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

HomeStory _story(
  String id,
  String title,
  String category,
  DateTime publishedAt, {
  String region = 'Kota Padang',
}) => HomeStory(
  id: id,
  category: category,
  title: title,
  date: '${publishedAt.day} Oktober ${publishedAt.year}',
  image: '',
  color: 0xFF74839A,
  summary: 'Ringkasan API.',
  content: 'Isi berita API untuk detail.',
  source: 'BNPB',
  region: region,
  publishedAt: publishedAt,
  eventAt: publishedAt,
  isApiRecord: true,
);

Map<String, dynamic> _apiStory() => {
  'id': 101,
  'judul': 'Kabar banjir Padang',
  'kategori': 'Banjir',
  'jenis_konten': 'kejadian',
  'isi': 'Isi berita API untuk detail.',
  'gambar': null,
  'sumber': 'BNPB',
  'sumber_id': 'bnpb-101',
  'url_sumber': 'https://bnpb.go.id/berita/101',
  'wilayah': 'Kota Padang',
  'waktu_publikasi': '2026-10-24T10:30:00Z',
  'waktu_kejadian': '2026-10-24T08:00:00Z',
  'waktu_berakhir': null,
  'waktu_pengambilan': '2026-10-24T11:00:00Z',
  'tingkat_kepentingan': 'normal',
  'status_publikasi': 'published',
};
