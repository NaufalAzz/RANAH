import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ranah_web/widgets/ranah_header.dart';

void main() {
  testWidgets('bell badge follows the earthquake count and hides at zero', (
    tester,
  ) async {
    Widget header(int count) => MaterialApp(
      home: Scaffold(
        body: RanahHeader(
          selected: RanahDestination.home,
          onSelect: (_) {},
          onNotifications: () {},
          notificationCount: count,
        ),
      ),
    );
    await tester.pumpWidget(header(3));
    expect(find.text('3'), findsOneWidget);
    await tester.pumpWidget(header(0));
    expect(find.text('3'), findsNothing);
  });
}
