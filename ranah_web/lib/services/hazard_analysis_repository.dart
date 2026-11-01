import 'ranah_api_client.dart';

class KrbFeatureMatch {
  const KrbFeatureMatch({
    required this.volcanoName,
    required this.zone,
    required this.sourceFeatureId,
    this.mapYear,
  });

  final String volcanoName;
  final String zone;
  final int sourceFeatureId;
  final int? mapYear;

  factory KrbFeatureMatch.fromJson(Map<String, dynamic> json) {
    final name = json['nama_gunung']?.toString().trim() ?? '';
    final zone = json['zona_krb']?.toString().trim() ?? '';
    final featureId = _intValue(json['id_fitur_sumber']);
    if (name.isEmpty || zone.isEmpty || featureId == null) {
      throw const FormatException('Fitur KRB dari API tidak lengkap.');
    }
    return KrbFeatureMatch(
      volcanoName: name,
      zone: zone,
      sourceFeatureId: featureId,
      mapYear: _intValue(json['tahun_peta']),
    );
  }
}

class VolcanoHazardResult {
  const VolcanoHazardResult({
    required this.status,
    required this.explanation,
    required this.method,
    required this.source,
    required this.sourceUrl,
    required this.limitations,
    required this.features,
  });

  final String status;
  final String explanation;
  final String method;
  final String source;
  final String sourceUrl;
  final String limitations;
  final List<KrbFeatureMatch> features;

  factory VolcanoHazardResult.fromJson(Map<String, dynamic> json) {
    final rawFeatures = json['fitur'];
    if (rawFeatures is! List) {
      throw const FormatException('Daftar fitur KRB dari API tidak valid.');
    }
    return VolcanoHazardResult(
      status: _text(json['status'], 'analisis_tidak_dapat_ditentukan'),
      explanation: _text(json['penjelasan'], 'Hasil belum dapat ditentukan.'),
      method: _text(json['metode'], ''),
      source: _text(json['sumber'], ''),
      sourceUrl: _text(json['url_sumber'], ''),
      limitations: _text(json['keterbatasan'], ''),
      features: List.unmodifiable(
        rawFeatures.map((feature) {
          if (feature is! Map) {
            throw const FormatException('Fitur KRB bukan objek JSON.');
          }
          return KrbFeatureMatch.fromJson(Map<String, dynamic>.from(feature));
        }),
      ),
    );
  }
}

class HazardAnalysisResult {
  const HazardAnalysisResult({
    required this.analyzedAt,
    required this.volcano,
    this.tsunami = const RasterHazardResult.notAnalyzed(),
    this.flood = const RasterHazardResult.notAnalyzed(),
    this.earthquake = const RasterHazardResult.notAnalyzed(),
  });

  final DateTime? analyzedAt;
  final VolcanoHazardResult volcano;
  final RasterHazardResult tsunami;
  final RasterHazardResult flood;
  final RasterHazardResult earthquake;

  factory HazardAnalysisResult.fromJson(Map<String, dynamic> json) {
    final rawHazards = json['bahaya'];
    final rawVolcano = rawHazards is Map
        ? rawHazards['letusan_gunung_api']
        : null;
    if (rawVolcano is! Map) {
      throw const FormatException('Hasil analisis gunung api tidak tersedia.');
    }
    final hazards = Map<String, dynamic>.from(rawHazards as Map);
    return HazardAnalysisResult(
      analyzedAt: DateTime.tryParse(json['waktu_analisis']?.toString() ?? ''),
      volcano: VolcanoHazardResult.fromJson(
        Map<String, dynamic>.from(rawVolcano),
      ),
      tsunami: RasterHazardResult.fromJson(hazards['tsunami']),
      flood: RasterHazardResult.fromJson(hazards['banjir']),
      earthquake: RasterHazardResult.fromJson(hazards['gempa_bumi']),
    );
  }
}

class RasterHazardResult {
  const RasterHazardResult({
    required this.status,
    required this.explanation,
    this.dataset,
    this.valueType,
    this.dataType,
    this.methodologyUrl,
    this.queryMethod,
    this.source,
    this.sourceUrl,
    this.year,
    this.pixelSizeMeters,
    this.spatialReference,
    this.pixelValue,
    this.classification,
    this.limitations,
  });

  const RasterHazardResult.notAnalyzed()
    : status = 'belum_dianalisis',
      explanation = 'Belum dianalisis pada tahap ini.',
      dataset = null,
      valueType = null,
      dataType = null,
      methodologyUrl = null,
      queryMethod = null,
      source = null,
      sourceUrl = null,
      year = null,
      pixelSizeMeters = null,
      spatialReference = null,
      pixelValue = null,
      classification = null,
      limitations = null;

  final String status;
  final String explanation;
  final String? dataset;
  final String? valueType;
  final String? dataType;
  final String? methodologyUrl;
  final String? queryMethod;
  final String? source;
  final String? sourceUrl;
  final int? year;
  final double? pixelSizeMeters;
  final String? spatialReference;
  final double? pixelValue;
  final String? classification;
  final String? limitations;

  factory RasterHazardResult.fromJson(dynamic raw) {
    if (raw is! Map) return const RasterHazardResult.notAnalyzed();
    final json = Map<String, dynamic>.from(raw);
    return RasterHazardResult(
      status: _text(json['status'], 'belum_dapat_ditentukan'),
      explanation: _text(
        json['penjelasan'],
        'Informasi bahaya untuk lokasi ini belum dapat ditentukan berdasarkan data yang tersedia.',
      ),
      dataset: _nullableText(json['dataset']),
      valueType: _nullableText(json['jenis_nilai']),
      dataType: _nullableText(json['tipe_nilai']),
      methodologyUrl: _nullableText(json['url_metodologi']),
      queryMethod: _nullableText(json['metode_query']),
      source: _nullableText(json['sumber']),
      sourceUrl: _nullableText(json['url_sumber']),
      year: _intValue(json['tahun_data']),
      pixelSizeMeters: _doubleValue(json['resolusi_piksel_meter']),
      spatialReference: _nullableText(json['sistem_koordinat_dataset']),
      pixelValue: _doubleValue(json['nilai_piksel']),
      classification: _nullableText(json['klasifikasi']),
      limitations: _nullableText(json['keterbatasan']),
    );
  }
}

class HazardAnalysisRepository {
  HazardAnalysisRepository({RanahApiClient? client})
    : _client = client ?? RanahApiClient();

  final RanahApiClient _client;

  Future<HazardAnalysisResult> analyze({
    required double latitude,
    required double longitude,
  }) async {
    final response = await _client.postJson(
      'peta/analisis-bahaya',
      body: {'latitude': latitude, 'longitude': longitude},
      timeoutOverride: const Duration(seconds: 35),
    );
    if (response['success'] != true || response['data'] is! Map) {
      throw const RanahApiException(
        'Format hasil analisis dari API tidak sesuai.',
      );
    }
    return HazardAnalysisResult.fromJson(
      Map<String, dynamic>.from(response['data'] as Map),
    );
  }

  void close() => _client.close();
}

String _text(dynamic value, String fallback) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String? _nullableText(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

int? _intValue(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}

double? _doubleValue(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
