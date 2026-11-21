import 'package:ranah_web/services/browser_location.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ranah_accessibility/ranah_accessibility.dart';
import 'package:ranah_web/app/ranah_app.dart';
import 'package:ranah_web/pages/mitigation_guide_page.dart';
import 'package:ranah_web/theme/ranah_theme.dart';

class SilentVoiceEngine implements VoiceEngine {
  void Function(String, bool)? result;
  @override
  Future<void> cancel() async {}
  @override
  Future<void> stopSpeaking() async {}
  @override
  Future<void> speak(String text) async {}
  @override
  Future<void> listen({
    required void Function(String, bool) onText,
    required void Function(String) onError,
    required void Function() onDone,
  }) async {
    result = onText;
  }
}

void main() {
  testWidgets('location is requested only after using the map button', (
    tester,
  ) async {
    var requests = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: RanahTheme.light,
        home: RanahShell(
          locationReader: () async {
            requests++;
            return const BrowserLocation(latitude: -0.95, longitude: 100.35);
          },
          areaLookup: (_) async =>
              const BrowserAdministrativeArea(province: 'Sumatera Barat'),
          volcanoMapTilesEnabled: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(requests, 0);
    await tester.tap(find.byKey(const ValueKey('ranah-nav-map')));
    await tester.pumpAndSettle();
    expect(requests, 0);
    final button = find.byKey(const ValueKey('find-device-location'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('accept-location-only')));
    await tester.pumpAndSettle();
    expect(requests, 1);
  });
  testWidgets('web speech results select the existing mitigation page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final engine = SilentVoiceEngine();
    await tester.pumpWidget(
      MaterialApp(
        theme: RanahTheme.light,
        home: RanahShell(voiceEngine: engine, volcanoMapTilesEnabled: false),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Awal'), findsNothing);
    expect(find.text('Kontak Darurat'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('ranah-nav-voice')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('voice-result-guide')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('voice-start')));
    await tester.pumpAndSettle();
    engine.result!('tolong saya mau melihat gunung dan peta', true);
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('voice-result-guide')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('voice-result-guide')));
    await tester.pumpAndSettle();
    expect(find.byType(MitigationGuidePage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
