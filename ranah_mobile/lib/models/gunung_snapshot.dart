class GunungListSnapshot {
  const GunungListSnapshot({
    required this.items,
    required this.lastCheckedAt,
    required this.isFromCache,
    this.apiReturnedEmpty = false,
  });

  final List<Map<String, dynamic>> items;
  final DateTime? lastCheckedAt;
  final bool isFromCache;
  final bool apiReturnedEmpty;
}

class GunungDetailSnapshot {
  const GunungDetailSnapshot({
    required this.data,
    required this.lastCheckedAt,
    required this.isFromCache,
  });

  final Map<String, dynamic> data;
  final DateTime? lastCheckedAt;
  final bool isFromCache;
}
