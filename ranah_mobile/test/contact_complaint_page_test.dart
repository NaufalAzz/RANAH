import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ranah_mobile/app/ranah_app.dart';
import 'package:ranah_mobile/data/sample_emergency_contacts.dart';
import 'package:ranah_mobile/models/emergency_contact.dart';

void main() {
  test('bundled contacts have unique ids and source metadata', () {
    final ids = sampleEmergencyContacts.map((contact) => contact.id).toSet();
    expect(ids.length, sampleEmergencyContacts.length);

    for (final contact in sampleEmergencyContacts) {
      expect(contact.displayNumber.trim(), isNotEmpty);
      expect(contact.sourceTitle.trim(), isNotEmpty);
      expect(contact.sourceOrganization.trim(), isNotEmpty);
      expect(contact.sourceUrl.startsWith('https://'), isTrue);
      expect(contact.sourceAccessedAt, '23 Oktober 2026');
      if (contact.numberVerified) {
        expect(contact.dialNumbers, isNotEmpty);
      } else {
        expect(contact.dialNumbers, isEmpty);
      }
    }
  });

  test('unverified contact attribution does not claim official verification', () {
    const unverified = EmergencyContact(
      id: 'example',
      name: 'Kontak contoh',
      organization: 'Contoh',
      displayNumber: '123',
      dialNumbers: [],
      icon: Icons.phone,
      numberVerified: false,
      sourceTitle: 'Sumber belum diperiksa',
      sourceOrganization: 'Contoh',
      sourceUrl: 'https://example.invalid',
      sourceAccessedAt: '—',
    );
    expect(unverified.sourceAttribution, 'Nomor belum diverifikasi');
  });

  testWidgets(
    'offline emergency contacts show sources and keep dial confirmation',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const channel = MethodChannel('ranah/phone_dialer');
      final dialedNumbers = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            dialedNumbers.add(call.arguments['number'] as String);
            return true;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );

      await tester.pumpWidget(const RanahApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Menu').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kontak Darurat & Pengaduan'));
      await tester.pumpAndSettle();

      expect(find.text('Kontak & Pengaduan'), findsOneWidget);
      expect(
        find.text('Badan Nasional Pencarian dan Pertolongan'),
        findsOneWidget,
      );
      await tester.tap(find.text('115'));
      await tester.pumpAndSettle();
      expect(find.text('Buka Telepon 115'), findsOneWidget);
      expect(find.textContaining('Kontak Darurat SAR'), findsOneWidget);
      expect(dialedNumbers, isEmpty);
      await tester.tap(find.text('Buka Telepon 115'));
      await tester.pumpAndSettle();
      expect(dialedNumbers, ['115']);

      await tester.tap(find.text('117'));
      await tester.pumpAndSettle();
      expect(find.text('Buka Telepon 117'), findsOneWidget);
      expect(
        find.textContaining('BNPB menyediakan Call Center 117'),
        findsOneWidget,
      );
      await tester.tap(find.text('Buka Telepon 117'));
      await tester.pumpAndSettle();
      expect(dialedNumbers, ['115', '117']);

      await tester.tap(find.text('Pengaduan'));
      await tester.pumpAndSettle();
      expect(find.text('Form Pengaduan'), findsOneWidget);
      await _scrollTap(tester, find.text('KIRIM LAPORAN'));
      expect(find.text('Nama pelapor wajib diisi.'), findsOneWidget);
      expect(find.text('Masukkan nomor telepon yang valid.'), findsOneWidget);
      expect(find.text('Pilih kategori pengaduan.'), findsOneWidget);
      expect(find.text('Lokasi kejadian wajib diisi.'), findsOneWidget);
      expect(find.text('Deskripsi kejadian wajib diisi.'), findsOneWidget);

      await _enterVisible(
        tester,
        find.byType(TextFormField).at(0),
        'Pelapor Contoh',
      );
      await _enterVisible(
        tester,
        find.byType(TextFormField).at(1),
        '081234567890',
      );
      final categoryField = find.byType(DropdownButtonFormField<String>);
      await tester.ensureVisible(categoryField);
      await tester.pumpAndSettle();
      await tester.tap(categoryField);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Erupsi gunung api').last);
      await tester.pumpAndSettle();
      await _enterVisible(
        tester,
        find.byType(TextFormField).at(2),
        'Lokasi Contoh',
      );
      await _enterVisible(
        tester,
        find.byType(TextFormField).at(3),
        'Contoh laporan untuk menguji formulir lokal.',
      );
      await _scrollTap(tester, find.byType(CheckboxListTile));
      await _scrollTap(tester, find.text('KIRIM LAPORAN'));
      expect(
        find.text('Tersimpan sementara di sesi aplikasi: 1'),
        findsOneWidget,
      );
      expect(find.text('belum dikirim ke server'), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Kembali ke Menu'));
      await tester.pumpAndSettle();
      expect(find.text('Layanan RANAH'), findsOneWidget);
      await tester.tap(find.text('Beranda').last);
      await tester.pumpAndSettle();
      expect(find.text('Berita Utama'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _scrollTap(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    180,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _enterVisible(
  WidgetTester tester,
  Finder finder,
  String value,
) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.enterText(finder, value);
}
