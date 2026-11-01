import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ranah_web/services/hazard_analysis_repository.dart';
import 'package:ranah_web/services/ranah_api_client.dart';

void main() {
  test(
    'posts exact coordinates and parses every returned KRB feature',
    () async {
      late http.Request sentRequest;
      final client = RanahApiClient(
        baseUrl: 'https://api.example.test/api',
        client: MockClient((request) async {
          sentRequest = request;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'waktu_analisis': '2026-10-26T10:00:00+07:00',
                'sistem_koordinat': 'EPSG:4326',
                'bahaya': {
                  'tsunami': {
                    'status': 'klasifikasi_belum_diverifikasi',
                    'penjelasan': 'Nilai piksel tersedia.',
                    'dataset': 'layer_bahaya_tsunami',
                    'sumber': 'BNPB InaRISK GIS Services',
                    'url_sumber': 'https://gis.bnpb.go.id/tsunami',
                    'tahun_data': null,
                    'resolusi_piksel_meter': 100,
                    'sistem_koordinat_dataset': 'EPSG:3395',
                    'nilai_piksel': 0.0224382,
                    'klasifikasi': null,
                    'keterbatasan': 'Kelas belum diverifikasi.',
                  },
                  'banjir': {
                    'status': 'layanan_bermasalah',
                    'penjelasan': 'Informasi sementara tidak dapat dimuat.',
                    'dataset': 'layer_bahaya_banjir',
                  },
                  'gempa_bumi': {
                    'status': 'klasifikasi_belum_diverifikasi',
                    'penjelasan':
                        'Indeks bahaya tersedia; kelas belum diverifikasi.',
                    'dataset': 'INDEKS_BAHAYA_GEMPABUMI',
                    'jenis_nilai': 'Indeks bahaya gempa ternormalisasi (0–1), bukan persentase.',
                    'tipe_nilai': 'Float32',
                    'url_metodologi': 'https://inarisk.bnpb.go.id/metodologi',
                    'metode_query': 'ArcGIS ImageServer Identify.',
                    'sumber': 'BNPB InaRISK GIS Services',
                    'url_sumber': 'https://gis.bnpb.go.id/earthquake',
                    'tahun_data': null,
                    'resolusi_piksel_meter': 100,
                    'sistem_koordinat_dataset': 'EPSG:3395',
                    'nilai_piksel': 0.42,
                    'klasifikasi': null,
                    'keterbatasan': 'Bukan prediksi atau peringatan.',
                  },
                  'letusan_gunung_api': {
                    'status': 'hasil_tersedia',
                    'penjelasan': 'Ada irisan fitur.',
                    'metode': 'point-intersects',
                    'sumber': 'BIG',
                    'url_sumber': 'https://big.example/layer',
                    'keterbatasan': 'Tahun peta dapat lama.',
                    'fitur': [
                      {
                        'nama_gunung': 'MARAPI',
                        'zona_krb': 'KRB I',
                        'indga': 1,
                        'tahun_peta': 2006,
                        'id_fitur_sumber': 277,
                      },
                      {
                        'nama_gunung': 'MARAPI',
                        'zona_krb': 'KRB II',
                        'indga': 2,
                        'tahun_peta': 2006,
                        'id_fitur_sumber': 278,
                      },
                    ],
                  },
                },
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      final repository = HazardAnalysisRepository(client: client);

      final result = await repository.analyze(
        latitude: -0.381234567,
        longitude: 100.473456789,
      );

      expect(sentRequest.method, 'POST');
      expect(sentRequest.url.path, '/api/peta/analisis-bahaya');
      expect(jsonDecode(sentRequest.body), {
        'latitude': -0.381234567,
        'longitude': 100.473456789,
      });
      expect(result.volcano.features, hasLength(2));
      expect(
        result.volcano.features.map((feature) => feature.sourceFeatureId),
        [277, 278],
      );
      expect(result.volcano.features.first.mapYear, 2006);
      expect(result.volcano.limitations, 'Tahun peta dapat lama.');
      expect(result.tsunami.status, 'klasifikasi_belum_diverifikasi');
      expect(result.tsunami.pixelValue, 0.0224382);
      expect(result.tsunami.year, isNull);
      expect(result.tsunami.classification, isNull);
      expect(result.tsunami.spatialReference, 'EPSG:3395');
      expect(result.flood.status, 'layanan_bermasalah');
      expect(result.earthquake.status, 'klasifikasi_belum_diverifikasi');
      expect(result.earthquake.dataset, 'INDEKS_BAHAYA_GEMPABUMI');
      expect(result.earthquake.valueType, contains('bukan persentase'));
      expect(result.earthquake.dataType, 'Float32');
      expect(
        result.earthquake.methodologyUrl,
        'https://inarisk.bnpb.go.id/metodologi',
      );
      expect(result.earthquake.queryMethod, 'ArcGIS ImageServer Identify.');
      expect(result.earthquake.pixelValue, 0.42);
      expect(result.earthquake.classification, isNull);
      repository.close();
    },
  );

  test(
    'rejects non-success HTTP response without pretending there is no hazard',
    () async {
      final repository = HazardAnalysisRepository(
        client: RanahApiClient(
          baseUrl: 'https://api.example.test/api',
          client: MockClient(
            (_) async => http.Response('{"message":"busy"}', 429),
          ),
        ),
      );

      await expectLater(
        repository.analyze(latitude: -0.9, longitude: 100.4),
        throwsA(isA<RanahApiException>()),
      );
      repository.close();
    },
  );
}
