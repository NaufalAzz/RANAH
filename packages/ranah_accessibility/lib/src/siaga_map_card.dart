import 'package:flutter/material.dart';

import 'siaga_guide.dart';

class SiagaMapCard extends StatelessWidget {
  const SiagaMapCard({
    required this.volcanoName,
    required this.onOpenGuide,
    this.guide,
    this.loading = false,
    this.error,
    super.key,
  });

  final String volcanoName;
  final SiagaGuide? guide;
  final bool loading;
  final String? error;
  final VoidCallback onOpenGuide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final points = guide?.recommendationParagraphs ?? const <String>[];
    return Card(
      color: const Color(0xFFF7F9FD),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFF21005E),
                  foregroundColor: Colors.white,
                  child: Icon(Icons.landscape_rounded),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Siaga Erupsi · $volcanoName',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1B2A45),
                        ),
                      ),
                      Text(
                        guide?.status ?? 'Status sedang dimuat',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (loading) const LinearProgressIndicator(),
            if (error != null)
              Text(error!, style: const TextStyle(color: Color(0xFF9B3A12))),
            if (guide != null) ...[
              Text(
                'Sumber: ${guide!.source} · ${guide!.displayPeriod}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              for (final point in points.take(2))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '• $point',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              if (points.isEmpty)
                const Text('Rekomendasi belum tersedia pada laporan ini.'),
            ],
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: onOpenGuide,
              icon: const Icon(Icons.health_and_safety_outlined),
              label: const Text('Buka Panduan Siaga Lengkap'),
            ),
          ],
        ),
      ),
    );
  }
}
