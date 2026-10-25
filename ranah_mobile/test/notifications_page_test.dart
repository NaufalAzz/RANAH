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
        home: NotificationsPage(
          repository: NotificationsRepository(
            api: _FakeApi(
              [_quake],
              sourceUpdatedAt: DateTime.parse('2026-10-24T04:00:00Z'),
            ),
            store: _MemoryStore(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Informasi gempa BMKG relevan dengan Sumatera Barat'), findsOneWidget);
    expect(find.textContaining('Wilayah: Kota Padang'), findsOneWidget);
    expect(find.textContaining('Kejadian/mulai:'), findsOneWidget);
    expect(find.textContaining('Publikasi:'), findsNothing);
    expect(find.textContaining('Sinkronisasi sumber BMKG terakhir'), findsOneWidget);
    expect(find.textContaining('Diambil RANAH:'), findsOneWidget);
    expect(find.textContaining('BMKG'), findsOneWidget);
    expect(find.text('Buka sumber asli'), findsOneWidget);
    expect(find.text('SIMULASI DATA'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('valid empty API response shows an empty state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationsPage(
          repository: NotificationsRepository(
            api: _FakeApi([]),
            store: _MemoryStore(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Belum ada notifikasi dari sumber yang terhubung.'), findsOneWidget);
    expect(find.text('Notifikasi belum dapat dimuat dari server.'), findsNothing);
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
        home: NotificationsPage(
          repository: NotificationsRepository(
            api: _FakeApi([outside, legacy, oldSource]),
            store: _MemoryStore(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Gempa dari wilayah lain'), findsNothing);
    expect(find.text('Berita lama dari BNPB'), findsNothing);
    expect(find.text('Informasi gempa BMKG relevan dengan Sumatera Barat'), findsNothing);
    expect(find.text('Belum ada notifikasi dari sumber yang terhubung.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('network failure displays cached data with a stale marker', (
    tester,
  ) async {
    final cache = _MemoryStore();
    await NotificationsRepository(
      api: _FakeApi(
        [_quake],
        sourceUpdatedAt: DateTime.parse('2026-10-24T04:00:00Z'),
      ),
      store: cache,
    ).load();
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationsPage(
          repository: NotificationsRepository(api: _FailingApi(), store: cache),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Informasi gempa BMKG relevan dengan Sumatera Barat'), findsOneWidget);
    expect(find.textContaining('Menampilkan cache lokal'), findsOneWidget);
    expect(find.textContaining('Sinkronisasi sumber BMKG terakhir'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('network failure without cache shows retry and no sample data', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationsPage(
          repository: NotificationsRepository(
            api: _FailingApi(),
            store: _MemoryStore(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Notifikasi belum dapat dimuat dari server.'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
    expect(find.textContaining('CONTOH'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('legacy and expired cache entries are not current notifications', (
    tester,
  ) async {
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
        home: NotificationsPage(
          repository: NotificationsRepository(api: _FailingApi(), store: cache),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Informasi gempa BMKG relevan dengan Sumatera Barat'), findsNothing);
    expect(find.text('Gempa lama di cache'), findsNothing);
    expect(find.text('Notifikasi belum dapat dimuat dari server.'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

const _quake = <String, dynamic>{
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
  'waktu_kejadian': '2026-10-24T03:30:00.000000Z',
  'waktu_publikasi': null,
  'waktu_pengambilan': '2026-10-24T03:31:00.000000Z',
  'waktu_berakhir': null,
  'status': 'informasi',
};

class _FakeApi implements NotificationApi {
  _FakeApi(this.items, {this.sourceUpdatedAt});
  final List<dynamic> items;
  final DateTime? sourceUpdatedAt;

  @override
  Future<NotificationApiFeed> getNotifications() async => NotificationApiFeed(
    items: items,
    sourceUpdatedAt: sourceUpdatedAt,
  );
}

class _FailingApi implements NotificationApi {
  @override
  Future<NotificationApiFeed> getNotifications() async => throw Exception('offline');
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
