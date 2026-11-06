import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ranah_web/app/ranah_app.dart';
import 'package:ranah_web/data/home_stories.dart';
import 'package:ranah_web/services/news_repository.dart';
import 'package:ranah_web/theme/ranah_theme.dart';

class EmptyNews extends NewsRepository {
  @override
  Future<List<HomeStory>> load() async => [];
}

void main() {
  testWidgets('web home opens an offline action without API', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: RanahTheme.light,
        home: RanahShell(newsRepository: EmptyNews()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tindakan Sekarang'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terkena hujan abu'));
    await tester.pumpAndSettle();
    expect(find.text('Langkah 1 dari 4'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
