import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ranah_web/pages/emergency_contacts_page.dart';
import 'package:ranah_web/services/complaint_repository.dart';
import 'package:ranah_web/services/ranah_api_client.dart';

void main() {
  testWidgets('requires consent and sends once before confirming success', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var requests = 0;
    final response = Completer<http.Response>();
    final repository = ComplaintRepository(
      client: RanahApiClient(
        client: MockClient((request) async {
          requests++;
          final body = latin1.decode((request).bodyBytes);
          expect(body, contains('name="persetujuan"'));
          expect(body, contains('\r\n\r\ntrue\r\n'));
          return response.future;
        }),
        baseUrl: 'http://localhost:8000/api',
      ),
    );
    addTearDown(repository.close);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmergencyContactsPage(
            onBack: () {},
            complaintRepository: repository,
            filePicker: () async => const [],
          ),
        ),
      ),
    );
    await _openComplaintForm(tester);
    await _fillValidForm(tester);

    final submit = find.byKey(const ValueKey('complaint-submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text('Persetujuan diperlukan sebelum mengirim.'), findsOneWidget);
    expect(requests, 0);

    await tester.tap(find.byKey(const ValueKey('complaint-consent')));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();
    expect(requests, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(submit);
    await tester.pump();
    expect(requests, 1);

    response.complete(
      http.Response(
        jsonEncode({
          'success': true,
          'message': 'Pengaduan berhasil diterima.',
          'data': {'id': 73, 'waktu_pengaduan': '2026-10-26T12:00:00Z'},
        }),
        201,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Server menerima pengaduan #73'), findsOneWidget);
    expect(requests, 1);
    for (final field in tester.widgetList<TextFormField>(find.byType(TextFormField))) {
      expect(field.controller?.text ?? '', isEmpty);
    }
  });

  testWidgets('keeps user entries and shows server validation after failure', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = ComplaintRepository(
      client: RanahApiClient(
        client: MockClient((_) async => http.Response(
          jsonEncode({
            'message': 'The given data was invalid.',
            'errors': {
              'lokasi_kejadian': ['Lokasi wajib diisi.'],
            },
          }),
          422,
        )),
        baseUrl: 'http://localhost:8000/api',
      ),
    );
    addTearDown(repository.close);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmergencyContactsPage(
            onBack: () {},
            complaintRepository: repository,
            filePicker: () async => const [],
          ),
        ),
      ),
    );
    await _openComplaintForm(tester);
    await _fillValidForm(tester);
    await tester.tap(find.byKey(const ValueKey('complaint-consent')));
    final submit = find.byKey(const ValueKey('complaint-submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('complaint-submit-error')),
      findsOneWidget,
    );
    expect(tester.widgetList<TextFormField>(find.byType(TextFormField)).first.controller!.text, 'Pelapor Uji');
    expect(find.text('KIRIM LAPORAN'), findsOneWidget);
  });
}

Future<void> _openComplaintForm(WidgetTester tester) async {
  await tester.tap(find.text('Pengaduan').last);
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('complaint-submit')), findsOneWidget);
}

Future<void> _fillValidForm(WidgetTester tester) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), 'Pelapor Uji');
  await tester.enterText(fields.at(1), '081234567890');
  await tester.enterText(fields.at(2), 'Padang, Sumatera Barat');
  await tester.enterText(fields.at(3), 'Kondisi banjir perlu dilaporkan.');
  final category = find.byKey(const ValueKey('complaint-category'));
  await tester.ensureVisible(category);
  await tester.tap(category);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Banjir').last);
  await tester.pumpAndSettle();
}
