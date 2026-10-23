import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ranah_mobile/data/sample_news.dart';
import 'package:ranah_mobile/services/news_api.dart';
import 'package:ranah_mobile/services/news_repository.dart';
import 'package:ranah_mobile/services/gunung_local_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory tempDirectory;
  late GunungLocalStore store;

  setUpAll(sqfliteFfiInit);
  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('ranah-news-test-');
    store = GunungLocalStore(
      factory: databaseFactoryFfi,
      databasePath: '${tempDirectory.path}/news.db',
    );
  });
  tearDown(() async {
    await store.close();
    await tempDirectory.delete(recursive: true);
  });

  test('parses published news fields and source', () async {
    final result = await NewsRepository(
      localStore: store,
      api: _FakeNewsApi([
        {
          'id': 42,
          'judul': 'Informasi daerah',
          'kategori': 'Erupsi',
          'isi': 'Isi berita dari server.',
          'sumber': 'BPBD Contoh',
          'gambar': null,
          'waktu_publikasi': '2026-10-22T09:00:00.000000Z',
        },
      ]),
    ).load();

    expect(result.isUsingFallback, isFalse);
    expect(result.items, hasLength(1));
    expect(result.items.single.id, '42');
    expect(result.items.single.title, 'Informasi daerah');
    expect(result.items.single.source, 'BPBD Contoh');
    expect(result.items.single.body, 'Isi berita dari server.');
  });

  test(
    'successful empty response stays empty instead of using examples',
    () async {
      final result = await NewsRepository(
        api: _FakeNewsApi([]),
        localStore: store,
      ).load();

      expect(result.items, isEmpty);
      expect(result.isUsingFallback, isFalse);
    },
  );

  test('network failure returns clearly identified local examples', () async {
    final result = await NewsRepository(
      api: _FakeNewsApi.failure(StateError('offline')),
      localStore: store,
    ).load();

    expect(result.isUsingFallback, isTrue);
    expect(result.items, same(sampleNews));
    expect(result.error, isA<StateError>());
  });

  test(
    'malformed item falls back instead of partially replacing local data',
    () async {
      final result = await NewsRepository(
        api: _FakeNewsApi([
          {'id': 1, 'judul': 'Missing required fields'},
        ]),
        localStore: store,
      ).load();

      expect(result.isUsingFallback, isTrue);
      expect(result.items, same(sampleNews));
      expect(result.error, isA<FormatException>());
    },
  );
}

class _FakeNewsApi implements NewsApi {
  _FakeNewsApi(this.items) : error = null;

  _FakeNewsApi.failure(this.error) : items = const [];

  final List<dynamic> items;
  final Object? error;

  @override
  Future<List<dynamic>> getBerita() async {
    if (error case final value?) throw value;
    return items;
  }
}
