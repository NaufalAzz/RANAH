abstract interface class NotificationApi {
  Future<NotificationApiFeed> getNotifications();
}

class NotificationApiFeed {
  const NotificationApiFeed({required this.items, this.sourceUpdatedAt});

  final List<dynamic> items;
  final DateTime? sourceUpdatedAt;
}
