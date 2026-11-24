import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ranah_accessibility/ranah_accessibility.dart';

void main() {
  test(
    'range includes the whole last calendar day and uses the event date',
    () {
      final range = DateTimeRange(
        start: DateTime(2026, 5, 2),
        end: DateTime(2026, 5, 9),
      );
      expect(newsDateMatches(DateTime(2026, 5, 2), range), isTrue);
      expect(newsDateMatches(DateTime(2026, 5, 9, 23, 59), range), isTrue);
      expect(newsDateMatches(DateTime(2026, 5, 10), range), isFalse);
      expect(newsDateMatches(null, range), isFalse);
      expect(newsDateMatches(null, null), isTrue);
    },
  );

  test(
    'BNPB bulletin date-only events overlap both ends and never invent an event time',
    () {
      const body =
          'Catatan BNPB.\n\nTanggal kejadian menurut buletin: 2024-04-16. Waktu kejadian tidak dicantumkan pada kandidat.\nTanggal akhir kejadian menurut buletin: 2024-04-17. Waktu tidak dicantumkan.';
      final days = bnpbBulletinDays('BNPB; instansi daerah', body)!;
      expect(newsDayRangeLabel(days), '16/04/2024 – 17/04/2024');
      for (final day in [15, 16, 17, 18]) {
        final date = DateTime(2024, 4, day);
        expect(
          newsDateMatches(
            null,
            DateTimeRange(start: date, end: date),
            bulletinDays: days,
          ),
          day == 16 || day == 17,
        );
      }
      expect(bnpbBulletinDays('BMKG', body), isNull);
      expect(bnpbBulletinDays('BNPB', 'Rujukan: 2026-05-05'), isNull);
      expect(
        bnpbBulletinDays(
          'BNPB',
          'Tanggal kejadian menurut buletin: 2026-02-30.',
        ),
        isNull,
      );
    },
  );

  test('matches administrative components and common province spellings', () {
    const region = 'Koto Tangah, Kota Padang, SUMATRA BARAT';
    expect(newsRegionMatches(region, 'Padang'), isTrue);
    expect(newsRegionMatches(region, 'Sumatera Barat'), isTrue);
    expect(
      newsRegionMatches('Kota Padang Panjang, Sumatera Barat', 'Padang'),
      isFalse,
    );
    expect(newsRegionMatches('Papua Barat Daya', 'Papua Barat'), isFalse);
    expect(newsRegionMatches(null, 'Aceh'), isFalse);
  });

  testWidgets('users can select an unlisted city even with an empty feed', (
    tester,
  ) async {
    String selected = '';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NewsRegionField(
            value: '',
            locations: const [],
            onChanged: (value) => selected = value,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Semua wilayah'));
    await tester.pumpAndSettle();
    expect(find.text('Aceh'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Kota Pariaman');
    await tester.pump();
    await tester.tap(find.widgetWithText(ListTile, 'Kota Pariaman'));
    await tester.pumpAndSettle();
    expect(selected, 'Kota Pariaman');
  });
}
