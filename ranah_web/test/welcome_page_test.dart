import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ranah_web/pages/welcome_page.dart';

void main() {
  for (final width in [390.0, 1280.0]) {
    testWidgets(
      'the intro reveals the name before the tagline and keeps the landscape moving at width $width',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 800);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final surface = GlobalKey();
        var completed = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: RepaintBoundary(
              key: surface,
              child: WelcomePage(onFinished: () => completed++),
            ),
          ),
        );

        final title = find.text('RANAH');
        final clip = find
            .ancestor(of: title, matching: find.byType(ClipRect))
            .first;
        double titleWidth() => tester
            .widget<ClipRect>(clip)
            .clipper!
            .getClip(tester.getSize(title))
            .width;
        final tagline = find
            .ancestor(
              of: find.text('Informasi Bencana dan Evakuasi'),
              matching: find.byType(FadeTransition),
            )
            .first;
        await tester.pump(const Duration(milliseconds: 350));
        expect(titleWidth(), 0);
        await tester.pump(const Duration(milliseconds: 850));
        expect(titleWidth(), inExclusiveRange(0, tester.getSize(title).width));
        expect(tester.widget<FadeTransition>(tagline).opacity.value, 0);
        await tester.pump(const Duration(milliseconds: 650));
        expect(titleWidth(), closeTo(tester.getSize(title).width, .01));
        final first = await _landscapePixels(tester, surface);
        await tester.pump(const Duration(milliseconds: 750));
        expect(
          listEquals(first, await _landscapePixels(tester, surface)),
          isFalse,
        );
        expect(completed, 0);
        await tester.pump(const Duration(milliseconds: 401));
        expect(completed, 1);
        await tester.pump(const Duration(seconds: 3));
        expect(completed, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Lewati works during the entrance and completes once', (
    tester,
  ) async {
    var completed = 0;
    await tester.pumpWidget(
      MaterialApp(home: WelcomePage(onFinished: () => completed++)),
    );
    await tester.tap(find.text('Lewati'));
    expect(completed, 1);
    await tester.pump(const Duration(seconds: 4));
    expect(completed, 1);
  });

  testWidgets(
    'reduced motion goes straight to the app even when enabled mid-intro',
    (tester) async {
      for (final reduceAtStart in [true, false]) {
        var completed = 0;
        final reduceMotion = ValueNotifier(reduceAtStart);
        await tester.pumpWidget(
          MaterialApp(
            home: ValueListenableBuilder<bool>(
              valueListenable: reduceMotion,
              builder: (context, reduce, _) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(disableAnimations: reduce),
                child: WelcomePage(onFinished: () => completed++),
              ),
            ),
          ),
        );
        if (!reduceAtStart) {
          await tester.pump(const Duration(milliseconds: 450));
          expect(completed, 0);
          reduceMotion.value = true;
          await tester.pump();
        }
        expect(completed, 1);
        await tester.pump(const Duration(seconds: 4));
        expect(completed, 1);
        await tester.pumpWidget(const SizedBox.shrink());
        reduceMotion.dispose();
      }
    },
  );
}

// Compare only the mountain band. A moving title or progress bar alone shouldn't pass.
Future<Uint8List> _landscapePixels(
  WidgetTester tester,
  GlobalKey surface,
) async {
  final boundary =
      surface.currentContext!.findRenderObject() as RenderRepaintBoundary;
  return (await tester.runAsync(() async {
    final frame = await boundary.toImage(pixelRatio: .25);
    try {
      final bytes = (await frame.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      final stride = 4 * frame.width;
      return bytes.buffer.asUint8List(
        bytes.offsetInBytes + stride * (frame.height * .67).floor(),
        stride * (frame.height * .2).floor(),
      );
    } finally {
      frame.dispose();
    }
  }))!;
}
