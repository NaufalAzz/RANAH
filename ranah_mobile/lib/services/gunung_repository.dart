import '../models/gunung_snapshot.dart';
import 'api_service.dart';
import 'gunung_api.dart';
import 'gunung_local_store.dart';

abstract interface class GunungDataRepository {
  Future<GunungListSnapshot> readGunungCache();
  Future<GunungListSnapshot> syncGunung();
  Future<GunungDetailSnapshot?> readDetailCache(int id);
  Future<GunungDetailSnapshot> syncDetail(int id);
}

class GunungRepository implements GunungDataRepository {
  GunungRepository({GunungApi? api, GunungLocalStore? localStore})
    : _api = api ?? ApiService(),
      _localStore = localStore ?? GunungLocalStore.instance;

  final GunungApi _api;
  final GunungLocalStore _localStore;

  @override
  Future<GunungListSnapshot> readGunungCache() async => GunungListSnapshot(
    items: await _localStore.readGunung(),
    lastCheckedAt: await _localStore.readLastSync('gunung_list_last_sync'),
    isFromCache: true,
  );

  @override
  Future<GunungListSnapshot> syncGunung() async {
    final rawItems = await _api.getGunung();
    final items = <Map<String, dynamic>>[];
    for (final rawItem in rawItems) {
      if (rawItem is! Map) {
        throw const FormatException('Format daftar gunung tidak sesuai.');
      }
      final item = Map<String, dynamic>.from(rawItem);
      if (!_hasId(item['id'])) {
        throw const FormatException('Data gunung tidak memiliki ID server.');
      }
      items.add(item);
    }
    final checkedAt = DateTime.now();
    await _localStore.saveGunung(items, checkedAt: checkedAt);
    return GunungListSnapshot(
      items: await _localStore.readGunung(),
      lastCheckedAt: checkedAt,
      isFromCache: false,
      apiReturnedEmpty: items.isEmpty,
    );
  }

  @override
  Future<GunungDetailSnapshot?> readDetailCache(int id) async {
    final data = await _localStore.readDetail(id);
    if (data == null) return null;
    return GunungDetailSnapshot(
      data: data,
      lastCheckedAt: await _localStore.readLastSync('gunung_detail_$id'),
      isFromCache: true,
    );
  }

  @override
  Future<GunungDetailSnapshot> syncDetail(int id) async {
    final detail = await _api.getDetailGunung(id);
    final gunung = detail['gunung'];
    final reports = detail['laporan'];
    if (gunung is! Map || reports is! List) {
      throw const FormatException('Format detail gunung tidak sesuai.');
    }
    final normalizedGunung = Map<String, dynamic>.from(gunung);
    if (!_hasId(normalizedGunung['id'])) {
      throw const FormatException('Detail gunung tidak memiliki ID server.');
    }
    final normalized = {'gunung': normalizedGunung, 'laporan': reports};
    final checkedAt = DateTime.now();
    await _localStore.saveDetail(normalized, checkedAt: checkedAt);
    final saved = await _localStore.readDetail(id);
    if (saved == null) {
      throw StateError('Detail gunung tidak ditemukan setelah disimpan.');
    }
    return GunungDetailSnapshot(
      data: saved,
      lastCheckedAt: checkedAt,
      isFromCache: false,
    );
  }

  bool _hasId(dynamic value) =>
      value is int || int.tryParse(value?.toString() ?? '') != null;
}
