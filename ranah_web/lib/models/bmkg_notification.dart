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
      throw const FormatException(
        'Item notifikasi tidak memiliki ID atau judul.',
      );
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
    this.sourceStatuses = const <String, BmkgSyncState>{},
  });

  final List<BmkgNotification> items;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final DateTime? sourceUpdatedAt;
  final int? earthquakeWindowDays;
  final Map<String, BmkgSyncState> sourceStatuses;

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
      sourceStatuses: _syncStates(meta['status_sumber']),
    );
  }
}

class BmkgSyncState {
  const BmkgSyncState({
    required this.status,
    this.lastAttemptAt,
    this.lastSuccessAt,
    this.errorCode,
    this.records,
  });

  final String status;
  final DateTime? lastAttemptAt;
  final DateTime? lastSuccessAt;
  final String? errorCode;
  final int? records;

  factory BmkgSyncState.fromJson(Map<String, dynamic> json) => BmkgSyncState(
    status: _string(json['status']) ?? 'belum_diperiksa',
    lastAttemptAt: _date(json['last_attempt_at']),
    lastSuccessAt: _date(json['last_success_at']),
    errorCode: _string(json['error_code']),
    records: _nullableInteger(json['records']),
  );
}

class BmkgWeatherArea {
  const BmkgWeatherArea({
    required this.adm4,
    required this.village,
    required this.district,
    required this.city,
    required this.province,
  });

  final String adm4;
  final String village;
  final String district;
  final String city;
  final String province;

  String get label => '$village · $district, $city';

  factory BmkgWeatherArea.fromJson(Map<String, dynamic> json) {
    final adm4 = _string(json['adm4']);
    final village = _string(json['desa']);
    final district = _string(json['kecamatan']);
    final city = _string(json['kotkab']);
    final province = _string(json['provinsi']);
    if (adm4 == null ||
        village == null ||
        district == null ||
        city == null ||
        province == null) {
      throw const FormatException(
        'Wilayah prakiraan tidak memiliki identitas ADM4 lengkap.',
      );
    }
    return BmkgWeatherArea(
      adm4: adm4,
      village: village,
      district: district,
      city: city,
      province: province,
    );
  }
}

class BmkgWeatherInterval {
  const BmkgWeatherInterval({
    required this.localTime,
    required this.utcTime,
    required this.condition,
    this.temperature,
    this.humidity,
    this.windSpeed,
  });

  final DateTime localTime;
  final DateTime utcTime;
  final String condition;
  final double? temperature;
  final int? humidity;
  final double? windSpeed;

  factory BmkgWeatherInterval.fromJson(Map<String, dynamic> json) {
    final localTime = _date(json['waktu_lokal']);
    final utcTime = _date(json['waktu_utc']);
    final condition = _string(json['kondisi']);
    if (localTime == null || utcTime == null || condition == null) {
      throw const FormatException(
        'Interval prakiraan tidak memiliki waktu atau kondisi yang valid.',
      );
    }
    return BmkgWeatherInterval(
      localTime: localTime,
      utcTime: utcTime,
      condition: condition,
      temperature: _nullableDouble(json['suhu_c']),
      humidity: _nullableInteger(json['kelembapan_persen']),
      windSpeed: _nullableDouble(json['kecepatan_angin_kmh']),
    );
  }
}

class BmkgWeatherForecast {
  const BmkgWeatherForecast({
    required this.area,
    required this.intervals,
    required this.status,
    required this.isStale,
    this.analysisAt,
    this.retrievedAt,
  });

  final BmkgWeatherArea area;
  final List<BmkgWeatherInterval> intervals;
  final String status;
  final bool isStale;
  final DateTime? analysisAt;
  final DateTime? retrievedAt;

  factory BmkgWeatherForecast.fromJson(Map<String, dynamic> json) {
    if (json['success'] != true) {
      throw const FormatException('Prakiraan BMKG tidak tersedia.');
    }
    final meta = json['meta'] is Map
        ? Map<String, dynamic>.from(json['meta'] as Map)
        : const <String, dynamic>{};
    final raw = json['data'];
    if (raw == null) {
      return BmkgWeatherForecast(
        area: const BmkgWeatherArea(
          adm4: '',
          village: '',
          district: '',
          city: '',
          province: '',
        ),
        intervals: const [],
        status: _string(meta['status']) ?? 'belum_tersedia',
        isStale: false,
      );
    }
    if (raw is! Map) {
      throw const FormatException('Objek prakiraan BMKG tidak sesuai.');
    }
    final data = Map<String, dynamic>.from(raw);
    final area = BmkgWeatherArea.fromJson(
      Map<String, dynamic>.from(data['wilayah'] as Map),
    );
    final rawIntervals = data['prakiraan'];
    if (rawIntervals is! List) {
      throw const FormatException('Daftar interval prakiraan tidak sesuai.');
    }
    final intervals = rawIntervals
        .whereType<Map>()
        .map(
          (item) =>
              BmkgWeatherInterval.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false);
    return BmkgWeatherForecast(
      area: area,
      intervals: List.unmodifiable(intervals),
      status: _string(meta['status']) ?? 'tersedia',
      isStale: meta['data_stale'] == true,
      analysisAt: _date(data['waktu_data_dibuat']),
      retrievedAt: _date(data['waktu_diambil']),
    );
  }
}

Map<String, BmkgSyncState> _syncStates(dynamic value) {
  if (value is! Map) return const {};
  return value.entries.where((entry) => entry.value is Map).fold(
    <String, BmkgSyncState>{},
    (result, entry) {
      result[entry.key.toString()] = BmkgSyncState.fromJson(
        Map<String, dynamic>.from(entry.value as Map),
      );
      return result;
    },
  );
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

int? _nullableInteger(dynamic value) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');

double? _nullableDouble(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '');

String? _httpsUrl(dynamic value) {
  final source = _string(value);
  if (source == null) return null;
  final uri = Uri.tryParse(source);
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty) {
    return null;
  }
  return uri.toString();
}
