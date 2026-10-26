import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ranah_web/services/notifications_repository.dart';
import 'package:ranah_web/services/ranah_api_client.dart';

void main() {
  test('parses notification metadata and requests the selected page', () async {
    late Uri requestedUri;
    final repository = NotificationsRepository(
      client: RanahApiClient(
        baseUrl: 'https://api.example.test/api',
        client: MockClient((request) async {
          requestedUri = request.url;
          return http.Response(jsonEncode(_feed()), 200);
        }),
      ),
    );

    final result = await repository.load(page: 2);

    expect(requestedUri.path, '/api/notifikasi');
    expect(requestedUri.queryParameters, {'page': '2', 'per_page': '30'});
    expect(result.items, hasLength(1));
    expect(result.items.single.title, 'Gempa di Sumbar');
    expect(result.items.single.eventAt, DateTime.parse('2026-10-25T01:00:00Z'));
    expect(result.items.single.publishedAt, isNull);
    expect(result.items.single.retrievedAt, DateTime.parse('2026-10-25T01:02:00Z'));
    expect(result.items.single.region, 'Kota Padang');
    expect(result.items.single.source, 'BMKG');
    expect(result.sourceUpdatedAt, DateTime.parse('2026-10-25T01:03:00Z'));
    expect(result.currentPage, 2);
    expect(result.lastPage, 3);
    expect(result.total, 61);
  });

  test('accepts a successful empty response as an empty feed', () async {
    final repository = NotificationsRepository(
      client: RanahApiClient(
        baseUrl: 'http://localhost:8000/api',
        client: MockClient((_) async => http.Response(
          jsonEncode({
            'success': true,
            'data': [],
            'meta': {'total': 0, 'current_page': 1, 'last_page': 1},
          }),
          200,
        )),
      ),
    );

    final result = await repository.load(page: 1);
    expect(result.items, isEmpty);
    expect(result.total, 0);
  });

  test('reports HTTP errors without substituting sample notifications', () async {
    final repository = NotificationsRepository(
      client: RanahApiClient(
        baseUrl: 'https://api.example.test/api',
        client: MockClient((_) async => http.Response(
          jsonEncode({'message': 'Server unavailable'}),
          503,
        )),
      ),
    );

    await expectLater(
      repository.load(page: 1),
      throwsA(
        isA<RanahApiException>()
            .having((error) => error.statusCode, 'statusCode', 503)
            .having((error) => error.message, 'message', 'Server unavailable'),
      ),
    );
  });

  test('rejects malformed JSON', () async {
    final repository = NotificationsRepository(
      client: RanahApiClient(
        baseUrl: 'https://api.example.test/api',
        client: MockClient((_) async => http.Response('<html>bad</html>', 200)),
      ),
    );

    await expectLater(
      repository.load(page: 1),
      throwsA(isA<RanahApiException>().having(
        (error) => error.message,
        'message',
        'Respons JSON dari API tidak valid.',
      )),
    );
  });
}

Map<String, dynamic> _feed() => {
  'success': true,
  'data': [
    {
      'id': 12,
      'judul': 'Gempa di Sumbar',
      'kategori': 'Gempa bumi',
      'jenis_konten': 'kejadian',
      'ringkasan': 'Informasi dari fixture API.',
      'wilayah': 'Kota Padang',
      'cakupan_wilayah': 'Sumatera Barat',
      'sumber': 'BMKG',
      'sumber_id': 'bmkg-quake:fixture-12',
      'url_sumber': 'https://data.bmkg.go.id/DataMKG/TEWS/gempadirasakan.json',
      'waktu_kejadian': '2026-10-25T01:00:00Z',
      'waktu_publikasi': null,
      'waktu_pengambilan': '2026-10-25T01:02:00Z',
      'waktu_berakhir': null,
      'status': 'informasi',
    },
  ],
  'meta': {
    'current_page': 2,
    'last_page': 3,
    'per_page': 30,
    'total': 61,
    'waktu_pembaruan_terakhir_bmkg': '2026-10-25T01:03:00Z',
    'rentang_gempa_hari': 7,
  },
};
