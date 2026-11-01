import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ranah_web/models/gunung_data.dart';
import 'package:ranah_web/services/administrative_area_lookup.dart';
import 'package:ranah_web/services/browser_location.dart';
import 'package:ranah_web/services/ranah_api_client.dart';

void main() {
  test(
    'reverse lookup reads province and caches the coordinate result',
    () async {
      var requests = 0;
      final lookup = OpenStreetMapAreaLookup(
        client: RanahApiClient(
          baseUrl: 'https://api.example.test/api',
          client: MockClient((request) async {
            requests++;
            expect(request.url.host, 'api.example.test');
            expect(request.url.path, '/api/peta/alamat');
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'address': {
                    'state': 'Sumatera Barat',
                    'city': 'Kota Padang',
                    'suburb': 'Padang Barat',
                    'road': 'Jalan Contoh',
                    'district': 'Kecamatan Contoh',
                    'city_district': 'label administratif lain',
                  },
                  'display_name': 'Jalan Contoh, Padang Barat, Kota Padang',
                  'sumber': 'Nominatim / OpenStreetMap',
                  'waktu_pengambilan': '2026-10-28T00:00:00+00:00',
                },
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }),
        ),
      );
      const location = BrowserLocation(latitude: -0.91, longitude: 100.46);

      final first = await lookup.call(location);
      final second = await lookup.call(location);
      expect(first?.province, 'Sumatera Barat');
      expect(first?.regency, 'Kota Padang');
      expect(second?.locality, 'Padang Barat');
      expect(first?.street, 'Jalan Contoh');
      expect(first?.district, 'Kecamatan Contoh');
      expect(first?.displayName, contains('Jalan Contoh'));
      expect(requests, 1);
    },
  );

  test('filters by normalized exact province and sorts verified distances', () {
    const origin = BrowserLocation(latitude: 0, longitude: 100);
    const records = [
      GunungRecord(
        id: 1,
        nama: 'Dekat',
        provinsi: 'Sumatera Barat',
        latitude: 0.1,
        longitude: 100,
        statusValidasiKoordinat: 'terverifikasi',
      ),
      GunungRecord(
        id: 2,
        nama: 'Jauh',
        provinsi: 'Provinsi Sumatera Barat',
        latitude: 1,
        longitude: 100,
        statusValidasiKoordinat: 'terverifikasi',
      ),
      GunungRecord(id: 3, nama: 'Tanpa jarak', provinsi: 'Sumbar'),
      GunungRecord(
        id: 4,
        nama: 'Provinsi berbeda',
        provinsi: 'Sumatera Selatan',
        latitude: 0.01,
        longitude: 100,
        statusValidasiKoordinat: 'terverifikasi',
      ),
      GunungRecord(
        id: 5,
        nama: 'Koordinat belum sah',
        provinsi: 'Sumatera Barat',
        latitude: 0.001,
        longitude: 100,
        statusValidasiKoordinat: 'belum terverifikasi',
      ),
    ];

    final result = volcanoesForProvince(
      records: records,
      province: 'West Sumatra',
      origin: origin,
    );
    expect(result.map((item) => item.record.id), [1, 2, 5, 3]);
    expect(result[0].distanceKm, closeTo(11.12, .1));
    expect(result[2].distanceKm, isNull);
    expect(result[3].distanceKm, isNull);
  });

  test('unknown region yields no province match', () {
    expect(
      volcanoesForProvince(
        records: const [
          GunungRecord(id: 1, nama: 'Marapi', provinsi: 'Sumatera Barat'),
        ],
        province: 'Unknown Area',
        origin: const BrowserLocation(latitude: 0, longitude: 0),
      ),
      isEmpty,
    );
  });

  test('reverse lookup rejects HTTP and malformed responses', () async {
    final unavailable = OpenStreetMapAreaLookup(
      client: RanahApiClient(
        baseUrl: 'https://api.example.test/api',
        client: MockClient(
          (_) async => http.Response('{"message":"offline"}', 503),
        ),
      ),
    );
    await expectLater(
      unavailable.call(const BrowserLocation(latitude: -1, longitude: 100)),
      throwsA(isA<RanahApiException>()),
    );

    final malformed = OpenStreetMapAreaLookup(
      client: RanahApiClient(
        baseUrl: 'https://api.example.test/api',
        client: MockClient((_) async => http.Response('{}', 200)),
      ),
    );
    await expectLater(
      malformed.call(const BrowserLocation(latitude: -2, longitude: 101)),
      throwsFormatException,
    );
  });

  test('does not infer district from a city_district-only label', () async {
    final lookup = OpenStreetMapAreaLookup(
      client: RanahApiClient(
        baseUrl: 'https://api.example.test/api',
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'address': {
                  'city_district': 'Label kecamatan yang tidak pasti',
                },
                'display_name': 'Kota Padang, Sumatera Barat',
                'sumber': 'Nominatim / OpenStreetMap',
              },
            }),
            200,
          ),
        ),
      ),
    );

    final result = await lookup.call(
      const BrowserLocation(latitude: -0.91, longitude: 100.46),
    );
    expect(result?.district, isNull);
  });
}
