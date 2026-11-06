import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ranah_mobile/app/ranah_app.dart';
import 'package:ranah_accessibility/ranah_accessibility.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('existing menu opens the illustrated guide and returns', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      RanahApp(
        mapTilesEnabled: false,
        internetStatusMonitor: createTestInternetStatusMonitor(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Menu').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Panduan Mitigasi'));
    await tester.pumpAndSettle();
    for (final lesson in mitigationLessons) {
      final tile = find.byKey(ValueKey('guide-category-${lesson.id}'));
      await tester.ensureVisible(tile);
      await tester.pumpAndSettle();
      await tester.tap(tile);
      await tester.pumpAndSettle();
      expect(find.text(lesson.steps.first.action), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('guide-back')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('guide-back')));
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(find.byKey(const ValueKey('guide-back')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('guide-back')));
    await tester.pumpAndSettle();
    expect(find.text('Layanan RANAH'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
