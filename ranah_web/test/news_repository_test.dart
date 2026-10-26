import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ranah_web/services/news_repository.dart';
import 'package:ranah_web/services/ranah_api_client.dart';

void main() {
  test('maps Laravel news to HomeStory and removes duplicate IDs', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/api/berita');
      return http.Response(jsonEncode({
        'success': true,
        'data': [
          _news(id: 21, title: 'Pertama'),
          _news(id: 21, title: 'Duplikat'),
          _news(id: 22, title: 'Kedua', publication: '2026-10-25T12:00:00Z'),
        ],
      }), 200);
    });
    final repository = NewsRepository(
      client: RanahApiClient(client: client, baseUrl: 'http://localhost:8000/api'),
    );
    addTearDown(repository.close);

    final stories = await repository.load();
    expect(stories.map((story) => story.id), ['22', '21']);
    final story = stories.last;
    expect(story.title, 'Pertama');
    expect(story.category, 'Banjir');
    expect(story.content, 'Isi berita dari backend.');
    expect(story.source, 'BNPB');
    expect(story.sourceId, 'bnpb-21');
    expect(story.region, 'Sumatera Barat');
    expect(story.sourceUrl, 'https://bnpb.go.id/berita/21');
    expect(story.imageUrl, 'http://localhost:8000/api/berita/21/gambar');
    expect(story.publishedAt, DateTime.parse('2026-10-24T10:30:00Z'));
    expect(story.eventAt, DateTime.parse('2026-10-24T08:00:00Z'));
    expect(story.expiresAt, isNull);
    expect(story.isApiRecord, isTrue);
    expect(story.date, '24 Oktober 2026');
  });

  test('accepts successful empty response', () async {
    final repository = NewsRepository(
      client: RanahApiClient(
        client: MockClient((_) async => http.Response(
          jsonEncode({'success': true, 'data': []}),
          200,
        )),
        baseUrl: 'http://localhost:8000/api',
      ),
    );
    addTearDown(repository.close);
    expect(await repository.load(), isEmpty);
  });

  test('reports HTTP errors and does not silently use sample stories', () async {
    final repository = NewsRepository(
      client: RanahApiClient(
        client: MockClient((_) async => http.Response('Unavailable', 503)),
        baseUrl: 'http://localhost:8000/api',
      ),
    );
    addTearDown(repository.close);
    await expectLater(repository.load(), throwsA(isA<RanahApiException>()));
  });

  test('reports network and timeout failures', () async {
    final networkRepository = NewsRepository(
      client: RanahApiClient(
        client: MockClient((_) async => throw http.ClientException('offline')),
        baseUrl: 'http://localhost:8000/api',
      ),
    );
    addTearDown(networkRepository.close);
    await expectLater(networkRepository.load(), throwsA(isA<RanahApiException>()));

    final pending = Completer<http.Response>();
    final timeoutRepository = NewsRepository(
      client: RanahApiClient(
        client: MockClient((_) => pending.future),
        baseUrl: 'http://localhost:8000/api',
        timeout: const Duration(milliseconds: 10),
      ),
    );
    addTearDown(timeoutRepository.close);
    await expectLater(timeoutRepository.load(), throwsA(isA<RanahApiException>()));
    pending.complete(http.Response('{}', 200));
  });

  test('rejects malformed records and unsafe source/image URLs', () async {
    final invalidSource = _news(id: 5, title: 'Catatan')
      ..['url_sumber'] = 'http://unsafe.example/source'
      ..['gambar'] = 'javascript:alert(1)';
    final repository = NewsRepository(
      client: RanahApiClient(
        client: MockClient((_) async => http.Response(jsonEncode({
          'success': true,
          'data': [invalidSource],
        }), 200)),
        baseUrl: 'http://localhost:8000/api',
      ),
    );
    addTearDown(repository.close);
    final story = (await repository.load()).single;
    expect(story.sourceUrl, isNull);
    expect(story.imageUrl, isNull);
    expect(story.isApiRecord, isTrue);
  });
}

Map<String, dynamic> _news({
  required int id,
  required String title,
  String publication = '2026-10-24T10:30:00Z',
}) => {
  'id': id,
  'judul': title,
  'kategori': 'Banjir',
  'jenis_konten': 'kejadian',
  'isi': 'Isi berita dari backend.',
  'gambar': 'http://localhost:8000/api/berita/21/gambar',
  'sumber': 'BNPB',
  'sumber_id': 'bnpb-$id',
  'url_sumber': 'https://bnpb.go.id/berita/$id',
  'wilayah': 'Sumatera Barat',
  'waktu_publikasi': publication,
  'waktu_kejadian': '2026-10-24T08:00:00Z',
  'waktu_berakhir': null,
  'waktu_pengambilan': '2026-10-24T11:00:00Z',
  'tingkat_kepentingan': 'normal',
  'status_publikasi': 'published',
};
