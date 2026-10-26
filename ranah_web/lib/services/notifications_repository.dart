import '../models/bmkg_notification.dart';
import 'ranah_api_client.dart';

abstract interface class BmkgNotificationRepository {
  Future<BmkgNotificationFeed> load({required int page});
}

class NotificationsRepository implements BmkgNotificationRepository {
  NotificationsRepository({RanahApiClient? client})
    : _client = client ?? RanahApiClient();

  final RanahApiClient _client;

  @override
  Future<BmkgNotificationFeed> load({required int page}) async {
    final response = await _client.getJson(
      'notifikasi',
      queryParameters: {'page': '$page', 'per_page': '30'},
    );
    return BmkgNotificationFeed.fromJson(response);
  }
}
