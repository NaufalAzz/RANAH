import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ranah_mobile/data/sample_news.dart';
import 'package:ranah_mobile/models/news_item.dart';
import 'package:ranah_mobile/services/gunung_local_store.dart';
import 'package:ranah_mobile/services/news_api.dart';
import 'package:ranah_mobile/services/news_repository.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory tempDirectory;
  late String databasePath;
  late GunungLocalStore store;

  setUpAll(sqfliteFfiInit);
  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('ranah-news-cache-');
    databasePath = '${tempDirectory.path}/ranah.db';
    store = _newStore(databasePath);
  });
  tearDown(() async {
    await store.close();
    await tempDirectory.delete(recursive: true);
  });

  test(
    'server news persists when repository and database are reopened',
    () async {
      final online = await NewsRepository(
        api: _FakeNewsApi([_article(title: 'Berita tersimpan')]),
        localStore: store,
      ).load();
      expect(online.items.single.title, 'Berita tersimpan');
      expect(online.isFromCache, isFalse);

      final syncedAt = online.lastSyncedAt;
      await store.close();
      store = _newStore(databasePath);
      final offline = await NewsRepository(
        api: _FakeNewsApi.failure(),
        localStore: store,
      ).load();

      expect(offline.items, hasLength(1));
      expect(offline.items.single.title, 'Berita tersimpan');
      expect(offline.isUsingFallback, isFalse);
      expect(offline.isFromCache, isTrue);
      expect(offline.lastSyncedAt, syncedAt);
    },
  );

  test('failed synchronization preserves the last valid cache', () async {
    await NewsRepository(
      api: _FakeNewsApi([_article(title: 'Berita lama')]),
      localStore: store,
    ).load();

    final result = await NewsRepository(
      api: _FakeNewsApi.failure(),
      localStore: store,
    ).load();

    expect(result.items.single.title, 'Berita lama');
    expect(result.isFromCache, isTrue);
    expect(result.isUsingFallback, isFalse);
  });

  test(
    'successful empty response replaces cache and remains distinguishable',
    () async {
      await NewsRepository(
        api: _FakeNewsApi([_article()]),
        localStore: store,
      ).load();

      final onlineEmpty = await NewsRepository(
        api: _FakeNewsApi([]),
        localStore: store,
      ).load();
      expect(onlineEmpty.items, isEmpty);
      expect(onlineEmpty.isFromCache, isFalse);
      expect(onlineEmpty.isUsingFallback, isFalse);

      final offlineEmpty = await NewsRepository(
        api: _FakeNewsApi.failure(),
        localStore: store,
      ).load();
      expect(offlineEmpty.items, isEmpty);
      expect(offlineEmpty.isFromCache, isTrue);
      expect(offlineEmpty.isUsingFallback, isFalse);
      expect(offlineEmpty.lastSyncedAt, isNotNull);
    },
  );

  test('demo content is separate from a server cache', () async {
    final noCache = await NewsRepository(
      api: _FakeNewsApi.failure(),
      localStore: store,
    ).load();
    expect(noCache.items, same(sampleNews));
    expect(noCache.isUsingFallback, isTrue);
    expect(noCache.isFromCache, isFalse);

    await NewsRepository(
      api: _FakeNewsApi([_article(title: 'Berita server')]),
      localStore: store,
    ).load();
    final cached = await NewsRepository(
      api: _FakeNewsApi.failure(),
      localStore: store,
    ).load();
    expect(cached.items, hasLength(1));
    expect(cached.items.single.title, 'Berita server');
    expect(cached.items, isNot(containsAll(sampleNews)));
  });

  test('database upgrade preserves existing volcano cache tables', () async {
    final oldDatabase = await databaseFactoryFfi.openDatabase(
      databasePath,
      options: sqflite.OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE gunung (
              id INTEGER PRIMARY KEY,
              nama TEXT,
              aktif INTEGER NOT NULL DEFAULT 1,
              payload TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE laporan_gunung (
              id INTEGER PRIMARY KEY,
              gunung_id INTEGER NOT NULL,
              waktu_publikasi TEXT,
              payload TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE metadata (key TEXT PRIMARY KEY, value TEXT NOT NULL)
          ''');
          await db.insert('gunung', {
            'id': 11,
            'nama': 'Gunung tersimpan',
            'payload': '{"id":11,"nama":"Gunung tersimpan"}',
          });
        },
      ),
    );
    await oldDatabase.close();
    await store.close();
    store = _newStore(databasePath);

    expect((await store.readGunung()).single['nama'], 'Gunung tersimpan');
    expect(await store.readNews(), isEmpty);
  });

  test(
    'valid absolute image URLs map; missing and malformed values fall back',
    () async {
      final valid = await _loadImage('https://media.example.test/berita.jpg');
      final empty = await _loadImage('');
      final relative = await _loadImage('/storage/berita.jpg');
      final credentialed = await _loadImage(
        'https://user:secret@example.test/a.jpg',
      );

      expect(valid.imageUrl, 'https://media.example.test/berita.jpg');
      expect(empty.imageUrl, isNull);
      expect(relative.imageUrl, isNull);
      expect(credentialed.imageUrl, isNull);
    },
  );
}

Future<NewsItem> _loadImage(String? image) async {
  final store = _newStore(inMemoryDatabasePath);
  try {
    final result = await NewsRepository(
      api: _FakeNewsApi([_article(gambar: image)]),
      localStore: store,
    ).load();
    return result.items.single;
  } finally {
    await store.close();
  }
}

GunungLocalStore _newStore(String path) =>
    GunungLocalStore(factory: databaseFactoryFfi, databasePath: path);

Map<String, dynamic> _article({String title = 'Berita uji', String? gambar}) =>
    {
      'id': 7,
      'judul': title,
      'kategori': 'Erupsi',
      'isi': 'Isi berita server.',
      'gambar': gambar,
      'sumber': 'Sumber uji',
      'waktu_publikasi': '2026-10-22T09:00:00.000Z',
    };

class _FakeNewsApi implements NewsApi {
  _FakeNewsApi(this.items) : error = false;

  _FakeNewsApi.failure() : items = const [], error = true;

  final List<dynamic> items;
  final bool error;

  @override
  Future<List<dynamic>> getBerita() async {
    if (error) throw StateError('offline');
    return items;
  }
}
