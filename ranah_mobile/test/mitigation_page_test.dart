import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ranah_mobile/app/ranah_app.dart';

void main() {
  testWidgets('all mitigation stages open matching steps and return', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const RanahApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Menu').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Panduan Mitigasi'));
    await tester.pumpAndSettle();

    const stages = <(String, String)>[
      (
        'Sebelum Erupsi',
        'Kenali tanda peringatan dan ikuti informasi aktivitas gunung api dari sumber resmi.',
      ),
      (
        'Saat Erupsi',
        'Tetap tenang dan ikuti peringatan serta arahan petugas di wilayah Anda.',
      ),
      (
        'Evakuasi',
        'Mulai evakuasi saat diperintahkan petugas atau sesuai informasi resmi yang berlaku.',
      ),
      (
        'Pasca Erupsi',
        'Tetap berada di tempat aman sampai pemerintah atau petugas menyatakan Anda boleh kembali.',
      ),
    ];

    for (final (stage, firstStep) in stages) {
      await _tapVisible(tester, find.text(stage));
      expect(find.text('Panduan Mitigasi'), findsOneWidget);
      expect(find.text(firstStep), findsOneWidget);
      expect(find.text('Kembali'), findsOneWidget);
      expect(
        find.textContaining('Buku Saku Menghadapi Bencana'),
        findsOneWidget,
      );
      expect(
        find.textContaining('ikuti arahan terbaru PVMBG dan BPBD'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Kembali'));
      await tester.pumpAndSettle();
      expect(find.text(stage), findsOneWidget);
    }

    await tester.tap(find.text('Kembali'));
    await tester.pumpAndSettle();
    expect(find.text('Layanan RANAH'), findsOneWidget);
    await tester.tap(find.text('Beranda').last);
    await tester.pumpAndSettle();
    expect(find.text('Berita Utama'), findsOneWidget);

    await tester.tap(find.text('Menu').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Panduan Mitigasi'));
    await tester.pumpAndSettle();
    expect(find.text('Panduan Mitigasi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    180,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
