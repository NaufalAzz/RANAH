import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ranah_web/app/ranah_app.dart';
import 'package:ranah_web/services/gunung_repository.dart';
import 'package:ranah_web/services/news_repository.dart';
import 'package:ranah_web/services/ranah_api_client.dart';

void main() {
  testWidgets(
    'activity list opens API detail and preserves source timestamps',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final listItem = {
        'id': 5,
        'nama': 'Gunung Marapi',
        'provinsi': 'Sumatera Barat',
        'kabupaten': 'Agam dan Tanah Datar',
        'status_aktivitas': 'Level II (Waspada)',
        'sumber_data': 'MAGMA Indonesia',
        'waktu_pengambilan': '2026-10-25T18:00:06Z',
      };
      final detail = {
        'gunung': listItem,
        'laporan': [
          {
            'id': 51,
            'gunung_id': 5,
            'periode_mulai': '2026-10-24',
            'periode_selesai': '2026-10-24',
            'pengamatan_visual': 'Data pengamatan fixture.',
            'rekomendasi': 'Ikuti informasi dari sumber terkait.',
            'sumber': 'MAGMA Indonesia',
            'waktu_publikasi': '2026-10-24T00:00:00Z',
            'waktu_pengambilan': '2026-10-25T07:05:56Z',
            'url_sumber': 'https://magma.esdm.go.id/v1/gunung-api/laporan/51',
          },
        ],
      };

      http.Response responseFor(http.Request request) {
        final path = request.url.path;
        final data = path.endsWith('/gunung/5')
            ? detail
            : path.endsWith('/berita')
            ? <Object>[]
            : [listItem];
        return http.Response(
          jsonEncode({'success': true, 'data': data}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      RanahApiClient client() => RanahApiClient(
        baseUrl: 'https://api.example.test/api',
        client: MockClient((request) async => responseFor(request)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: RanahShell(
            gunungRepository: GunungRepository(client: client()),
            newsRepository: NewsRepository(client: client()),
            volcanoMapTilesEnabled: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Peta').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Laporan Aktivitas Gunung'));
      await tester.pumpAndSettle();

      expect(find.text('Gunung Marapi'), findsOneWidget);
      expect(find.textContaining('Level II (Waspada)'), findsOneWidget);
      expect(find.textContaining('Gunung Semeru'), findsNothing);

      final reportButton = find.text('Lihat Laporan').first;
      await tester.ensureVisible(reportButton);
      await tester.tap(reportButton);
      for (var frame = 0; frame < 12; frame++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('Data pengamatan fixture.'), findsOneWidget);
      expect(
        find.textContaining('Waktu publikasi sumber: 24/10/2026'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Waktu pengambilan server: 25/10/2026'),
        findsOneWidget,
      );
      expect(find.textContaining('Gunung Api - DATA CONTOH'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
