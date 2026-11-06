import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ranah_accessibility/ranah_accessibility.dart';
import 'package:ranah_mobile/app/main_shell.dart';
import 'package:ranah_mobile/theme/app_theme.dart';

import 'test_helpers.dart';

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
  testWidgets(
    'home contact confirmation and spoken gunung results open mitigation',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final engine = SilentVoiceEngine();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MainShell(
            voiceEngine: engine,
            internetStatusMonitor: createTestInternetStatusMonitor(),
            mapTilesEnabled: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Kontak Darurat'), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(const ValueKey('home-emergency-BNPB')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('home-emergency-BNPB')));
      await tester.pumpAndSettle();
      expect(find.text('Hubungi BNPB?'), findsOneWidget);
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Suara'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('voice-result-guide')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('voice-start')));
      await tester.pumpAndSettle();
      engine.result!('gunung', true);
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('voice-result-guide')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('voice-result-guide')));
      await tester.pumpAndSettle();
      expect(find.text('Sebelum Erupsi'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
