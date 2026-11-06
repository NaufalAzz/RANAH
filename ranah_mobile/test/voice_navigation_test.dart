import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ranah_accessibility/ranah_accessibility.dart';
import 'package:ranah_mobile/app/main_shell.dart';
import 'package:ranah_mobile/theme/app_theme.dart';

import 'test_helpers.dart';

class SilentVoiceEngine implements VoiceEngine {
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
  }) async {}
}

void main() {
  testWidgets('home contacts are direct and voice fallback opens mitigation', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MainShell(
          voiceEngine: SilentVoiceEngine(),
          internetStatusMonitor: createTestInternetStatusMonitor(),
          mapTilesEnabled: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Kontak Darurat'), findsOneWidget);
    await tester.ensureVisible(find.text('BNPB · 117\nTelepon'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('BNPB · 117\nTelepon'));
    await tester.pumpAndSettle();
    expect(find.text('Hubungi BNPB?'), findsOneWidget);
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Suara'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Panduan'));
    await tester.tap(find.text('Panduan'));
    await tester.pumpAndSettle();
    expect(find.text('Sebelum Erupsi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
