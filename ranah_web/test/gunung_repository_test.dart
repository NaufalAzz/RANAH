import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ranah_web/models/gunung_data.dart';
import 'package:ranah_web/services/gunung_repository.dart';
import 'package:ranah_web/services/ranah_api_client.dart';

void main() {
  test('maps nullable activity metadata and level without inventing values', () {
    final record = GunungRecord.fromJson({
      'id': 7,
      'nama': 'Gunung Contoh',
      'status_aktivitas': null,
      'latitude': null,
      'longitude': null,
    });

    expect(record.id, 7);
    expect(record.activityLevel, isNull);
    expect(record.latitude, isNull);
    expect(record.statusAktivitas, isNull);
    expect(
      GunungRecord.fromJson({
        'id': 8,
        'nama': 'Gunung Lain',
        'status_aktivitas': 'Level III (Siaga)',
      }).activityLevel,
      3,
    );
  });

  test('detail orders reports by source publication time, not retrieval time', () {
    final detail = GunungDetailRecord.fromJson({
      'gunung': {'id': 4, 'nama': 'Gunung Uji'},
      'laporan': [
        {
          'id': 10,
          'gunung_id': 4,
          'waktu_publikasi': '2026-10-20T00:00:00Z',
          'waktu_pengambilan': '2026-10-26T09:00:00Z',
        },
        {
          'id': 11,
          'gunung_id': 4,
          'waktu_publikasi': '2026-10-24T00:00:00Z',
          'waktu_pengambilan': '2026-10-25T09:00:00Z',
        },
        {'id': 12, 'gunung_id': 4},
      ],
    });

    expect(detail.laporan.map((item) => item.id), [11, 10, 12]);
    expect(detail.laporan.first.waktuPengambilan, DateTime.parse('2026-10-25T09:00:00Z'));
  });

  test('rejects reports associated with a different volcano', () {
    expect(
      () => GunungDetailRecord.fromJson({
        'gunung': {'id': 4, 'nama': 'Gunung Uji'},
        'laporan': [
          {'id': 9, 'gunung_id': 5},
        ],
      }),
      throwsFormatException,
    );
  });

  test('repository maps an empty list and requests normal Laravel endpoint', () async {
    final requests = <Uri>[];
    final repository = GunungRepository(
      client: RanahApiClient(
        baseUrl: 'https://api.example.test/api',
        client: MockClient((request) async {
          requests.add(request.url);
          return http.Response(
            jsonEncode({'success': true, 'data': []}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
    );

    expect(await repository.loadGunung(), isEmpty);
    expect(requests.single.path, '/api/gunung');
    repository.close();
  });

  test('repository preserves API 404 for a missing volcano detail', () async {
    final repository = GunungRepository(
      client: RanahApiClient(
        baseUrl: 'https://api.example.test/api',
        client: MockClient((_) async => http.Response(
          jsonEncode({'message': 'Not found'}),
          404,
          headers: {'content-type': 'application/json'},
        )),
      ),
    );

    await expectLater(
      repository.loadDetail(404),
      throwsA(isA<RanahApiException>().having((error) => error.statusCode, 'statusCode', 404)),
    );
    repository.close();
  });
}
