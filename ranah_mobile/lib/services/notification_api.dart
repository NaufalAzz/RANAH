abstract interface class NotificationApi {
  Future<NotificationApiFeed> getNotifications();
}

abstract interface class WeatherForecastApi {
  Future<List<dynamic>> getWeatherAreas();
  Future<Map<String, dynamic>> getWeatherForecast(String adm4);
}

class NotificationApiFeed {
  const NotificationApiFeed({required this.items, this.sourceUpdatedAt});

  final List<dynamic> items;
  final DateTime? sourceUpdatedAt;
}
