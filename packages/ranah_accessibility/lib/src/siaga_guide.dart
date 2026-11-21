import 'dart:convert';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import 'volcano_reference.dart';

class SiagaLocation {
  const SiagaLocation(this.latitude, this.longitude, this.accuracy);
  final double latitude, longitude;
  final double? accuracy;
  String get accuracyLabel => accuracy == null
      ? 'Akurasi belum tersedia'
      : 'Akurasi ±${accuracy!.round()} m';
  bool get isValid =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180 &&
      (accuracy == null || accuracy!.isFinite && accuracy! >= 0);

  double distanceKm(VolcanoReference reference) {
    double radians(double value) => value * math.pi / 180;
    final lat = radians(reference.latitude - latitude);
    final lon = radians(reference.longitude - longitude);
    final a =
        math.pow(math.sin(lat / 2), 2) +
        math.cos(radians(latitude)) *
            math.cos(radians(reference.latitude)) *
            math.pow(math.sin(lon / 2), 2);
    return 6371 * 2 * math.asin(math.sqrt(a.clamp(0, 1)));
  }

  VolcanoReference get nearest =>
      (volcanoReferences.values.toList()
            ..sort((a, b) => distanceKm(a).compareTo(distanceKm(b))))
          .first;
}

class SiagaGuide {
  const SiagaGuide({
    required this.id,
    required this.name,
    required this.status,
    required this.recommendation,
    required this.period,
    required this.retrievedAt,
    this.source = 'Sumber belum tersedia',
    this.fromCache = false,
  });
  final int id;
  final String name, status, period, source;
  final String? recommendation;
  final DateTime? retrievedAt;
  final bool fromCache;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'status': status,
    'recommendation': recommendation,
    'period': period,
    'source': source,
    'retrievedAt': retrievedAt?.toIso8601String(),
  };

  factory SiagaGuide.fromJson(Map<String, dynamic> data) {
    final id = data['id'];
    final name = data['name'];
    if (id is! int ||
        id <= 0 ||
        name is! String ||
        volcanoReference(name) == null ||
        data['status'] is! String ||
        data['period'] is! String ||
        data['recommendation'] != null && data['recommendation'] is! String) {
      throw const FormatException('Panduan tersimpan tidak valid.');
    }
    return SiagaGuide(
      id: id,
      name: volcanoReference(name)!.name,
      status: data['status'],
      recommendation: data['recommendation'],
      period: data['period'],
      source: data['source'] is String
          ? data['source']
          : 'Sumber belum tersedia',
      retrievedAt: DateTime.tryParse(data['retrievedAt']?.toString() ?? ''),
      fromCache: true,
    );
  }
}

class SiagaGuideStore {
  static const _key = 'ranah_siaga_guide_v1';
  Future<void> save(SiagaGuide guide) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(_key, jsonEncode(guide.toJson()))) {
      throw StateError('Panduan belum berhasil disimpan.');
    }
  }

  Future<SiagaGuide?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return SiagaGuide.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }
}
