import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ranah_accessibility/ranah_accessibility.dart';

void main() {
  testWidgets(
    'all six bundled atlases decode with the expected grid dimensions',
    (tester) async {
      await tester.runAsync(() async {
        for (final suffix in ['', '-1', '-2', '-3', '-4', '-5']) {
          final data = await rootBundle.load(
            'packages/ranah_accessibility/assets/volcano-atlas$suffix.webp',
          );
          final codec = await ui.instantiateImageCodec(
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          );
          final frame = await codec.getNextFrame();
          expect(frame.image.width, 1536, reason: suffix);
          expect(frame.image.height, 1024, reason: suffix);
          frame.image.dispose();
          codec.dispose();
        }
      });
    },
  );

  test(
    'MAGMA references preserve distinct volcano identities and valid coordinates',
    () {
      expect(volcanoReferences, hasLength(69));
      for (final name in volcanoReferences.keys) {
        expect(hasVolcanoIllustration(name), isTrue, reason: name);
      }
      expect(hasVolcanoIllustration('G. Lewotobi Laki'), isTrue);
      expect(hasVolcanoIllustration('Gunung tidak dikenal'), isFalse);
      for (final r in volcanoReferences.values) {
        expect(r.latitude, inInclusiveRange(-90, 90));
        expect(r.longitude, inInclusiveRange(-180, 180));
      }
      expect(volcanoReference('G. Bromo')?.latitude, -7.942);
      expect(volcanoReference('Gunung Marapi')?.longitude, 100.473);
      expect(volcanoReference('Merapi')?.longitude, isNot(100.473));
      expect(volcanoReference('Gunung yang belum dikenal'), isNull);
    },
  );
  testWidgets(
    'illustrations have no overlay and unknown names keep the map fallback',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 180,
              child: VolcanoArtwork(name: 'Bromo'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Ilustrasi AI · Bromo'), findsNothing);
      expect(find.text('AI'), findsNothing);
      expect(find.byTooltip('Bromo'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 180,
              child: VolcanoArtwork(name: 'Gunung tidak dikenal'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Peta lokasi · Gunung tidak dikenal'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
