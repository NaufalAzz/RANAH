class BmkgNotification {
  const BmkgNotification({
    required this.id,
    required this.title,
    required this.category,
    required this.summary,
    required this.kind,
    required this.status,
    this.region,
    this.source,
    this.sourceId,
    this.sourceUrl,
    this.importance,
    this.eventAt,
    this.publishedAt,
    this.retrievedAt,
    this.expiresAt,
  });

  final String id;
  final String title;
  final String category;
  final String summary;
  final String kind;
  final String status;
  final String? region;
  final String? source;
  final String? sourceId;
  final String? sourceUrl;
  final String? importance;
  final DateTime? eventAt;
  final DateTime? publishedAt;
  final DateTime? retrievedAt;
  final DateTime? expiresAt;

  bool get isWarning => kind == 'peringatan';

  factory BmkgNotification.fromJson(Map<String, dynamic> json) {
    final id = _string(json['id']);
    final title = _string(json['judul']);
    if (id == null || title == null) {
      throw const FormatException('Item notifikasi tidak memiliki ID atau judul.');
    }

    return BmkgNotification(
      id: id,
      title: title,
      category: _string(json['kategori']) ?? 'Informasi',
      summary: _string(json['ringkasan']) ?? '',
      kind: _string(json['jenis_konten']) ?? 'kejadian',
      status: _string(json['status']) ?? 'informasi',
      region: _string(json['wilayah']),
      source: _string(json['sumber']),
      sourceId: _string(json['sumber_id']),
      sourceUrl: _httpsUrl(json['url_sumber']),
      importance: _string(json['tingkat_kepentingan']),
      eventAt: _date(json['waktu_kejadian']),
      publishedAt: _date(json['waktu_publikasi']),
      retrievedAt: _date(json['waktu_pengambilan']),
      expiresAt: _date(json['waktu_berakhir']),
    );
  }
}

class BmkgNotificationFeed {
  const BmkgNotificationFeed({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    this.sourceUpdatedAt,
    this.earthquakeWindowDays,
  });

  final List<BmkgNotification> items;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final DateTime? sourceUpdatedAt;
  final int? earthquakeWindowDays;

  factory BmkgNotificationFeed.fromJson(Map<String, dynamic> json) {
    if (json['success'] != true || json['data'] is! List) {
      throw const FormatException('Struktur feed notifikasi tidak sesuai.');
    }
    final rawItems = json['data'] as List;
    final items = <BmkgNotification>[];
    for (final rawItem in rawItems) {
      if (rawItem is! Map) {
        throw const FormatException('Item feed notifikasi bukan objek JSON.');
      }
      items.add(BmkgNotification.fromJson(Map<String, dynamic>.from(rawItem)));
    }

    final meta = json['meta'] is Map
        ? Map<String, dynamic>.from(json['meta'] as Map)
        : const <String, dynamic>{};
    return BmkgNotificationFeed(
      items: List.unmodifiable(items),
      currentPage: _integer(meta['current_page'], fallback: 1),
      lastPage: _integer(meta['last_page'], fallback: 1),
      perPage: _integer(meta['per_page'], fallback: items.length),
      total: _integer(meta['total'], fallback: items.length),
      sourceUpdatedAt: _date(
        meta['waktu_pembaruan_terakhir_bmkg'] ??
            meta['waktu_pembaruan_terakhir'],
      ),
      earthquakeWindowDays: _nullableInteger(meta['rentang_gempa_hari']),
    );
  }
}

String? _string(dynamic value) {
  if (value == null) return null;
  final result = value.toString().trim();
  return result.isEmpty ? null : result;
}

DateTime? _date(dynamic value) =>
    value is String ? DateTime.tryParse(value) : null;

int _integer(dynamic value, {required int fallback}) =>
    _nullableInteger(value) ?? fallback;

int? _nullableInteger(dynamic value) => value is num
    ? value.toInt()
    : int.tryParse(value?.toString() ?? '');

String? _httpsUrl(dynamic value) {
  final source = _string(value);
  if (source == null) return null;
  final uri = Uri.tryParse(source);
  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty || uri.userInfo.isNotEmpty) {
    return null;
  }
  return uri.toString();
}
