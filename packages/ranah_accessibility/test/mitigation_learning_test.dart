import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ranah_accessibility/ranah_accessibility.dart';

void main() {
  Future<void> open(
    WidgetTester tester, {
    VoidCallback? back,
    bool reduced = false,
    double scale = 1,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: tester.view.physicalSize,
            disableAnimations: reduced,
            textScaler: TextScaler.linear(scale),
          ),
          child: Scaffold(body: MitigationLearningPage(onBack: back ?? () {})),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await Scrollable.ensureVisible(tester.element(finder), alignment: .4);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'every phase presents actions, reasons, avoidances and a summary',
    (tester) async {
      var returned = false;
      await open(tester, back: () => returned = true);
      for (final lesson in mitigationLessons) {
        await tap(tester, find.byKey(ValueKey('guide-category-${lesson.id}')));
        for (var i = 0; i < lesson.steps.length; i++) {
          expect(
            find.text('Langkah ${i + 1} dari ${lesson.steps.length}'),
            findsOneWidget,
          );
          expect(find.text(lesson.steps[i].action), findsOneWidget);
          expect(find.text(lesson.steps[i].reason), findsOneWidget);
          expect(find.text(lesson.steps[i].avoid), findsOneWidget);
          await tap(tester, find.byKey(const ValueKey('guide-step-next')));
        }
        expect(find.text(lesson.takeaway), findsOneWidget);
        await tap(tester, find.byKey(const ValueKey('guide-choose-another')));
      }
      await tap(tester, find.byKey(const ValueKey('guide-back')));
      expect(returned, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'sources show the selected action reference and open the exact official link',
    (tester) async {
      const channel = MethodChannel('plugins.flutter.io/url_launcher');
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return true;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      await open(tester);
      await tap(
        tester,
        find.byKey(const ValueKey('guide-category-before-eruption')),
      );
      await tap(tester, find.text('Sumber materi'));
      expect(find.textContaining(bnpbPreparation.title), findsWidgets);
      expect(find.text('Diakses ${GuideSource.checkedAt}'), findsOneWidget);
      await tap(tester, find.text('Buka sumber resmi'));
      expect(calls, hasLength(1));
      expect((calls.single.arguments as Map)['url'], bnpbPreparation.url);
    },
  );
  testWidgets(
    'reduced motion stays static and step back restores the previous action',
    (tester) async {
      await open(tester, reduced: true);
      await tap(
        tester,
        find.byKey(const ValueKey('guide-category-during-eruption')),
      );
      expect(find.textContaining('Ilustrasi statis'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('guide-animation-toggle')),
        findsNothing,
      );
      await tap(tester, find.byKey(const ValueKey('guide-step-next')));
      await tap(tester, find.byKey(const ValueKey('guide-step-previous')));
      expect(
        find.text(mitigationLessons[1].steps.first.action),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'illustration can be replayed and paused without an endless ticker',
    (tester) async {
      await open(tester);
      await tap(
        tester,
        find.byKey(const ValueKey('guide-category-before-eruption')),
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('guide-animation-toggle')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('guide-animation-toggle')));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Jeda animasi'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('guide-animation-toggle')));
      await tester.pumpAndSettle();
      expect(find.text('Putar ilustrasi'), findsOneWidget);
    },
  );
  testWidgets('guide fits phones with enlarged text and desktop widths', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    for (final width in [320.0, 390.0, 1280.0]) {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      await open(tester, reduced: true);
      for (final lesson in mitigationLessons) {
        await tap(tester, find.byKey(ValueKey('guide-category-${lesson.id}')));
        await tap(tester, find.byKey(const ValueKey('guide-step-next')));
        expect(
          tester.takeException(),
          isNull,
          reason: '${lesson.id} at $width',
        );
        await tap(tester, find.byKey(const ValueKey('guide-back')));
      }
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
