import 'package:flutter/material.dart';

import 'siaga_guide.dart';
import 'eruption_assessment.dart';

class SiagaMapCard extends StatelessWidget {
  const SiagaMapCard({
    required this.volcanoName,
    required this.onOpenGuide,
    this.guide,
    this.assessment,
    this.loading = false,
    this.error,
    super.key,
  });

  final String volcanoName;
  final SiagaGuide? guide;
  final EruptionAssessment? assessment;
  final bool loading;
  final String? error;
  final VoidCallback? onOpenGuide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedGuide = assessment == null ? guide : assessment!.guide;
    final showRecommendation = assessment?.showRecommendation ?? true;
    final points = showRecommendation
        ? selectedGuide?.recommendationParagraphs ?? const <String>[]
        : const <String>[];
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF174476),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF456A91)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFF105675),
                  foregroundColor: Colors.white,
                  child: Icon(Icons.landscape_rounded),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assessment?.title ?? 'Siaga Erupsi · $volcanoName',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        selectedGuide?.status ??
                            (assessment == null
                                ? 'Status sedang dimuat'
                                : 'Hasil pemeriksaan lokasi'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFFD9E8F5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (loading)
              const LinearProgressIndicator(color: Color(0xFF62D2E0)),
            if (error != null)
              Text(error!, style: const TextStyle(color: Color(0xFFFFD166))),
            if (assessment != null) ...[
              Text(
                assessment!.reason,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (selectedGuide != null && showRecommendation) ...[
              Text(
                'Sumber: ${selectedGuide.source} · ${selectedGuide.displayPeriod}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFFD9E8F5),
                ),
              ),
              const SizedBox(height: 8),
              for (final point in points.take(2))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    RegExp(r'^\d+[.)]\s').hasMatch(point) ? point : '• $point',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              if (points.isEmpty)
                const Text(
                  'Rekomendasi belum tersedia pada laporan ini.',
                  style: TextStyle(color: Color(0xFFD9E8F5)),
                ),
            ],
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: loading ? null : onOpenGuide,
              icon: const Icon(Icons.health_and_safety_outlined),
              label: Text(
                showRecommendation
                    ? 'Buka Panduan Siaga Lengkap'
                    : 'Lihat Alasan dan Data',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
