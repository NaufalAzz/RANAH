import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ranah_web/models/gunung_data.dart';
import 'package:ranah_web/pages/volcanic_activity_page.dart';

void main() {
  const longName =
      'Gunung dengan nama panjang untuk menguji susunan daftar yang responsif';
  final records = [
    const GunungRecord(
      id: 1,
      nama: 'Gunung Marapi',
      kabupaten: 'Agam dan Tanah Datar',
      provinsi: 'Sumatera Barat',
      statusAktivitas: 'Level IV - Awas',
      sumberData: 'Sumber API untuk data uji',
    ),
    const GunungRecord(
      id: 2,
      nama: longName,
      statusAktivitas: 'Level II - Waspada',
    ),
    const GunungRecord(id: 3, nama: 'Gunung Tanpa Status'),
    for (var index = 0; index < 12; index++)
      GunungRecord(
        id: 10 + index,
        nama: 'Gunung Contoh $index',
        statusAktivitas: 'Level II - Waspada',
      ),
  ];

  testWidgets(
    'list handles small, tablet, and desktop widths and opens selected ID',
    (tester) async {
      int? selectedId;
      for (final size in [
        const Size(390, 844),
        const Size(768, 1024),
        const Size(1366, 900),
      ]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(
          MaterialApp(
            home: VolcanicActivityPage(
              onBack: () {},
              onViewReport: (gunung) => selectedId = gunung.id,
              gunung: records,
              isLoading: false,
              error: null,
              onRetry: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Gunung Marapi'), findsOneWidget);
        expect(find.text(longName), findsOneWidget);
        expect(find.text('Lokasi administratif belum tersedia'), findsWidgets);
        expect(find.text('Status aktivitas belum tersedia'), findsOneWidget);
        expect(tester.takeException(), isNull);

        if (size.width == 390) {
          final secondReportButton = find.text('Lihat Laporan').at(1);
          await tester.ensureVisible(secondReportButton);
          await tester.tap(secondReportButton);
          expect(selectedId, 2);
        }
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );
}
