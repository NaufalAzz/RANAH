import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ranah_mobile/app/main_shell.dart';
import 'package:ranah_mobile/models/mobile_map_data.dart';
import 'package:ranah_mobile/services/news_repository.dart';
import 'package:ranah_mobile/theme/app_theme.dart';

import 'test_helpers.dart';

class EmptyNews extends NewsRepository {
  @override
  Future<NewsFeedSnapshot> load() async => const NewsFeedSnapshot(
    items: [],
    isUsingFallback: false,
    isFromCache: false,
  );
}

void main() {
  test('old multihazard API data cannot reintroduce unrelated cards', () {
    final result = MapHazardResult.fromEnvelope({
      'success': true,
      'data': {
        'bahaya': {
          'tsunami': {'status': 'hasil_tersedia'},
          'banjir': {'status': 'hasil_tersedia'},
          'gempa_bumi': {'status': 'hasil_tersedia'},
          'letusan_gunung_api': {
            'status': 'hasil_tersedia',
            'penjelasan': 'KRB uji',
          },
        },
      },
    });
    expect(result.items, hasLength(1));
    expect(result.items.single.name, 'Kawasan rawan gunung api');
  });
  testWidgets(
    'home opens immediate eruption actions without fetching volcanoes',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MainShell(
            newsRepository: EmptyNews(),
            mapTilesEnabled: false,
            internetStatusMonitor: createTestInternetStatusMonitor(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tindakan Sekarang'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Terkena hujan abu'));
      await tester.pumpAndSettle();
      expect(find.text('Langkah 1 dari 4'), findsOneWidget);
      expect(find.text('Potensi Bencana di Lokasi'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
