import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ranah_mobile/app/ranah_app.dart';

import 'test_helpers.dart';

import 'package:ranah_mobile/data/sample_emergency_contacts.dart';
import 'package:ranah_mobile/models/emergency_contact.dart';
import 'package:ranah_mobile/services/complaint_api.dart';
import 'package:ranah_mobile/services/complaint_media_picker.dart';

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

  test(
    'unverified contact attribution does not claim official verification',
    () {
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
    },
  );

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

      final complaintApi = _FakeComplaintApi();
      final mediaPicker = _FakeMediaPicker();
      await tester.pumpWidget(
        RanahApp(
          complaintApi: complaintApi,
          mediaPicker: mediaPicker,
          internetStatusMonitor: createTestInternetStatusMonitor(),
        ),
      );
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
      await _scrollTap(tester, find.text('115'));
      expect(find.text('Buka Telepon 115'), findsOneWidget);
      expect(find.textContaining('Kontak Darurat SAR'), findsOneWidget);
      expect(dialedNumbers, isEmpty);
      await tester.tap(find.text('Buka Telepon 115'));
      await tester.pumpAndSettle();
      expect(dialedNumbers, ['115']);

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
      await _scrollTap(tester, find.text('Pilih foto dari galeri'));
      expect(mediaPicker.pickCount, 1);
      await _scrollTap(tester, find.byType(CheckboxListTile));
      await _scrollTap(tester, find.text('KIRIM LAPORAN'));
      expect(find.text('Berhasil dikirim dari sesi ini: 1'), findsOneWidget);
      expect(find.text('Pengaduan Berhasil Dikirim'), findsOneWidget);
      expect(complaintApi.lastSubmission?['reporterName'], 'Pelapor Contoh');
      expect(complaintApi.lastSubmission?['phoneNumber'], '081234567890');
      expect(complaintApi.lastSubmission?['consented'], isTrue);
      expect(complaintApi.lastSubmission?['attachmentCount'], 1);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kembali ke Menu'));
      await tester.pumpAndSettle();
      expect(find.text('Layanan RANAH'), findsOneWidget);
      await tester.tap(find.text('Beranda').last);
      await tester.pumpAndSettle();
      expect(find.text('Berita Utama'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('failed server submission keeps form data and shows no success', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      RanahApp(
        complaintApi: _FakeComplaintApi(shouldFail: true),
        internetStatusMonitor: createTestInternetStatusMonitor(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Menu').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kontak Darurat & Pengaduan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pengaduan'));
    await tester.pumpAndSettle();

    await _enterVisible(
      tester,
      find.byType(TextFormField).at(0),
      'Pelapor Uji',
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
    await tester.tap(find.text('Banjir').last);
    await tester.pumpAndSettle();
    await _enterVisible(tester, find.byType(TextFormField).at(2), 'Lokasi Uji');
    await _enterVisible(
      tester,
      find.byType(TextFormField).at(3),
      'Deskripsi yang harus tetap tersimpan di formulir.',
    );
    await _scrollTap(tester, find.byType(CheckboxListTile));
    await _scrollTap(tester, find.text('KIRIM LAPORAN'));

    expect(find.textContaining('Uji gagal'), findsOneWidget);
    expect(find.text('Pengaduan Berhasil Dikirim'), findsNothing);
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).at(0))
          .controller!
          .text,
      'Pelapor Uji',
    );
    expect(
      find.text('Belum ada pengaduan yang terkirim dari sesi ini.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

class _FakeComplaintApi implements ComplaintApi {
  _FakeComplaintApi({this.shouldFail = false});

  final bool shouldFail;
  Map<String, Object?>? lastSubmission;

  @override
  Future<ComplaintSubmissionReceipt> submitComplaint({
    required String reporterName,
    required String phoneNumber,
    required String category,
    required String location,
    required String description,
    required bool consented,
    List<XFile> attachments = const [],
  }) async {
    if (shouldFail) {
      throw const ComplaintApiException(
        'Uji gagal. Data tetap di formulir; coba lagi.',
      );
    }
    lastSubmission = {
      'reporterName': reporterName,
      'phoneNumber': phoneNumber,
      'category': category,
      'location': location,
      'description': description,
      'consented': consented,
      'attachmentCount': attachments.length,
    };
    return ComplaintSubmissionReceipt(
      id: 17,
      receivedAt: DateTime(2026, 10, 24, 10, 15),
    );
  }
}

class _FakeMediaPicker implements ComplaintMediaPicker {
  int pickCount = 0;

  @override
  Future<List<XFile>> pickImages() async {
    pickCount++;
    return [XFile('/tmp/dokumentasi-uji.jpg', name: 'dokumentasi-uji.jpg')];
  }
}

Future<void> _scrollTap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
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
