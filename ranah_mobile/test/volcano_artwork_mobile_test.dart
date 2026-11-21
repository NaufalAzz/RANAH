import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ranah_accessibility/ranah_accessibility.dart';
import 'package:ranah_mobile/models/gunung_snapshot.dart';
import 'package:ranah_mobile/pages/volcanic_activity_page.dart';
import 'package:ranah_mobile/services/gunung_repository.dart';
import 'package:ranah_mobile/theme/app_theme.dart';

class _Repository implements GunungDataRepository {
  final snapshot = const GunungListSnapshot(
    items: [
      {
        'id': 8,
        'nama': 'Bromo',
        'provinsi': 'Jawa Timur',
        'status_aktivitas': 'Level II (Waspada)',
      },
      {
        'id': 1,
        'nama': 'Dempo',
        'provinsi': 'Sumatera Barat',
        'status_aktivitas': 'Level II (Waspada)',
      },
    ],
    lastCheckedAt: null,
    isFromCache: false,
  );
  @override
  Future<GunungListSnapshot> readGunungCache() async => snapshot;
  @override
  Future<GunungListSnapshot> syncGunung() async => snapshot;
  @override
  Future<GunungDetailSnapshot?> readDetailCache(int id) async => null;
  @override
  Future<GunungDetailSnapshot> syncDetail(int id) async =>
      throw UnimplementedError();
}

void main() {
  testWidgets(
    'mobile activity displays decoded local illustrations, not only Image widgets',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: VolcanicActivityPage(
              onBack: () {},
              repository: _Repository(),
            ),
          ),
        ),
      );
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 30));
        });
      }
      final artwork = find.byType(VolcanoArtwork);
      expect(artwork, findsNWidgets(2));
      final raw = find.descendant(of: artwork, matching: find.byType(RawImage));
      expect(raw, findsNWidgets(2));
      for (final element in raw.evaluate()) {
        final image = element.renderObject! as RenderImage;
        expect(image.image, isNotNull);
        expect(image.image!.width, 1536);
        expect(image.size.width, greaterThan(0));
      }
      expect(find.text('AI'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
