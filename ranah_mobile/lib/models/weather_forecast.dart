class WeatherArea {
  const WeatherArea({
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

  factory WeatherArea.fromJson(Map<String, dynamic> json) {
    String? text(String key) {
      final value = json[key]?.toString().trim();
      return value == null || value.isEmpty ? null : value;
    }

    final adm4 = text('adm4');
    final village = text('desa');
    final district = text('kecamatan');
    final city = text('kotkab');
    final province = text('provinsi');
    if ([
      adm4,
      village,
      district,
      city,
      province,
    ].any((value) => value == null)) {
      throw const FormatException('Identitas wilayah ADM4 tidak lengkap.');
    }
    return WeatherArea(
      adm4: adm4!,
      village: village!,
      district: district!,
      city: city!,
      province: province!,
    );
  }
}

class WeatherInterval {
  const WeatherInterval({
    required this.localTime,
    required this.condition,
    this.temperature,
    this.humidity,
    this.windSpeed,
  });

  final DateTime localTime;
  final String condition;
  final double? temperature;
  final int? humidity;
  final double? windSpeed;

  factory WeatherInterval.fromJson(Map<String, dynamic> json) {
    final time = DateTime.tryParse(json['waktu_lokal']?.toString() ?? '');
    final condition = json['kondisi']?.toString().trim();
    if (time == null || condition == null || condition.isEmpty) {
      throw const FormatException('Waktu atau kondisi prakiraan tidak valid.');
    }
    double? number(String key) {
      final value = json[key];
      return value is num
          ? value.toDouble()
          : double.tryParse(value?.toString() ?? '');
    }

    int? integer(String key) {
      final value = json[key];
      return value is num
          ? value.toInt()
          : int.tryParse(value?.toString() ?? '');
    }

    return WeatherInterval(
      localTime: time,
      condition: condition,
      temperature: number('suhu_c'),
      humidity: integer('kelembapan_persen'),
      windSpeed: number('kecepatan_angin_kmh'),
    );
  }
}

class WeatherForecast {
  const WeatherForecast({
    required this.area,
    required this.intervals,
    required this.status,
    required this.isStale,
    this.analysisAt,
    this.retrievedAt,
  });

  final WeatherArea? area;
  final List<WeatherInterval> intervals;
  final String status;
  final bool isStale;
  final DateTime? analysisAt;
  final DateTime? retrievedAt;

  factory WeatherForecast.fromEnvelope(Map<String, dynamic> json) {
    if (json['success'] != true) {
      throw const FormatException('Respons prakiraan cuaca tidak valid.');
    }
    final meta = json['meta'] is Map
        ? Map<String, dynamic>.from(json['meta'] as Map)
        : <String, dynamic>{};
    final data = json['data'];
    if (data == null) {
      return WeatherForecast(
        area: null,
        intervals: const [],
        status: meta['status']?.toString() ?? 'belum_tersedia',
        isStale: false,
      );
    }
    if (data is! Map || data['wilayah'] is! Map || data['prakiraan'] is! List) {
      throw const FormatException('Struktur prakiraan cuaca tidak sesuai.');
    }
    final intervals = (data['prakiraan'] as List)
        .whereType<Map>()
        .map(
          (item) => WeatherInterval.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false);
    DateTime? date(dynamic value) => DateTime.tryParse(value?.toString() ?? '');
    return WeatherForecast(
      area: WeatherArea.fromJson(
        Map<String, dynamic>.from(data['wilayah'] as Map),
      ),
      intervals: List.unmodifiable(intervals),
      status: meta['status']?.toString() ?? 'tersedia',
      isStale: meta['data_stale'] == true,
      analysisAt: date(data['waktu_data_dibuat']),
      retrievedAt: date(data['waktu_diambil']),
    );
  }
}
