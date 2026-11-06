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
      throw UnsupportedError(
        'Izin mikrofon ditolak. Kembali ke aplikasi atau coba lagi.',
      );
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
    'specific feature names are unique but shared keywords yield several results',
    () {
      expect(resolveVoiceCommand('Tolong buka panduan!'), [
        VoiceDestination.guide,
      ]);
      expect(resolveVoiceCommand('menu'), [VoiceDestination.menu]);
      expect(resolveVoiceCommand('Buka menu kontak darurat'), [
        VoiceDestination.contacts,
      ]);
      expect(resolveVoiceCommand('status gunung'), [VoiceDestination.activity]);
      expect(resolveVoiceCommand('peta gunung'), [VoiceDestination.map]);
      expect(resolveVoiceCommand('berita gunung'), [VoiceDestination.news]);
      expect(
        resolveVoiceCommand('gunung'),
        unorderedEquals([
          VoiceDestination.activity,
          VoiceDestination.map,
          VoiceDestination.guide,
          VoiceDestination.news,
        ]),
      );
      expect(resolveVoiceCommand('gunung api'), hasLength(4));
      expect(
        resolveVoiceCommand('EVAKUASI'),
        unorderedEquals([VoiceDestination.guide, VoiceDestination.map]),
      );
      expect(resolveVoiceCommand('jangan buka peta'), isEmpty);
      expect(resolveVoiceCommand('peta panduan'), isEmpty);
      expect(resolveVoiceCommand('petani'), isEmpty);
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

  void noResults() {
    for (final destination in VoiceDestination.values) {
      expect(
        find.byKey(ValueKey('voice-result-${destination.name}')),
        findsNothing,
      );
    }
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'initial panel has no quick menu and never requests mic on its own',
    (tester) async {
      final engine = FakeVoiceEngine();
      await openSheet(tester, engine, (_) {});
      expect(engine.starts, 0);
      noResults();
      expect(find.text('Panduan'), findsNothing);
      expect(find.text('Mulai bicara'), findsOneWidget);
    },
  );
  testWidgets('only a unique final utterance opens the feature', (
    tester,
  ) async {
    final engine = FakeVoiceEngine();
    VoiceDestination? selected;
    await openSheet(tester, engine, (value) => selected = value);
    await tap(tester, find.byKey(const ValueKey('voice-start')));
    engine.result!('panduan', false);
    await tester.pumpAndSettle();
    expect(selected, isNull);
    noResults();
    engine.result!('panduan', true);
    await tester.pumpAndSettle();
    expect(selected, VoiceDestination.guide);
  });
  testWidgets(
    'gunung offers relevant choices after final speech, never auto opens',
    (tester) async {
      final engine = FakeVoiceEngine();
      VoiceDestination? selected;
      await openSheet(tester, engine, (value) => selected = value);
      await tap(tester, find.byKey(const ValueKey('voice-start')));
      engine.result!('gunung', false);
      await tester.pumpAndSettle();
      noResults();
      engine.result!('gunung', true);
      await tester.pumpAndSettle();
      expect(selected, isNull);
      for (final feature in [
        VoiceDestination.activity,
        VoiceDestination.guide,
        VoiceDestination.map,
        VoiceDestination.news,
      ]) {
        expect(
          find.byKey(ValueKey('voice-result-${feature.name}')),
          findsOneWidget,
        );
      }
      expect(find.byKey(const ValueKey('voice-result-contacts')), findsNothing);
      // Late results from the finished recording must not auto-select a feature.
      engine.result!('peta', true);
      await tester.pumpAndSettle();
      expect(selected, isNull);
      await tap(tester, find.byKey(const ValueKey('voice-result-map')));
      expect(selected, VoiceDestination.map);
    },
  );
  testWidgets(
    'permission denial and unknown speech do not reveal a fallback menu',
    (tester) async {
      final engine = FakeVoiceEngine()..denied = true;
      await openSheet(tester, engine, (_) {});
      await tap(tester, find.byKey(const ValueKey('voice-start')));
      expect(find.textContaining('Izin mikrofon ditolak'), findsOneWidget);
      noResults();
      engine.denied = false;
      await tap(tester, find.byKey(const ValueKey('voice-start')));
      engine.result!('mobil', true);
      await tester.pumpAndSettle();
      expect(find.textContaining('Perintah belum dikenali'), findsOneWidget);
      noResults();
    },
  );
  testWidgets('retry clears old choices and close ignores late speech', (
    tester,
  ) async {
    final engine = FakeVoiceEngine();
    VoiceDestination? selected;
    await openSheet(tester, engine, (value) => selected = value);
    await tap(tester, find.byKey(const ValueKey('voice-start')));
    engine.result!('gunung', true);
    await tester.pumpAndSettle();
    await tap(tester, find.byKey(const ValueKey('voice-start')));
    noResults();
    await tap(tester, find.byTooltip('Tutup suara'));
    engine.result!('peta', true);
    await tester.pump();
    expect(selected, isNull);
    expect(tester.takeException(), isNull);
  });
  testWidgets('voice results fit a narrow screen with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final engine = FakeVoiceEngine();
    await openSheet(tester, engine, (_) {});
    await tap(tester, find.byKey(const ValueKey('voice-start')));
    engine.result!('gunung', true);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('voice-result-news')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
