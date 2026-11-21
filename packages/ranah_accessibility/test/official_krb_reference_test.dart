import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ranah_accessibility/ranah_accessibility.dart';

void main() {
  test(
    'official raster references match 40 exact volcano names and source URLs',
    () {
      expect(officialKrbReferences, hasLength(40));
      for (final entry in officialKrbReferences.entries) {
        expect(volcanoReference(entry.key), isNotNull);
        expect(normalizeVolcanoName(entry.value.name), entry.key);
        expect(entry.value.year, inInclusiveRange(1990, 2026));
        final uri = Uri.parse(entry.value.imageUrl);
        expect(uri.scheme, 'https');
        expect(uri.host, 'magma.esdm.go.id');
        expect(uri.path, startsWith('/storage/krb-gunungapi/'));
      }
      expect(officialKrbReference('Gunung Anak Krakatau')?.year, 2007);
      expect(officialKrbReference('Merapi'), isNull);
      expect(officialKrbReference('Hobal'), isNull);
      expect(officialKrbReference('Lamongan'), isNull);
      expect(officialKrbReference('Gunung tidak dikenal'), isNull);
    },
  );

  testWidgets('official map action appears only for a verified document', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              OfficialKrbMapButton(name: 'Anak Krakatau'),
              OfficialKrbMapButton(name: 'Hobal'),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Lihat peta KRB resmi'), findsOneWidget);
  });
}
