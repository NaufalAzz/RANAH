abstract interface class NotificationCacheStore {
  Future<List<Map<String, dynamic>>> readNotifications();

  Future<void> saveNotifications(
    List<Map<String, dynamic>> items, {
    required DateTime checkedAt,
    DateTime? sourceUpdatedAt,
  });

  Future<DateTime?> readLastSync(String key);
}
