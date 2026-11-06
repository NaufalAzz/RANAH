import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ranah_accessibility/ranah_accessibility.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  const volcano = {
    'id': 1,
    'nama': 'Marapi',
    'provinsi': 'Sumatera Barat',
    'status_aktivitas': 'Level II',
    'sumber_data': 'Sumber uji',
  };
  Future<void> open(
    WidgetTester tester,
    EruptionSection section, {
    VolcanoDetailLoader? detail,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: EruptionCenterPage(
          key: UniqueKey(),
          section: section,
          onContacts: () {},
          loadVolcanoes: () async => [volcano],
          loadDetail:
              detail ??
              (_) async => {
                'gunung': volcano,
                'laporan': [
                  {'rekomendasi': 'Rekomendasi uji', 'sumber': 'Sumber uji'},
                ],
              },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.pumpAndSettle();
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  test('scope classifier keeps lahar and excludes other disasters', () {
    expect(isEruptionContent('Lahar'), isTrue);
    expect(isEruptionContent('Aktivitas gunung api'), isTrue);
    expect(isEruptionContent('Gempa'), isFalse);
    expect(resolveVoiceCommand('tindakan sekarang'), [
      VoiceDestination.actions,
    ]);
    expect(resolveVoiceCommand('latihan'), [VoiceDestination.training]);
  });
  testWidgets('immediate action opens one step at a time without API', (
    tester,
  ) async {
    await open(tester, EruptionSection.actions);
    await tap(tester, 'Terkena hujan abu');
    expect(find.text('Langkah 1 dari 4'), findsOneWidget);
    await tap(tester, 'Langkah berikutnya');
    expect(find.text('Langkah 2 dari 4'), findsOneWidget);
    expect(find.textContaining('gunakan masker'), findsOneWidget);
  });
  testWidgets(
    'selected report persists offline and failed refresh retains it',
    (tester) async {
      await open(tester, EruptionSection.follow);
      await tap(tester, 'Muat daftar gunung');
      await tap(tester, 'Marapi');
      await tap(tester, 'Perbarui dan simpan laporan offline');
      expect((await EruptionStore().read())['savedAt'], isNotNull);
      await open(
        tester,
        EruptionSection.follow,
        detail: (_) async => throw Exception('offline'),
      );
      expect(find.textContaining('Rekomendasi uji'), findsOneWidget);
      await tap(tester, 'Perbarui dan simpan laporan offline');
      expect(find.textContaining('Pembaruan gagal'), findsOneWidget);
      expect((await EruptionStore().read())['detail'], isNotNull);
    },
  );
  testWidgets('training gives feedback and stores result without timer', (
    tester,
  ) async {
    await open(tester, EruptionSection.training);
    for (final question in eruptionTraining) {
      await tap(tester, question.options[question.correct]);
      expect(find.text('Pilihan sesuai panduan.'), findsOneWidget);
      await tap(tester, 'Lanjutkan');
    }
    expect(find.textContaining('Latihan selesai: 3'), findsOneWidget);
    expect((await EruptionStore().read())['trainingScore'], 3);
    await open(tester, EruptionSection.training);
    expect(find.textContaining('Latihan sebelumnya: 3'), findsOneWidget);
  });
  testWidgets('local page never invents operational village directions', (
    tester,
  ) async {
    await open(tester, EruptionSection.local);
    expect(
      find.textContaining('belum memiliki pengumuman desa'),
      findsOneWidget,
    );
    expect(
      find.textContaining('tidak otomatis menjadi perintah'),
      findsOneWidget,
    );
  });
}
