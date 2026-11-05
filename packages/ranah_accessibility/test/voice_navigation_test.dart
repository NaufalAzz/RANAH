import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ranah_accessibility/ranah_accessibility.dart';

class FakeVoiceEngine implements VoiceEngine {
  int starts = 0;
  int cancels = 0;
  bool denied = false;
  void Function(String, bool)? result;
  @override
  Future<void> listen({
    required void Function(String, bool) onText,
    required void Function(String) onError,
    required void Function() onDone,
  }) async {
    starts++;
    result = onText;
    if (denied)
      throw UnsupportedError('Izin mikrofon ditolak. Pilih tombol fitur.');
  }

  @override
  Future<void> cancel() async {
    cancels++;
  }

  @override
  Future<void> speak(String text) async {}
  @override
  Future<void> stopSpeaking() async {}
}

void main() {
  test(
    'Indonesian aliases navigate without executing unknown or negative speech',
    () {
      expect(resolveVoiceCommand('Tolong buka panduan!'), [
        VoiceDestination.guide,
      ]);
      expect(resolveVoiceCommand('menu'), [VoiceDestination.menu]);
      expect(resolveVoiceCommand('Buka menu kontak darurat'), [
        VoiceDestination.contacts,
      ]);
      expect(resolveVoiceCommand('status gunung'), [VoiceDestination.activity]);
      expect(resolveVoiceCommand('EVAKUASI'), [
        VoiceDestination.guide,
        VoiceDestination.map,
      ]);
      expect(resolveVoiceCommand('jangan buka peta'), isEmpty);
      expect(resolveVoiceCommand('peta panduan'), isEmpty);
      expect(resolveVoiceCommand(''), isEmpty);
      expect(resolveVoiceCommand('telepon 117'), isEmpty);
    },
  );

  Future<void> openSheet(
    WidgetTester tester,
    FakeVoiceEngine engine,
    void Function(VoiceDestination?) onSelected,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => onSelected(
                await showVoiceNavigation(context, engine: engine),
              ),
              child: const Text('Suara'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Suara'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'opening sheet does not request mic; final speech navigates once',
    (tester) async {
      final engine = FakeVoiceEngine();
      VoiceDestination? selected;
      await openSheet(tester, engine, (value) => selected = value);
      expect(engine.starts, 0);
      await tester.tap(find.text('Mulai bicara'));
      await tester.pumpAndSettle();
      expect(engine.starts, 1);
      engine.result!('panduan', false);
      await tester.pump();
      expect(selected, isNull);
      engine.result!('panduan', true);
      await tester.pumpAndSettle();
      expect(selected, VoiceDestination.guide);
      expect(engine.cancels, greaterThan(0));
    },
  );

  testWidgets('permission denial keeps touch navigation available', (
    tester,
  ) async {
    final engine = FakeVoiceEngine()..denied = true;
    VoiceDestination? selected;
    await openSheet(tester, engine, (value) => selected = value);
    await tester.tap(find.text('Mulai bicara'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Izin mikrofon ditolak'), findsOneWidget);
    await tester.ensureVisible(find.text('Panduan'));
    await tester.tap(find.text('Panduan'));
    await tester.pumpAndSettle();
    expect(selected, VoiceDestination.guide);
  });

  testWidgets(
    'ambiguous command offers choices and closing rejects late speech',
    (tester) async {
      final engine = FakeVoiceEngine();
      VoiceDestination? selected;
      await openSheet(tester, engine, (value) => selected = value);
      await tester.tap(find.text('Mulai bicara'));
      await tester.pumpAndSettle();
      engine.result!('evakuasi', true);
      await tester.pumpAndSettle();
      expect(selected, isNull);
      expect(
        find.text('Pilih fitur evakuasi yang Anda maksud.'),
        findsOneWidget,
      );
      expect(find.text('Panduan'), findsOneWidget);
      expect(find.text('Peta'), findsOneWidget);
      await tester.tap(find.byTooltip('Tutup suara'));
      await tester.pumpAndSettle();
      engine.result!('peta', true);
      await tester.pump();
      expect(selected, isNull);
      expect(tester.takeException(), isNull);
    },
  );
}
