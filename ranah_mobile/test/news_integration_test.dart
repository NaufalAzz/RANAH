import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ranah_mobile/app/ranah_app.dart';
import 'package:ranah_mobile/services/news_api.dart';
import 'package:ranah_mobile/services/news_repository.dart';
import 'package:ranah_mobile/services/gunung_local_store.dart';
import 'package:ranah_mobile/widgets/news_feed_notice.dart';

import 'test_helpers.dart';

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
        internetStatusMonitor: createTestInternetStatusMonitor(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Contoh:'), findsWidgets);

    api.completer.complete([_newsItem()]);
    await _flushLocalDatabase(tester);
    await tester.pumpAndSettle();
    expect(find.text('Berita berhasil diperbarui.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Berita'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Berita uji server'),
      160,
      scrollable: _newsScrollable().first,
    );
    expect(find.text('Berita uji server'), findsOneWidget);
  });

  testWidgets(
    'successful empty server response is shown as empty, not examples',
    (tester) async {
      await tester.pumpWidget(
        RanahApp(
          internetStatusMonitor: createTestInternetStatusMonitor(),
          newsRepository: NewsRepository(
            api: _ImmediateNewsApi([]),
            localStore: store,
          ),
        ),
      );
      await tester.pumpAndSettle();
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
        internetStatusMonitor: createTestInternetStatusMonitor(),
        newsRepository: NewsRepository(
          api: _ImmediateNewsApi([_newsItem()]),
          localStore: store,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _flushLocalDatabase(tester);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Berita'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Berita uji server'),
      160,
      scrollable: _newsScrollable().first,
    );
    await tester.tap(find.text('Berita uji server'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Sumber berita: BPBD uji'), findsOneWidget);
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

  testWidgets('BMKG detail shows metadata and opens only the HTTPS source', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const sourceChannel = MethodChannel('plugins.flutter.io/url_launcher');
    final launched = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(sourceChannel, (call) async {
          launched.add(call);
          return true;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(sourceChannel, null),
    );

    await tester.pumpWidget(
      RanahApp(
        internetStatusMonitor: createTestInternetStatusMonitor(),
        newsRepository: NewsRepository(
          api: _ImmediateNewsApi([_bmkgFixture()]),
          localStore: store,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _flushLocalDatabase(tester);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Berita'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Peringatan fixture BMKG'),
      160,
      scrollable: _newsScrollable().first,
    );
    await tester.tap(find.text('Peringatan fixture BMKG'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Berlaku sejak: ${_formatFixtureDateTime(DateTime.parse('2026-10-24T09:00:00+07:00'))}',
      ),
      findsOneWidget,
    );
    final expirationLabel = find.text(
      'Berakhir: ${_formatFixtureDateTime(DateTime.parse('2026-10-25T09:00:00+07:00'))}',
    );
    await tester.scrollUntilVisible(
      expirationLabel,
      180,
      scrollable: _detailScrollable().first,
    );
    expect(expirationLabel, findsOneWidget);
    expect(find.text('Wilayah: Kota Padang'), findsOneWidget);
    expect(
      find.text(
        'Data diambil: ${_formatFixtureDateTime(DateTime.parse('2026-10-24T09:05:00+07:00'))}',
      ),
      findsOneWidget,
    );
    final sourceButton = find.text('Sumber resmi: BMKG');
    await tester.scrollUntilVisible(
      sourceButton,
      180,
      scrollable: _detailScrollable().first,
    );
    await tester.drag(
      find.byKey(const PageStorageKey('news-detail-scroll')),
      const Offset(0, -220),
    );
    await tester.pumpAndSettle();
    await tester.tap(sourceButton);
    await tester.pumpAndSettle();

    expect(launched, hasLength(1));
    expect(launched.single.method, 'launch');
    expect(
      (launched.single.arguments as Map)['url'],
      'https://www.bmkg.go.id/alerts/nowcast/id/fixture.xml',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('news update notice floats and disappears after five seconds', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(NewsFeedNotice.updated()),
                child: const Text('Tampilkan notifikasi'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Tampilkan notifikasi'));
    await tester.pumpAndSettle();
    expect(find.text('Berita berhasil diperbarui.'), findsOneWidget);
    expect(
      tester.widget<SnackBar>(find.byType(SnackBar)).behavior,
      SnackBarBehavior.floating,
    );
    expect(
      tester.widget<SnackBar>(find.byType(SnackBar)).duration,
      const Duration(seconds: 5),
    );
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('Berita berhasil diperbarui.'), findsNothing);
  });
}

Finder _newsScrollable() => find.descendant(
  of: find.byKey(const PageStorageKey('news-list-scroll')),
  matching: find.byType(Scrollable),
);

Finder _detailScrollable() => find.descendant(
  of: find.byKey(const PageStorageKey('news-detail-scroll')),
  matching: find.byType(Scrollable),
);

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

Map<String, dynamic> _bmkgFixture() => {
  'id': 24,
  'judul': 'Peringatan fixture BMKG',
  'kategori': 'Imbauan/penanganan bencana',
  'isi': 'Konten fixture uji integrasi, bukan peringatan BMKG live.',
  'jenis_konten': 'peringatan',
  'sumber': 'BMKG',
  'url_sumber': 'https://www.bmkg.go.id/alerts/nowcast/id/fixture.xml',
  'wilayah': 'Kota Padang',
  'waktu_publikasi': '2026-10-24T09:05:00+07:00',
  'waktu_kejadian': '2026-10-24T09:00:00+07:00',
  'waktu_berakhir': '2026-10-25T09:00:00+07:00',
  'waktu_pengambilan': '2026-10-24T09:05:00+07:00',
};

String _formatFixtureDateTime(DateTime value) {
  final local = value.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/${local.year} '
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

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
