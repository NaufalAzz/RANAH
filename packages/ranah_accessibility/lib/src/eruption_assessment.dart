import 'package:flutter/material.dart';

import 'siaga_guide.dart';
import 'volcano_reference.dart';

class EruptionKrbFeature {
  const EruptionKrbFeature({
    required this.volcanoName,
    required this.zone,
    this.mapYear,
  });
  final String volcanoName;
  final String zone;
  final int? mapYear;
}

enum EruptionAssessmentKind { monitor, normalInKrb, noIntersection, unknown }

class EruptionAssessment {
  const EruptionAssessment({
    required this.kind,
    required this.title,
    required this.reason,
    this.guide,
    this.zone,
    this.mapYear,
  });

  final EruptionAssessmentKind kind;
  final String title;
  final String reason;
  final SiagaGuide? guide;
  final String? zone;
  final int? mapYear;
  bool get showRecommendation => kind == EruptionAssessmentKind.monitor;
}

int? eruptionActivityLevel(String? status) {
  final match = RegExp(
    r'Level\s+(IV|III|II|I)\b',
    caseSensitive: false,
  ).firstMatch(status ?? '');
  return switch (match?.group(1)?.toUpperCase()) {
    'IV' => 4,
    'III' => 3,
    'II' => 2,
    'I' => 1,
    _ => null,
  };
}

Color eruptionActivityColor(String? status) =>
    switch (eruptionActivityLevel(status)) {
      1 => const Color(0xFF16805B),
      2 => const Color(0xFFE9AB16),
      3 => const Color(0xFFE77D25),
      4 => const Color(0xFFD83C47),
      _ => const Color(0xFF778A9C),
    };

class EruptionLevelLegend extends StatelessWidget {
  const EruptionLevelLegend({super.key});

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 12,
    runSpacing: 6,
    children: [
      for (final entry in const [
        ('Level I', 'Level I'),
        ('Level II', 'Level II'),
        ('Level III', 'Level III'),
        ('Level IV', 'Level IV'),
        ('Status belum ada', ''),
      ])
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.terrain,
              color: eruptionActivityColor(entry.$2),
              size: 18,
            ),
            const SizedBox(width: 4),
            Text(
              entry.$1,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
    ],
  );
}

EruptionAssessment assessEruptionLocation({
  required String spatialStatus,
  required List<EruptionKrbFeature> features,
  required List<SiagaGuide> reports,
  required double? accuracyMeters,
}) {
  if (accuracyMeters == null || accuracyMeters > 1000) {
    return const EruptionAssessment(
      kind: EruptionAssessmentKind.unknown,
      title: 'Posisi perlu diperiksa lagi',
      reason:
          'Akurasi lokasi terlalu rendah untuk menyimpulkan apakah titik Anda beririsan dengan KRB. Perbarui lokasi atau periksa peta resmi.',
    );
  }
  if (spatialStatus == 'no_data') {
    return const EruptionAssessment(
      kind: EruptionAssessmentKind.noIntersection,
      title: 'Tidak ditemukan irisan KRB pada titik ini',
      reason:
          'Titik lokasi tidak beririsan dengan poligon KRB pada layer BIG yang diperiksa. Cakupan dan tahun peta bisa berbeda; ini bukan jaminan bebas dampak erupsi.',
    );
  }
  if (spatialStatus != 'hasil_tersedia' || features.isEmpty) {
    return const EruptionAssessment(
      kind: EruptionAssessmentKind.unknown,
      title: 'Paparan erupsi belum dapat ditentukan',
      reason:
          'Data KRB untuk titik ini belum dapat divalidasi. Jangan menyimpulkan lokasi aman; periksa peta dan arahan terbaru PVMBG/BPBD.',
    );
  }
  final byName = {
    for (final report in reports) normalizeVolcanoName(report.name): report,
  };
  final matches = <(EruptionKrbFeature, SiagaGuide, int)>[];
  for (final feature in features) {
    final report = byName[normalizeVolcanoName(feature.volcanoName)];
    final level = eruptionActivityLevel(report?.status);
    if (report == null || level == null) {
      return const EruptionAssessment(
        kind: EruptionAssessmentKind.unknown,
        title: 'KRB terdeteksi, status belum cocok',
        reason:
            'Titik beririsan dengan KRB BIG, tetapi laporan aktivitas untuk seluruh gunung yang terkait belum dapat dicocokkan. Periksa peta dan laporan resmi.',
      );
    }
    if (report.retrievedAt != null &&
        DateTime.now().difference(report.retrievedAt!).inDays > 7) {
      return const EruptionAssessment(
        kind: EruptionAssessmentKind.unknown,
        title: 'KRB terdeteksi, laporan aktivitas sudah lama',
        reason:
            'Titik beririsan dengan KRB, tetapi laporan aktivitas terakhir yang tersedia lebih dari tujuh hari. Periksa status terbaru di PVMBG/BPBD sebelum mengambil keputusan.',
      );
    }
    matches.add((feature, report, level));
  }
  matches.sort((a, b) => b.$3.compareTo(a.$3));
  final selected = matches.first;
  final feature = selected.$1;
  final guide = selected.$2;
  final mapYear = feature.mapYear == null
      ? 'tahun tidak tersedia'
      : 'tahun ${feature.mapYear}';
  if (selected.$3 == 1) {
    return EruptionAssessment(
      kind: EruptionAssessmentKind.normalInKrb,
      title: 'Aktivitas normal, lokasi berada di KRB',
      reason:
          'Titik beririsan dengan ${feature.zone} Gunung ${guide.name} pada peta BIG $mapYear. Laporan MAGMA mencatat Level I (Normal); KRB tetap menunjukkan potensi bahaya dan larangan setempat tetap berlaku.',
      guide: guide,
      zone: feature.zone,
      mapYear: feature.mapYear,
    );
  }
  return EruptionAssessment(
    kind: EruptionAssessmentKind.monitor,
    title: 'Perhatikan rekomendasi Gunung ${guide.name}',
    reason:
        'Titik beririsan dengan ${feature.zone} pada peta BIG $mapYear dan laporan MAGMA mencatat ${guide.status}. Ikuti rekomendasi resmi dan arahan petugas; peta bukan penetapan jalur aman.',
    guide: guide,
    zone: feature.zone,
    mapYear: feature.mapYear,
  );
}
