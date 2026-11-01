import '../models/bmkg_notification.dart';
import 'ranah_api_client.dart';

abstract interface class BmkgNotificationRepository {
  Future<BmkgNotificationFeed> load({required int page, String? kind});
}

abstract interface class BmkgForecastRepository {
  Future<List<BmkgWeatherArea>> loadWeatherAreas();
  Future<BmkgWeatherForecast> loadWeatherForecast(String adm4);
}

class NotificationsRepository
    implements BmkgNotificationRepository, BmkgForecastRepository {
  NotificationsRepository({RanahApiClient? client})
    : _client = client ?? RanahApiClient();

  final RanahApiClient _client;

  @override
  Future<BmkgNotificationFeed> load({required int page, String? kind}) async {
    final response = await _client.getJson(
      'notifikasi',
      queryParameters: {
        'page': '$page',
        'per_page': '30',
        ...?_kindQuery(kind),
      },
    );
    return BmkgNotificationFeed.fromJson(response);
  }

  @override
  Future<List<BmkgWeatherArea>> loadWeatherAreas() async {
    final response = await _client.getJson('prakiraan-cuaca/wilayah');
    if (response['success'] != true || response['data'] is! List) {
      throw const FormatException(
        'Daftar wilayah prakiraan BMKG tidak sesuai.',
      );
    }
    return List.unmodifiable(
      (response['data'] as List).whereType<Map>().map(
        (item) => BmkgWeatherArea.fromJson(Map<String, dynamic>.from(item)),
      ),
    );
  }

  @override
  Future<BmkgWeatherForecast> loadWeatherForecast(String adm4) async {
    final response = await _client.getJson('prakiraan-cuaca/$adm4');
    return BmkgWeatherForecast.fromJson(response);
  }
}

Map<String, String>? _kindQuery(String? kind) =>
    kind == null ? null : {'jenis_konten': kind};
