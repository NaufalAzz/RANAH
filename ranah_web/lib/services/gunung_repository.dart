import '../models/gunung_data.dart';
import 'ranah_api_client.dart';

abstract interface class GunungDataRepository {
  Future<List<GunungRecord>> loadGunung();
  Future<GunungDetailRecord> loadDetail(int id);
}

class GunungRepository implements GunungDataRepository {
  GunungRepository({RanahApiClient? client}) : _client = client ?? RanahApiClient();

  final RanahApiClient _client;

  @override
  Future<List<GunungRecord>> loadGunung() async {
    final response = await _client.getJson('gunung');
    if (response['success'] != true || response['data'] is! List) {
      throw const RanahApiException('Format daftar gunung dari API tidak sesuai.');
    }

    final records = <GunungRecord>[];
    final ids = <int>{};
    for (final raw in response['data'] as List) {
      if (raw is! Map) {
        throw const FormatException('Item gunung dari API bukan objek JSON.');
      }
      final record = GunungRecord.fromJson(Map<String, dynamic>.from(raw));
      if (!ids.add(record.id)) {
        throw const FormatException('ID gunung duplikat pada respons API.');
      }
      records.add(record);
    }
    return List.unmodifiable(records);
  }

  @override
  Future<GunungDetailRecord> loadDetail(int id) async {
    final response = await _client.getJson('gunung/$id');
    if (response['success'] != true || response['data'] is! Map) {
      throw const RanahApiException('Format detail gunung dari API tidak sesuai.');
    }
    final detail = GunungDetailRecord.fromJson(
      Map<String, dynamic>.from(response['data'] as Map),
    );
    if (detail.gunung.id != id) {
      throw const FormatException('ID gunung pada detail API tidak cocok.');
    }
    return detail;
  }

  void close() => _client.close();
}
