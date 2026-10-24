import 'package:flutter/material.dart';

import '../data/volcanic_activity_data.dart';
import '../theme/ranah_theme.dart';

class VolcanicActivityPage extends StatefulWidget {
  const VolcanicActivityPage({
    required this.onBack,
    required this.onViewReport,
    super.key,
  });

  final VoidCallback onBack;
  final ValueChanged<VolcanoActivitySample> onViewReport;

  @override
  State<VolcanicActivityPage> createState() => _VolcanicActivityPageState();
}

class _VolcanicActivityPageState extends State<VolcanicActivityPage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final compact = width < 700;
      final contentWidth = width > 1120 ? 1120.0 : width;
      final query = _query.trim().toLowerCase();
      final visible = volcanicActivitySamples.where((sample) {
        return sample.name.toLowerCase().contains(query) ||
            sample.province.toLowerCase().contains(query);
      }).toList();

      return Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: contentWidth,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              compact ? 8 : 28,
              0,
              compact ? 8 : 28,
              28,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _ActivityTitleBanner(),
                _ActivityBackBar(onBack: widget.onBack),
                const SizedBox(height: 12),
                const _SampleDataNotice(),
                const SizedBox(height: 10),
                _LevelSummaryRow(
                  compact: compact,
                  counts: {
                    for (final level in activityLevelSamples)
                      level.level: visible
                          .where((item) => item.level == level.level)
                          .length,
                  },
                ),
                const SizedBox(height: 12),
                _SearchField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                ),
                const SizedBox(height: 12),
                if (visible.isEmpty)
                  const _EmptySearchResult()
                else
                  _ActivityGroups(
                    samples: visible,
                    compact: compact,
                    onViewReport: widget.onViewReport,
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _ActivityTitleBanner extends StatelessWidget {
  const _ActivityTitleBanner();

  @override
  Widget build(BuildContext context) => Container(
    height: 52,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    color: const Color(0xFF17003E),
    child: const Row(
      children: [
        Icon(Icons.landscape_outlined, size: 27),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DISASTER EVACUATION',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 8,
                  letterSpacing: .9,
                  color: Color(0xFF91A8D0),
                ),
              ),
              Text(
                'Volcanic Activity',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              Text(
                'Memantau aktivitas gunung api',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 9, color: Color(0xFFC1C8D7)),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ActivityBackBar extends StatelessWidget {
  const _ActivityBackBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 30,
    child: Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onBack,
        icon: const Icon(Icons.arrow_back, size: 14),
        label: const Text('Kembali', style: TextStyle(fontSize: 10)),
        style: TextButton.styleFrom(
          foregroundColor: RanahColors.ink,
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          minimumSize: const Size(0, 26),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
    ),
  );
}

class _SampleDataNotice extends StatelessWidget {
  const _SampleDataNotice();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFF493619),
      border: Border.all(color: const Color(0xFFFFB51B).withValues(alpha: .7)),
      borderRadius: BorderRadius.circular(5),
    ),
    child: const Row(
      children: [
        Icon(Icons.info_outline, color: Color(0xFFFFC44C), size: 14),
        SizedBox(width: 7),
        Expanded(
          child: Text(
            'DATA CONTOH - bukan status gunung terkini atau informasi resmi.',
            style: TextStyle(fontSize: 10, color: Colors.white),
          ),
        ),
      ],
    ),
  );
}

class _LevelSummaryRow extends StatelessWidget {
  const _LevelSummaryRow({required this.counts, required this.compact});

  final Map<int, int> counts;
  final bool compact;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth < 350 ? 2 : 4;
      final gap = 7.0;
      final cardWidth = (constraints.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: 7,
        children: [
          for (final level in activityLevelSamples)
            SizedBox(
              width: cardWidth,
              child: _LevelSummaryCard(
                level: level,
                count: counts[level.level] ?? 0,
                compact: compact,
              ),
            ),
        ],
      );
    },
  );
}

class _LevelSummaryCard extends StatelessWidget {
  const _LevelSummaryCard({
    required this.level,
    required this.count,
    required this.compact,
  });

  final ActivityLevelSample level;
  final int count;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    height: compact ? 56 : 70,
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFF133C67),
      borderRadius: BorderRadius.circular(5),
      border: Border.all(color: Color(level.color).withValues(alpha: .65)),
    ),
    child: Row(
      children: [
        Icon(Icons.change_history_rounded, color: Color(level.color), size: 18),
        const SizedBox(width: 5),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontSize: compact ? 17 : 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Level ${level.level} (${level.name})',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 8 : 11,
                  color: Color(level.color),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 42,
    child: TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(color: RanahColors.ink, fontSize: 13),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: 'Cari nama gunung atau provinsi',
        hintStyle: const TextStyle(color: Color(0xFF818A98), fontSize: 12),
        prefixIcon: const Icon(
          Icons.search,
          size: 20,
          color: Color(0xFF697589),
        ),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
                icon: const Icon(Icons.close, size: 18),
                tooltip: 'Hapus pencarian',
              ),
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
      ),
    ),
  );
}

class _ActivityGroups extends StatelessWidget {
  const _ActivityGroups({
    required this.samples,
    required this.compact,
    required this.onViewReport,
  });

  final List<VolcanoActivitySample> samples;
  final bool compact;
  final ValueChanged<VolcanoActivitySample> onViewReport;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFF174777),
      borderRadius: BorderRadius.circular(7),
      border: Border.all(color: const Color(0xFF3275A7)),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFF557EA0))),
          ),
          child: const Text(
            'Daftar Tingkat Aktivitas Gunung Api',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
        for (final level in activityLevelSamples)
          _ActivityLevelGroup(
            level: level,
            samples: samples
                .where((sample) => sample.level == level.level)
                .toList(),
            compact: compact,
            onViewReport: onViewReport,
          ),
      ],
    ),
  );
}

class _ActivityLevelGroup extends StatelessWidget {
  const _ActivityLevelGroup({
    required this.level,
    required this.samples,
    required this.compact,
    required this.onViewReport,
  });

  final ActivityLevelSample level;
  final List<VolcanoActivitySample> samples;
  final bool compact;
  final ValueChanged<VolcanoActivitySample> onViewReport;

  @override
  Widget build(BuildContext context) {
    if (samples.isEmpty && level.level != 4) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 9, 13, 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF52799C))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Level ${level.level} - ${level.name}',
            style: TextStyle(
              color: Color(level.color),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            level.description,
            style: const TextStyle(fontSize: 11, color: Color(0xFFE0E6EF)),
          ),
          const SizedBox(height: 3),
          Text(
            '${samples.length} gunung contoh',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
          if (samples.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 12, bottom: 5),
              child: Text('Belum ada entri contoh untuk tingkat ini.'),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final twoColumns = !compact && constraints.maxWidth >= 760;
                final rowWidth = twoColumns
                    ? (constraints.maxWidth - 12) / 2
                    : constraints.maxWidth;
                return Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 1,
                    children: [
                      for (final sample in samples)
                        SizedBox(
                          width: rowWidth,
                          child: _ActivityVolcanoRow(
                            sample: sample,
                            level: level,
                            onViewReport: () => onViewReport(sample),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ActivityVolcanoRow extends StatelessWidget {
  const _ActivityVolcanoRow({
    required this.sample,
    required this.level,
    required this.onViewReport,
  });

  final VolcanoActivitySample sample;
  final ActivityLevelSample level;
  final VoidCallback onViewReport;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 66),
    padding: const EdgeInsets.symmetric(vertical: 6),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0x557D9DB4))),
    ),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Image.asset(
            sample.image,
            width: 48,
            height: 40,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sample.name,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Provinsi contoh: ${sample.province}',
                style: const TextStyle(fontSize: 10),
              ),
              Text(
                'Status contoh: Level ${level.level} (${level.name})',
                style: TextStyle(fontSize: 9, color: Color(level.color)),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: onViewReport,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF0E9AE8),
            padding: const EdgeInsets.symmetric(horizontal: 7),
            minimumSize: const Size(0, 44),
          ),
          child: const Text('Lihat Laporan', style: TextStyle(fontSize: 10)),
        ),
      ],
    ),
  );
}

class _EmptySearchResult extends StatelessWidget {
  const _EmptySearchResult();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: const Color(0xFF174777),
      borderRadius: BorderRadius.circular(7),
      border: Border.all(color: const Color(0xFF3275A7)),
    ),
    child: const Column(
      children: [
        Icon(Icons.search_off, size: 30, color: Color(0xFFC7D2E0)),
        SizedBox(height: 7),
        Text('Tidak ada data contoh yang cocok dengan pencarian.'),
      ],
    ),
  );
}
