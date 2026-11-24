import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ranah_mobile/widgets/page_motion.dart';

void main() {
  testWidgets(
    'tab switches overlap, retain input, and settle after an interruption',
    (tester) async {
      final selection = ValueNotifier(0);
      addTearDown(selection.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<int>(
              valueListenable: selection,
              builder: (context, index, _) => RanahTabStack(
                index: index,
                children: const [TextField(), Text('Peta'), Text('Berita')],
              ),
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'Padang');
      selection.value = 1;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 90));
      expect(find.text('Padang'), findsOneWidget);
      expect(find.text('Peta'), findsOneWidget);
      final fading = tester.widget<Opacity>(
        find
            .ancestor(of: find.text('Peta'), matching: find.byType(Opacity))
            .first,
      );
      expect(fading.opacity, inExclusiveRange(0, 1));
      selection.value = 2;
      await tester.pump();
      selection.value = 0;
      await tester.pumpAndSettle();
      expect(find.text('Padang'), findsOneWidget);
      expect(find.text('Peta'), findsNothing);
      expect(find.text('Berita'), findsNothing);
    },
  );
  testWidgets('reduced motion changes tabs in the next frame', (tester) async {
    final selection = ValueNotifier(0);
    addTearDown(selection.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: ValueListenableBuilder<int>(
            valueListenable: selection,
            builder: (context, index, _) => RanahTabStack(
              index: index,
              children: const [Text('Beranda'), Text('Menu')],
            ),
          ),
        ),
      ),
    );
    selection.value = 1;
    await tester.pump();
    expect(find.text('Menu'), findsOneWidget);
    expect(find.text('Beranda'), findsNothing);
  });
}
