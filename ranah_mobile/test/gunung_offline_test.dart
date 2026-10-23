import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ranah_mobile/models/gunung_snapshot.dart';
import 'package:ranah_mobile/pages/gunung_report_page.dart';
import 'package:ranah_mobile/pages/volcanic_activity_page.dart';
import 'package:ranah_mobile/services/gunung_api.dart';
import 'package:ranah_mobile/services/gunung_local_store.dart';
import 'package:ranah_mobile/services/gunung_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late GunungLocalStore store;

  setUpAll(sqfliteFfiInit);
  setUp(() {
    store = GunungLocalStore(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
  });
  tearDown(() => store.close());

  test(
    'successful list sync is saved locally and can be read offline',
    () async {
      final api = FakeGunungApi(list: [sampleGunung()]);
      final repository = GunungRepository(api: api, localStore: store);

      final online = await repository.syncGunung();
      api.listError = true;
      final cached = await repository.readGunungCache();

      expect(online.items.single['nama'], 'Gunung Cache');
      expect(cached.items.single['id'], 11);
      expect(cached.items.single['status_aktivitas'], isNull);
    },
  );

  test('repeated sync updates rows without duplicating server IDs', () async {
    final api = FakeGunungApi(list: [sampleGunung()]);
    final repository = GunungRepository(api: api, localStore: store);
    await repository.syncGunung();
    api.list = [sampleGunung(nama: 'Nama terbaru')];
    await repository.syncGunung();

    final cached = await repository.readGunungCache();
    expect(cached.items, hasLength(1));
    expect(cached.items.single['nama'], 'Nama terbaru');
  });

  test('failed network refresh preserves previously stored cache', () async {
    final repository = GunungRepository(
      api: FakeGunungApi(list: [sampleGunung()]),
      localStore: store,
    );
    await repository.syncGunung();

    final offlineRepository = GunungRepository(
      api: FakeGunungApi()..listError = true,
      localStore: store,
    );
    await expectLater(offlineRepository.syncGunung(), throwsException);
    expect((await offlineRepository.readGunungCache()).items, hasLength(1));
  });

  test('empty list response keeps an existing cache', () async {
    final repository = GunungRepository(
      api: FakeGunungApi(list: [sampleGunung()]),
      localStore: store,
    );
    await repository.syncGunung();
    final emptyApi = FakeGunungApi(list: []);
    final result = await GunungRepository(
      api: emptyApi,
      localStore: store,
    ).syncGunung();

    expect(result.apiReturnedEmpty, isTrue);
    expect(result.items, hasLength(1));
  });

  test('detail and related reports can be read from cache offline', () async {
    final repository = GunungRepository(
      api: FakeGunungApi(detail: sampleDetail()),
      localStore: store,
    );
    await repository.syncDetail(11);
    final offline = GunungRepository(
      api: FakeGunungApi()..detailError = true,
      localStore: store,
    );

    await expectLater(offline.syncDetail(11), throwsException);
    final cached = await offline.readDetailCache(11);
    expect(cached?.data['gunung']['id'], 11);
    expect(cached?.data['laporan'], hasLength(1));
  });

  test('detail without reports and nullable values remain valid', () async {
    final detail = sampleDetail(reports: [], status: null);
    detail['gunung']['latitude'] = null;
    detail['gunung']['sumber_data'] = null;
    final repository = GunungRepository(
      api: FakeGunungApi(detail: detail),
      localStore: store,
    );

    final synced = await repository.syncDetail(11);
    final cached = await repository.readDetailCache(11);
    expect(synced.data['laporan'], isEmpty);
    expect(cached?.data['laporan'], isEmpty);
    expect(cached?.data['gunung']['latitude'], isNull);
    expect(cached?.data['gunung']['status_aktivitas'], isNull);
  });

  testWidgets(
    'activity page displays cached data and keeps unknown status unverified',
    (tester) async {
      final repository = OfflineGunungRepository(
        listCache: GunungListSnapshot(
          items: [sampleGunung()],
          lastCheckedAt: DateTime(2025, 4, 6, 12, 34),
          isFromCache: true,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: VolcanicActivityPage(onBack: () {}, repository: repository),
        ),
      );
      await _pumpOfflinePage(tester);
      expect(find.textContaining('mungkin sudah usang'), findsOneWidget);
      expect(find.textContaining('06/04/2025 12:34'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Gunung Cache'),
        300,
        scrollable: find.byType(Scrollable).last,
      );

      expect(find.text('Gunung Cache'), findsOneWidget);
      expect(find.text('Belum diverifikasi'), findsWidgets);
    },
  );

  testWidgets('detail page displays cached reports when API is offline', (
    tester,
  ) async {
    final repository = OfflineGunungRepository(
      listCache: const GunungListSnapshot(
        items: [],
        lastCheckedAt: null,
        isFromCache: true,
      ),
      detailCache: GunungDetailSnapshot(
        data: sampleDetail(),
        lastCheckedAt: DateTime(2025, 4, 6, 12, 34),
        isFromCache: true,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(home: GunungReportPage(gunungId: 11, repository: repository)),
    );
    await _pumpOfflinePage(tester);

    expect(find.textContaining('mungkin sudah usang'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Arahan aman'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Gunung Cache'), findsOneWidget);
    expect(find.text('Arahan aman'), findsOneWidget);
  });

  testWidgets('empty local database and failed API offers retry', (
    tester,
  ) async {
    final repository = OfflineGunungRepository(
      listCache: const GunungListSnapshot(
        items: [],
        lastCheckedAt: null,
        isFromCache: true,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: VolcanicActivityPage(onBack: () {}, repository: repository),
      ),
    );
    await _pumpOfflinePage(tester);

    expect(
      find.text('Data gunung belum tersedia di perangkat saat offline.'),
      findsOneWidget,
    );
    expect(find.text('Coba lagi'), findsOneWidget);
  });

  testWidgets('cached detail without reports and nullable fields is clear', (
    tester,
  ) async {
    final detail = sampleDetail(reports: [], status: null);
    detail['gunung']['latitude'] = null;
    detail['gunung']['longitude'] = null;
    final repository = OfflineGunungRepository(
      listCache: const GunungListSnapshot(
        items: [],
        lastCheckedAt: null,
        isFromCache: true,
      ),
      detailCache: GunungDetailSnapshot(
        data: detail,
        lastCheckedAt: DateTime(2025, 4, 6, 12, 34),
        isFromCache: true,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(home: GunungReportPage(gunungId: 11, repository: repository)),
    );
    await _pumpOfflinePage(tester);

    expect(find.text('Belum ada laporan pengamatan'), findsOneWidget);
    expect(find.text('Belum diverifikasi'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Koordinat belum tersedia'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Koordinat belum tersedia'), findsOneWidget);
  });
}

class FakeGunungApi implements GunungApi {
  FakeGunungApi({List<dynamic>? list, Map<String, dynamic>? detail})
    : list = list ?? [],
      detail = detail ?? sampleDetail();

  List<dynamic> list;
  Map<String, dynamic> detail;
  bool listError = false;
  bool detailError = false;

  @override
  Future<List<dynamic>> getGunung() async {
    if (listError) throw Exception('network unavailable');
    return list;
  }

  @override
  Future<Map<String, dynamic>> getDetailGunung(int id) async {
    if (detailError) throw Exception('network unavailable');
    return detail;
  }
}

class OfflineGunungRepository implements GunungDataRepository {
  OfflineGunungRepository({required this.listCache, this.detailCache});

  final GunungListSnapshot listCache;
  final GunungDetailSnapshot? detailCache;

  @override
  Future<GunungListSnapshot> readGunungCache() async => listCache;

  @override
  Future<GunungListSnapshot> syncGunung() async =>
      throw Exception('network unavailable');

  @override
  Future<GunungDetailSnapshot?> readDetailCache(int id) async => detailCache;

  @override
  Future<GunungDetailSnapshot> syncDetail(int id) async =>
      throw Exception('network unavailable');
}

Map<String, dynamic> sampleGunung({String nama = 'Gunung Cache'}) => {
  'id': 11,
  'nama': nama,
  'provinsi': 'Provinsi Contoh',
  'kabupaten': null,
  'latitude': null,
  'longitude': null,
  'status_aktivitas': null,
  'radius_perkiraan_km': null,
  'sumber_data': null,
  'aktif': true,
};

Map<String, dynamic> sampleDetail({
  List<Map<String, dynamic>>? reports,
  String? status = 'Belum diverifikasi',
}) => {
  'gunung': {...sampleGunung(), 'status_aktivitas': status},
  'laporan':
      reports ??
      [
        {
          'id': 101,
          'gunung_id': 11,
          'periode_mulai': null,
          'periode_selesai': null,
          'data_klimatologi': null,
          'pengamatan_visual': null,
          'rekomendasi': 'Arahan aman',
          'foto': null,
          'sumber': 'Sumber contoh',
          'waktu_publikasi': '2026-10-22T09:00:00Z',
        },
      ],
};

Future<void> _pumpOfflinePage(WidgetTester tester) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
