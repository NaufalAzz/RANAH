import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ranah_mobile/app/ranah_app.dart';
import 'package:ranah_mobile/services/news_api.dart';
import 'package:ranah_mobile/services/news_repository.dart';
import 'package:ranah_mobile/services/gunung_local_store.dart';
import 'package:ranah_mobile/widgets/news_feed_notice.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory tempDirectory;
  late GunungLocalStore store;

  setUpAll(sqfliteFfiInit);
  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('ranah-news-widget-');
    store = GunungLocalStore(
      factory: databaseFactoryFfi,
      databasePath: '${tempDirectory.path}/news.db',
    );
  });
  tearDown(() async {
    await store.close();
    await tempDirectory.delete(recursive: true);
  });

  testWidgets('shows offline examples while the server request is pending', (
    tester,
  ) async {
    final api = _CompletingNewsApi();
    await tester.pumpWidget(
      RanahApp(
        newsRepository: NewsRepository(api: api, localStore: store),
      ),
    );
    await tester.pump();

    expect(
      find.textContaining('Menampilkan konten contoh lokal'),
      findsOneWidget,
    );
    expect(find.textContaining('Contoh:'), findsWidgets);

    api.completer.complete([_newsItem()]);
    await _flushLocalDatabase(tester);
    await tester.pumpAndSettle();
    expect(find.text('Berita uji server'), findsOneWidget);
    expect(
      find.textContaining('Menampilkan konten contoh lokal'),
      findsNothing,
    );
  });

  testWidgets(
    'successful empty server response is shown as empty, not examples',
    (tester) async {
      await tester.pumpWidget(
        RanahApp(
          newsRepository: NewsRepository(
            api: _ImmediateNewsApi([]),
            localStore: store,
          ),
        ),
      );
      await _flushLocalDatabase(tester);
      await tester.pumpAndSettle();

      expect(
        find.text('Belum ada berita yang dipublikasikan.'),
        findsOneWidget,
      );
      expect(find.textContaining('Contoh:'), findsNothing);
      await tester.tap(find.text('Berita'));
      await tester.pumpAndSettle();
      expect(
        find.text('Belum ada berita yang dipublikasikan.'),
        findsOneWidget,
      );
      expect(find.textContaining('Contoh:'), findsNothing);
    },
  );

  testWidgets('server article appears with its source in detail', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      RanahApp(
        newsRepository: NewsRepository(
          api: _ImmediateNewsApi([_newsItem()]),
          localStore: store,
        ),
      ),
    );
    await _flushLocalDatabase(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Berita'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Berita uji server'));
    await tester.tap(find.text('Berita uji server'));
    await tester.pumpAndSettle();

    expect(find.text('Sumber berita: BPBD uji'), findsOneWidget);
    expect(
      find.text('Isi berita dari server untuk pengujian.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Menampilkan konten contoh lokal'),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('offline cache notice includes its last sync time', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NewsFeedNotice(
            isUsingFallback: false,
            isLoading: false,
            isFromCache: true,
            lastSyncedAt: DateTime(2026, 10, 23, 14, 5),
          ),
        ),
      ),
    );

    expect(find.textContaining('tersimpan secara offline'), findsOneWidget);
    expect(
      find.textContaining('Sinkronisasi terakhir: 23/10/2026 14:05'),
      findsOneWidget,
    );
  });
}

Future<void> _flushLocalDatabase(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 1)));
  await tester.pumpAndSettle();
}

Map<String, dynamic> _newsItem() => {
  'id': 23,
  'judul': 'Berita uji server',
  'kategori': 'Erupsi',
  'isi': 'Isi berita dari server untuk pengujian.',
  'sumber': 'BPBD uji',
  'gambar': null,
  'waktu_publikasi': '2026-10-22T09:00:00.000000Z',
};

class _ImmediateNewsApi implements NewsApi {
  _ImmediateNewsApi(this.items);

  final List<dynamic> items;

  @override
  Future<List<dynamic>> getBerita() async => items;
}

class _CompletingNewsApi implements NewsApi {
  final completer = Completer<List<dynamic>>();

  @override
  Future<List<dynamic>> getBerita() => completer.future;
}
