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
          'url_sumber': 'https://bpbd.example.id/berita/1',
          'jenis_konten': 'kejadian',
          'wilayah': 'Kota Padang',
          'gambar': null,
          'waktu_publikasi': '2026-10-22T09:00:00.000000Z',
          'waktu_kejadian': '2026-10-22T08:30:00.000000Z',
          'waktu_berakhir': null,
          'waktu_pengambilan': '2026-10-22T09:01:00.000000Z',
        },
      ]),
    ).load();

    expect(result.isUsingFallback, isFalse);
    expect(result.items, hasLength(1));
    expect(result.items.single.id, '42');
    expect(result.items.single.title, 'Informasi daerah');
    expect(result.items.single.source, 'BPBD Contoh');
    expect(result.items.single.body, 'Isi berita dari server.');
    expect(result.items.single.contentType, 'kejadian');
    expect(result.items.single.sourceUrl, 'https://bpbd.example.id/berita/1');
    expect(result.items.single.region, 'Kota Padang');
    expect(result.items.single.eventAt, DateTime.parse('2026-10-22T08:30:00Z'));
    expect(result.items.single.expiresAt, isNull);
    expect(
      result.items.single.retrievedAt,
      DateTime.parse('2026-10-22T09:01:00Z'),
    );
    expect(result.hasUpdates, isTrue);
  });

  test('unchanged server data does not report another update', () async {
    final api = _FakeNewsApi([
      _articleFixture(id: 401, source: 'BNPB', eventAt: '2026-05-05T00:00:00Z'),
    ]);
    final repository = NewsRepository(api: api, localStore: store);

    expect((await repository.load()).hasUpdates, isTrue);
    expect((await repository.load()).hasUpdates, isFalse);
  });

  test('parses imported archive rows from the normal published feed', () async {
    final result = await NewsRepository(
      localStore: store,
      api: _FakeNewsApi([
        {
          'id': 48,
          'judul': 'Arsip kejadian BNPB',
          'kategori': 'Tanah longsor',
          'jenis_konten': 'kejadian',
          'isi': 'Tanggal kejadian menurut buletin: 2026-05-05.',
          'sumber': 'BNPB',
          'url_sumber': null,
          'wilayah': 'Agam, Sumatera Barat',
          'waktu_publikasi': '2026-10-24T10:00:00Z',
          'waktu_kejadian': null,
          'waktu_berakhir': null,
          'waktu_pengambilan': '2026-10-24T10:00:00Z',
          'status_publikasi': 'published',
        },
      ]),
    ).load();

    expect(result.isUsingFallback, isFalse);
    expect(result.items, hasLength(1));
    expect(
      result.items.single.publishedAt,
      isNot('Tanggal publikasi tidak tersedia'),
    );
    expect(result.items.single.body, contains('2026-05-05'));
    expect(result.items.single.eventAt, isNull);
  });

  test('parses BMKG alert metadata and keeps source URL HTTPS-only', () async {
    final expiresAt = DateTime.now().add(const Duration(days: 1));
    final result = await NewsRepository(
      api: _FakeNewsApi([
        _articleFixture(
          id: 43,
          source: 'BMKG',
          sourceUrl: 'https://www.bmkg.go.id/alerts/nowcast/id/fixture.xml',
          type: 'peringatan',
          region: 'Kota Padang',
          eventAt: '2026-10-24T02:30:00Z',
          expiresAt: expiresAt.toUtc().toIso8601String(),
          retrievedAt: '2026-10-24T02:45:00Z',
        ),
      ]),
      localStore: store,
    ).load();

    final item = result.items.single;
    expect(item.source, 'BMKG');
    expect(item.contentType, 'peringatan');
    expect(item.sourceUrl, startsWith('https://'));
    expect(item.region, 'Kota Padang');
    expect(item.eventAt, DateTime.parse('2026-10-24T02:30:00Z'));
    expect(item.expiresAt, expiresAt.toUtc());
    expect(item.retrievedAt, DateTime.parse('2026-10-24T02:45:00Z'));
  });

  test(
    'generic article without BMKG metadata remains a normal article',
    () async {
      final result = await NewsRepository(
        api: _FakeNewsApi([_articleFixture(id: 44, source: 'Redaksi RANAH')]),
        localStore: store,
      ).load();

      final item = result.items.single;
      expect(item.contentType, 'artikel');
      expect(item.source, 'Redaksi RANAH');
      expect(item.sourceUrl, isNull);
      expect(item.region, isNull);
      expect(item.eventAt, isNull);
      expect(item.expiresAt, isNull);
      expect(item.retrievedAt, isNull);
    },
  );

  test('invalid or non-HTTPS source URLs are omitted', () async {
    final result = await NewsRepository(
      api: _FakeNewsApi([
        _articleFixture(id: 45, sourceUrl: 'http://insecure.example.test/a'),
        _articleFixture(
          id: 46,
          sourceUrl: 'https://user:secret@example.test/a',
        ),
        _articleFixture(id: 47, source: 42),
      ]),
      localStore: store,
    ).load();

    expect(result.items.map((item) => item.sourceUrl), [null, null, null]);
    expect(result.items.last.source, isNull);
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

  test('expired and unbounded warnings are not displayed or cached', () async {
    final result = await NewsRepository(
      api: _FakeNewsApi([
        {
          'id': 9,
          'judul': 'Peringatan lewat',
          'kategori': 'Imbauan/penanganan bencana',
          'jenis_konten': 'peringatan',
          'isi': 'Sudah berakhir.',
          'sumber': 'BMKG',
          'waktu_publikasi': '2026-10-22T09:00:00Z',
          'waktu_berakhir': '2020-01-01T00:00:00Z',
        },
        {
          'id': 10,
          'judul': 'Tanpa akhir',
          'kategori': 'Imbauan/penanganan bencana',
          'jenis_konten': 'peringatan',
          'isi': 'Tanpa masa aktif.',
          'sumber': 'BMKG',
          'waktu_publikasi': '2026-10-22T09:00:00Z',
        },
      ]),
      localStore: store,
    ).load();

    expect(result.items, isEmpty);
    expect(result.isUsingFallback, isFalse);
    expect(await store.readNews(), isEmpty);
  });

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

Map<String, dynamic> _articleFixture({
  required int id,
  Object? source,
  String? sourceUrl,
  String? type,
  String? region,
  String? eventAt,
  String? expiresAt,
  String? retrievedAt,
}) => {
  'id': id,
  'judul': 'Fixture berita $id',
  'kategori': type == 'peringatan' ? 'Imbauan/penanganan bencana' : 'Erupsi',
  'isi': 'Konten fixture pengujian, bukan kejadian BMKG live.',
  'sumber': source,
  'url_sumber': sourceUrl,
  'jenis_konten': type,
  'wilayah': region,
  'waktu_publikasi': '2026-10-24T02:50:00Z',
  'waktu_kejadian': eventAt,
  'waktu_berakhir': expiresAt,
  'waktu_pengambilan': retrievedAt,
};
