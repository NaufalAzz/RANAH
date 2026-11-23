import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ranah_mobile/widgets/brand_header.dart';

void main() {
  testWidgets('bell badge reflects earthquake count', (tester) async {
    Widget header(int count) => MaterialApp(
      home: Scaffold(body: BrandHeader(notificationCount: count)),
    );
    await tester.pumpWidget(header(4));
    expect(find.text('4'), findsOneWidget);
    await tester.pumpWidget(header(0));
    expect(find.text('4'), findsNothing);
  });
}
