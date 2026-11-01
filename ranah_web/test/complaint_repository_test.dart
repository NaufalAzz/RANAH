import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ranah_web/services/complaint_repository.dart';
import 'package:ranah_web/services/ranah_api_client.dart';

void main() {
  test('posts contract fields and image bytes as multipart', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/pengaduan');
      expect(request.headers['accept'], 'application/json');
      expect(
        request.headers['content-type'],
        startsWith('multipart/form-data; boundary='),
      );
      final body = (request).bodyBytes;
      final text = latin1.decode(body);
      for (final field in [
        'name="nama_pelapor"',
        'Pelapor Uji',
        'name="nomor_telepon"',
        '081234567890',
        'name="kategori"',
        'Banjir',
        'name="lokasi_kejadian"',
        'Padang',
        'name="deskripsi"',
        'Kondisi banjir perlu dilaporkan.',
        'name="persetujuan"',
        'true',
        'name="media[]"; filename="foto.jpg"',
        'content-type: image/jpeg',
      ]) {
        expect(text, contains(field));
      }
      expect(_containsBytes(body, [0xff, 0xd8, 0xff, 0xd9]), isTrue);
      return http.Response(
        jsonEncode({
          'success': true,
          'message': 'Pengaduan berhasil diterima.',
          'data': {'id': 42, 'waktu_pengaduan': '2026-10-26T12:00:00Z'},
        }),
        201,
      );
    });
    final repository = ComplaintRepository(
      client: RanahApiClient(
        client: client,
        baseUrl: 'http://localhost:8000/api',
      ),
    );
    addTearDown(repository.close);

    final receipt = await repository.submit(
      reporterName: 'Pelapor Uji',
      phoneNumber: '081234567890',
      category: 'Banjir',
      location: 'Padang',
      description: 'Kondisi banjir perlu dilaporkan.',
      consented: true,
      attachments: [
        ComplaintAttachment(
          name: 'foto.jpg',
          bytes: Uint8List.fromList([0xff, 0xd8, 0xff, 0xd9]),
          contentType: 'image/jpeg',
        ),
      ],
    );

    expect(receipt.id, 42);
    expect(receipt.receivedAt, DateTime.parse('2026-10-26T12:00:00Z'));
  });

  test('sends complaint without files and reports validation fields', () async {
    var hasFiles = true;
    final repository = ComplaintRepository(
      client: RanahApiClient(
        client: MockClient((request) async {
          hasFiles = latin1.decode((request).bodyBytes).contains(
            'name="media[]"',
          );
          return http.Response(
            jsonEncode({
              'message': 'The given data was invalid.',
              'errors': {
                'nomor_telepon': ['Nomor telepon tidak valid.'],
              },
            }),
            422,
          );
        }),
        baseUrl: 'http://localhost:8000/api',
      ),
    );
    addTearDown(repository.close);

    await expectLater(
      repository.submit(
        reporterName: 'Pelapor Uji',
        phoneNumber: 'bad',
        category: 'Banjir',
        location: 'Padang',
        description: 'Isi laporan cukup panjang.',
        consented: true,
      ),
      throwsA(
        isA<ComplaintSubmissionException>()
            .having((error) => error.statusCode, 'status', 422)
            .having(
              (error) => error.fieldErrors['nomor_telepon'],
              'phone validation',
              'Nomor telepon tidak valid.',
            ),
      ),
    );
    expect(hasFiles, isFalse);
  });

  test('maps rate limit and does not treat server errors as success', () async {
    var status = 429;
    final repository = ComplaintRepository(
      client: RanahApiClient(
        client: MockClient((_) async => http.Response('{}', status)),
        baseUrl: 'http://localhost:8000/api',
      ),
    );
    addTearDown(repository.close);

    await expectLater(
      _submitValid(repository),
      throwsA(isA<ComplaintSubmissionException>().having(
        (error) => error.statusCode,
        'status',
        429,
      )),
    );
    status = 500;
    await expectLater(
      _submitValid(repository),
      throwsA(isA<ComplaintSubmissionException>().having(
        (error) => error.statusCode,
        'status',
        500,
      )),
    );
  });

  test('timeout warns that persistence status is unknown', () async {
    final pending = Completer<http.Response>();
    final repository = ComplaintRepository(
      client: RanahApiClient(
        client: MockClient((_) => pending.future),
        baseUrl: 'http://localhost:8000/api',
        timeout: const Duration(milliseconds: 10),
      ),
    );
    addTearDown(repository.close);
    await expectLater(
      repository.submit(
        reporterName: 'Pelapor Uji',
        phoneNumber: '081234567890',
        category: 'Banjir',
        location: 'Padang',
        description: 'Isi laporan cukup panjang.',
        consented: true,
      ),
      throwsA(
        isA<ComplaintSubmissionException>().having(
          (error) => error.message,
          'message',
          contains('status penyimpanan belum diketahui'),
        ),
      ),
    );
    pending.complete(http.Response('{}', 201));
  });
}

Future<ComplaintReceipt> _submitValid(ComplaintRepository repository) =>
    repository.submit(
      reporterName: 'Pelapor Uji',
      phoneNumber: '081234567890',
      category: 'Banjir',
      location: 'Padang',
      description: 'Isi laporan cukup panjang.',
      consented: true,
    );

bool _containsBytes(Uint8List haystack, List<int> needle) {
  for (var start = 0; start <= haystack.length - needle.length; start++) {
    var matches = true;
    for (var offset = 0; offset < needle.length; offset++) {
      if (haystack[start + offset] != needle[offset]) {
        matches = false;
        break;
      }
    }
    if (matches) return true;
  }
  return false;
}
