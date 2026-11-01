import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ranah_mobile/pages/notifications_page.dart';
import 'package:ranah_mobile/services/notification_api.dart';
import 'package:ranah_mobile/services/notification_cache_store.dart';
import 'package:ranah_mobile/services/notifications_repository.dart';

void main() {
  testWidgets('shows API notification provenance and separates timestamps', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NotificationsPage(
            repository: NotificationsRepository(
              api: _FakeApi([
                _quake,
              ], sourceUpdatedAt: DateTime.parse('2026-10-24T04:00:00Z')),
              store: _MemoryStore(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Informasi gempa BMKG relevan dengan Sumatera Barat'),
      findsOneWidget,
    );
    await tester.ensureVisible(
      find.textContaining('Wilayah: Dirasakan: Kota Padang'),
    );
    expect(
      find.textContaining('Wilayah: Dirasakan: Kota Padang'),
      findsOneWidget,
    );
    expect(find.textContaining('Kejadian/mulai:'), findsOneWidget);
    expect(find.textContaining('Publikasi:'), findsNothing);
    expect(
      find.textContaining('Sinkronisasi sumber BMKG terakhir'),
      findsOneWidget,
    );
    expect(find.textContaining('Diambil RANAH:'), findsOneWidget);
    expect(find.text('Sumber: BMKG'), findsOneWidget);
    expect(find.text('Buka sumber asli'), findsOneWidget);
    expect(find.text('SIMULASI DATA'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('valid empty API response shows an empty state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NotificationsPage(
            repository: NotificationsRepository(
              api: _FakeApi([]),
              store: _MemoryStore(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Belum ada notifikasi dari sumber yang terhubung.'),
      findsOneWidget,
    );
    expect(
      find.text('Notifikasi belum dapat dimuat dari server.'),
      findsNothing,
    );
  });

  testWidgets('weather forecast requires an explicit configured area choice', (
    tester,
  ) async {
    final api = _FakeApi([]);
    final weatherApi = _FakeWeatherApi();
    final repository = NotificationsRepository(
      api: api,
      weatherApi: weatherApi,
      store: _MemoryStore(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: NotificationsPage(repository: repository)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cuaca'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining(
        'Pilih kelurahan dari daftar ADM4 Sumatera Barat yang dikonfigurasi.',
      ),
      findsOneWidget,
    );
    expect(
      find.text('Prakiraan Cuaca — Desa Uji, Kecamatan Uji, Kota Padang'),
      findsNothing,
    );
    expect(weatherApi.forecastRequests, 0);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Desa Uji · Kecamatan Uji, Kota Padang').last);
    await tester.pumpAndSettle();
    expect(weatherApi.forecastRequests, 1);
    expect(find.text('Cuaca cerah'), findsOneWidget);
    expect(find.textContaining('Prakiraan Cuaca — Desa Uji'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('drops notifications without the verified Sumbar API scope', (
    tester,
  ) async {
    final outside = Map<String, dynamic>.from(_quake)
      ..['id'] = 99
      ..['judul'] = 'Gempa dari wilayah lain'
      ..['wilayah'] = 'Kota Sorong'
      ..['cakupan_wilayah'] = 'Papua Barat Daya';
    final legacy = Map<String, dynamic>.from(_quake)
      ..['id'] = 100
      ..remove('cakupan_wilayah');
    final oldSource = Map<String, dynamic>.from(_quake)
      ..['id'] = 102
      ..['judul'] = 'Berita lama dari BNPB'
      ..['sumber'] = 'BNPB';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NotificationsPage(
            repository: NotificationsRepository(
              api: _FakeApi([outside, legacy, oldSource]),
              store: _MemoryStore(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Gempa dari wilayah lain'), findsNothing);
    expect(find.text('Berita lama dari BNPB'), findsNothing);
    expect(
      find.text('Informasi gempa BMKG relevan dengan Sumatera Barat'),
      findsNothing,
    );
    expect(
      find.text('Belum ada notifikasi dari sumber yang terhubung.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('network failure displays cached data with a stale marker', (
    tester,
  ) async {
    final cache = _MemoryStore();
    await NotificationsRepository(
      api: _FakeApi([
        _quake,
      ], sourceUpdatedAt: DateTime.parse('2026-10-24T04:00:00Z')),
      store: cache,
    ).load();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NotificationsPage(
            repository: NotificationsRepository(
              api: _FailingApi(),
              store: cache,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Informasi gempa BMKG relevan dengan Sumatera Barat'),
      findsOneWidget,
    );
    expect(find.textContaining('Menampilkan cache lokal'), findsOneWidget);
    expect(
      find.textContaining('Sinkronisasi sumber BMKG terakhir'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('network failure without cache shows retry and no sample data', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NotificationsPage(
            repository: NotificationsRepository(
              api: _FailingApi(),
              store: _MemoryStore(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Notifikasi belum dapat dimuat dari server.'),
      findsOneWidget,
    );
    expect(find.text('Coba lagi'), findsOneWidget);
    expect(find.textContaining('CONTOH'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'legacy and expired cache entries are not current notifications',
    (tester) async {
      final oldScopedCache = Map<String, dynamic>.from(_quake)
        ..['id'] = 101
        ..['judul'] = 'Gempa lama di cache'
        ..['waktu_kejadian'] = DateTime.now()
            .subtract(const Duration(days: 10))
            .toIso8601String();
      final cache = _MemoryStore()
        ..items = [
          Map<String, dynamic>.from(_quake)..remove('cakupan_wilayah'),
          oldScopedCache,
        ]
        ..lastSync = DateTime.parse('2026-10-24T04:00:00Z');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationsPage(
              repository: NotificationsRepository(
                api: _FailingApi(),
                store: cache,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Informasi gempa BMKG relevan dengan Sumatera Barat'),
        findsNothing,
      );
      expect(find.text('Gempa lama di cache'), findsNothing);
      expect(
        find.text('Notifikasi belum dapat dimuat dari server.'),
        findsOneWidget,
      );
      expect(find.text('Coba lagi'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

final _quake = <String, dynamic>{
  'id': 22,
  'judul': 'Informasi gempa BMKG relevan dengan Sumatera Barat',
  'kategori': 'Gempa',
  'jenis_konten': 'kejadian',
  'ringkasan': 'Informasi dari data fixture BMKG.',
  'wilayah': 'Dirasakan: Kota Padang',
  'cakupan_wilayah': 'Sumatera Barat',
  'rentang_gempa_hari': 7,
  'sumber': 'BMKG',
  'sumber_id': 'bmkg-quake:fixture',
  'url_sumber': 'https://data.bmkg.go.id/DataMKG/TEWS/gempadirasakan.json',
  'tingkat_kepentingan': null,
  'waktu_kejadian': DateTime.now()
      .toUtc()
      .subtract(const Duration(hours: 1))
      .toIso8601String(),
  'waktu_publikasi': null,
  'waktu_pengambilan': DateTime.now().toUtc().toIso8601String(),
  'waktu_berakhir': null,
  'status': 'informasi',
};

class _FakeApi implements NotificationApi {
  _FakeApi(this.items, {this.sourceUpdatedAt});
  final List<dynamic> items;
  final DateTime? sourceUpdatedAt;

  @override
  Future<NotificationApiFeed> getNotifications() async =>
      NotificationApiFeed(items: items, sourceUpdatedAt: sourceUpdatedAt);
}

class _FakeWeatherApi implements WeatherForecastApi {
  int forecastRequests = 0;
  @override
  Future<List<dynamic>> getWeatherAreas() async => [
    {
      'adm4': '13.71.01.1001',
      'desa': 'Desa Uji',
      'kecamatan': 'Kecamatan Uji',
      'kotkab': 'Kota Padang',
      'provinsi': 'Sumatera Barat',
    },
    {
      'adm4': '99.99.99.9999',
      'desa': 'Desa Lain',
      'kecamatan': 'Kecamatan Lain',
      'kotkab': 'Kota Lain',
      'provinsi': 'Provinsi Lain',
    },
  ];

  @override
  Future<Map<String, dynamic>> getWeatherForecast(String adm4) async {
    forecastRequests++;
    return {
      'success': true,
      'meta': {'status': 'tersedia', 'data_stale': false},
      'data': {
        'wilayah': {
          'adm4': adm4,
          'desa': 'Desa Uji',
          'kecamatan': 'Kecamatan Uji',
          'kotkab': 'Kota Padang',
          'provinsi': 'Sumatera Barat',
        },
        'prakiraan': [
          {
            'waktu_lokal': '2026-11-01T14:00:00+07:00',
            'waktu_utc': '2026-11-01T07:00:00Z',
            'kondisi': 'Cuaca cerah',
            'suhu_c': 29,
            'kelembapan_persen': 75,
            'kecepatan_angin_kmh': 8,
          },
        ],
        'waktu_data_dibuat': '2026-11-01T06:00:00Z',
        'waktu_diambil': '2026-11-01T06:05:00Z',
      },
    };
  }
}

class _FailingApi implements NotificationApi {
  @override
  Future<NotificationApiFeed> getNotifications() async =>
      throw Exception('offline');
}

class _MemoryStore implements NotificationCacheStore {
  List<Map<String, dynamic>> items = [];
  DateTime? lastSync;
  DateTime? sourceUpdatedAt;

  @override
  Future<List<Map<String, dynamic>>> readNotifications() async => items;

  @override
  Future<void> saveNotifications(
    List<Map<String, dynamic>> value, {
    required DateTime checkedAt,
    DateTime? sourceUpdatedAt,
  }) async {
    items = value;
    lastSync = checkedAt;
    this.sourceUpdatedAt = sourceUpdatedAt;
  }

  @override
  Future<DateTime?> readLastSync(String key) async =>
      key == 'notifications_source_last_sync' ? sourceUpdatedAt : lastSync;
}
