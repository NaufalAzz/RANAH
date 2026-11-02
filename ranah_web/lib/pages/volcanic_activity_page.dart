import 'package:flutter/material.dart';

import '../data/volcanic_activity_data.dart';
import '../models/gunung_data.dart';
import '../theme/ranah_theme.dart';
import '../widgets/ranah_full_width_title_background.dart';
import '../widgets/ranah_header.dart';

class VolcanicActivityPage extends StatefulWidget {
  const VolcanicActivityPage({
    required this.onBack,
    required this.onViewReport,
    required this.gunung,
    required this.isLoading,
    required this.error,
    required this.onRetry,
    super.key,
  });

  final VoidCallback onBack;
  final ValueChanged<GunungRecord> onViewReport;
  final List<GunungRecord> gunung;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;

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
      final contentWidth = width > RanahLayout.maxContentWidth
          ? RanahLayout.maxContentWidth
          : width;
      final horizontalInset = compact ? 8.0 : 28.0;
      final innerWidth = contentWidth - horizontalInset * 2;
      final query = _query.trim().toLowerCase();
      final visible = widget.gunung.where((item) {
        return item.nama.toLowerCase().contains(query) ||
            (item.provinsi ?? '').toLowerCase().contains(query) ||
            (item.kabupaten ?? '').toLowerCase().contains(query);
      }).toList();
      final sources =
          widget.gunung
              .map((item) => item.sumberData)
              .whereType<String>()
              .toSet()
              .toList()
            ..sort();
      final retrievalTimes =
          widget.gunung
              .map((item) => item.waktuPengambilan)
              .whereType<DateTime>()
              .toList()
            ..sort((a, b) => b.compareTo(a));
      final freshness = [
        if (sources.isNotEmpty) 'Sumber API: ${sources.join(', ')}.',
        if (retrievalTimes.isNotEmpty)
          'Data diambil server: ${_formatDateTime(retrievalTimes.first)}.',
        'Waktu pengambilan bukan waktu publikasi laporan; pembaruan tidak real-time.',
      ].join(' ');

      return RanahPageScrollLayout(
        maxContentWidth: contentWidth,
        horizontalInset: horizontalInset,
        title: _ActivityTitleBanner(maxContentWidth: contentWidth),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: RanahSpacing.xl),
            _ActivityBackBar(onBack: widget.onBack),
            const SizedBox(height: RanahSpacing.lg),
            _SourceDataNotice(text: freshness),
            const SizedBox(height: RanahSpacing.sm),
            _LevelSummaryRow(
              compact: compact,
              counts: {
                for (final level in activityLevels)
                  level.level: visible
                      .where((item) => item.activityLevel == level.level)
                      .length,
              },
            ),
            const SizedBox(height: RanahSpacing.md),
            _SearchField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: RanahSpacing.md),
            if (widget.isLoading && widget.gunung.isEmpty)
              const _ActivityLoadState(
                message: 'Memuat data gunung dari server...',
                loading: true,
              )
            else if (widget.error != null && widget.gunung.isEmpty)
              _ActivityLoadState(
                message: 'Daftar gunung belum dapat dimuat: ${widget.error}',
                onRetry: widget.onRetry,
              )
            else if (widget.isLoading)
              const LinearProgressIndicator()
            else if (widget.error != null)
              _ActivityLoadState(
                message:
                    'Pembaruan gagal. Menampilkan data yang terakhir diterima.',
                onRetry: widget.onRetry,
              )
            else if (widget.gunung.isEmpty)
              const _ActivityLoadState(
                message: 'Belum ada data gunung dari server.',
              )
            else if (visible.isEmpty)
              const _EmptySearchResult()
            else
              _ActivityGroups(
                gunung: visible,
                compact: compact,
                onViewReport: widget.onViewReport,
              ),
          ],
        ),
      );
    },
  );
}

class _ActivityTitleBanner extends StatelessWidget {
  const _ActivityTitleBanner({required this.maxContentWidth});

  final double maxContentWidth;

  @override
  Widget build(BuildContext context) => RanahFullWidthTitleBackground(
    color: RanahColors.banner,
    maxContentWidth: maxContentWidth,
    child: Container(
      constraints: const BoxConstraints(
        minHeight: RanahPageHeaderStyle.minHeight,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: RanahPageHeaderStyle.horizontalPadding,
        vertical: RanahPageHeaderStyle.verticalPadding,
      ),
      color: RanahColors.banner,
      child: const Row(
        children: [
          Icon(
            Icons.landscape_outlined,
            size: RanahPageHeaderStyle.iconSize,
          ),
          SizedBox(width: RanahPageHeaderStyle.iconGap),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SIAGA BENCANA',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: RanahPageHeaderStyle.kicker,
                ),
                Text(
                  'Aktivitas Gunung Api',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: RanahPageHeaderStyle.title,
                ),
                Text(
                  'Memantau aktivitas gunung api',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: RanahPageHeaderStyle.subtitle,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _ActivityBackBar extends StatelessWidget {
  const _ActivityBackBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: RanahSpacing.sm),
      child: Align(
        alignment: Alignment.centerLeft,
        child: RanahBackButton(onPressed: onBack),
      ),
    ),
  );
}

class _SourceDataNotice extends StatelessWidget {
  const _SourceDataNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: RanahColors.cardBlue,
      border: Border.all(color: Colors.white.withValues(alpha: .16)),
      borderRadius: BorderRadius.circular(RanahRadii.sm),
    ),
    child: Row(
      children: [
        Icon(Icons.info_outline, color: RanahColors.headerMuted, size: 18),
        SizedBox(width: RanahSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: Colors.white,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ActivityLoadState extends StatelessWidget {
  const _ActivityLoadState({
    required this.message,
    this.loading = false,
    this.onRetry,
  });

  final String message;
  final bool loading;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: RanahColors.cardBlue,
      borderRadius: BorderRadius.circular(RanahRadii.sm),
      border: Border.all(color: Colors.white.withValues(alpha: .16)),
    ),
    child: Column(
      children: [
        if (loading) const CircularProgressIndicator(),
        Text(message, textAlign: TextAlign.center),
        if (onRetry != null) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba lagi'),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
          ),
        ],
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
        runSpacing: RanahSpacing.sm,
        children: [
          for (final level in activityLevels)
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

  final ActivityLevelPresentation level;
  final int count;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    height: compact ? 68 : 76,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: RanahColors.cardBlue,
      borderRadius: BorderRadius.circular(RanahRadii.sm),
      border: Border.all(color: Color(level.color).withValues(alpha: .55)),
    ),
    child: Row(
      children: [
        Icon(
          Icons.change_history_rounded,
          color: Color(level.textColor),
          size: 18,
        ),
        const SizedBox(width: RanahSpacing.sm),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontSize: compact ? 18 : 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Level ${level.level} (${level.name})',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.25,
                  color: Color(level.textColor),
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
    height: 48,
    child: TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(color: RanahColors.ink, fontSize: 16),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: 'Cari nama gunung atau provinsi',
        hintStyle: TextStyle(color: RanahColors.muted, fontSize: 16),
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
                icon: const Icon(
                  Icons.close,
                  size: 18,
                  color: RanahColors.muted,
                ),
                tooltip: 'Hapus pencarian',
              ),
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RanahRadii.pill),
          borderSide: BorderSide.none,
        ),
      ),
    ),
  );
}

class _ActivityGroups extends StatelessWidget {
  const _ActivityGroups({
    required this.gunung,
    required this.compact,
    required this.onViewReport,
  });

  final List<GunungRecord> gunung;
  final bool compact;
  final ValueChanged<GunungRecord> onViewReport;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: RanahColors.backgroundStart,
      borderRadius: BorderRadius.circular(RanahRadii.md),
      border: Border.all(color: Colors.white.withValues(alpha: .16)),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: RanahSpacing.lg,
            vertical: RanahSpacing.md,
          ),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.white24)),
          ),
          child: const Text(
            'Daftar Tingkat Aktivitas Gunung Api',
            style: TextStyle(
              fontSize: 18,
              height: 1.25,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        for (final level in activityLevels)
          _ActivityLevelGroup(
            key: ValueKey('activity-level-${level.level}'),
            level: level,
            gunung: gunung
                .where((item) => item.activityLevel == level.level)
                .toList(),
            compact: compact,
            onViewReport: onViewReport,
          ),
        if (gunung.any((item) => item.activityLevel == null))
          _ActivityLevelGroup(
            key: const ValueKey('activity-level-unknown'),
            level: unknownActivityLevel,
            gunung: gunung.where((item) => item.activityLevel == null).toList(),
            compact: compact,
            onViewReport: onViewReport,
          ),
      ],
    ),
  );
}

class _ActivityLevelGroup extends StatefulWidget {
  const _ActivityLevelGroup({
    required this.level,
    required this.gunung,
    required this.compact,
    required this.onViewReport,
    super.key,
  });

  final ActivityLevelPresentation level;
  final List<GunungRecord> gunung;
  final bool compact;
  final ValueChanged<GunungRecord> onViewReport;

  @override
  State<_ActivityLevelGroup> createState() => _ActivityLevelGroupState();
}

class _ActivityLevelGroupState extends State<_ActivityLevelGroup> {
  static const _initialVisibleCount = 4;
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final gunung = widget.gunung;
    final level = widget.level;
    final visibleGunung = _showAll
        ? gunung
        : gunung.take(_initialVisibleCount).toList(growable: false);
    final hasMore = gunung.length > _initialVisibleCount;
    if (gunung.isEmpty && level.level != 4) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.fromLTRB(
        RanahSpacing.lg,
        RanahSpacing.md,
        RanahSpacing.lg,
        RanahSpacing.md,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  level.level == 0
                      ? 'Status aktivitas belum diketahui'
                      : 'Level ${level.level} · ${level.name}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: RanahSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: RanahSpacing.sm,
                  vertical: RanahSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: RanahColors.backgroundMiddle,
                  borderRadius: BorderRadius.circular(RanahRadii.pill),
                  border: Border.all(color: Color(level.color)),
                ),
                child: Text(
                  '${gunung.length} gunung',
                  style: TextStyle(
                    color: Color(level.textColor),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (level.level == 0) ...[
            const SizedBox(height: RanahSpacing.xs),
            const Text(
              'API tidak memberikan level aktivitas yang dapat dikenali.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Color(0xFFE0E6EF),
              ),
            ),
          ],
          if (gunung.isEmpty)
            const Padding(
              padding: EdgeInsets.only(
                top: RanahSpacing.md,
                bottom: RanahSpacing.xs,
              ),
              child: Text('Belum ada gunung pada tingkat ini di respons API.'),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final twoColumns =
                    !widget.compact && constraints.maxWidth >= 760;
                final rowWidth = twoColumns
                    ? (constraints.maxWidth - 12) / 2
                    : constraints.maxWidth;
                return Padding(
                  padding: const EdgeInsets.only(top: RanahSpacing.sm),
                  child: Wrap(
                    spacing: RanahSpacing.md,
                    runSpacing: RanahSpacing.md,
                    children: [
                      for (final item in visibleGunung)
                        SizedBox(
                          width: rowWidth,
                          child: _ActivityVolcanoRow(
                            gunung: item,
                            level: level,
                            onViewReport: () => widget.onViewReport(item),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          if (hasMore)
            Padding(
              padding: const EdgeInsets.only(top: RanahSpacing.md),
              child: Align(
                alignment: Alignment.center,
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _showAll = !_showAll),
                  icon: Icon(
                    _showAll
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                  ),
                  label: Text(
                    _showAll
                        ? 'Tampilkan lebih sedikit'
                        : 'Muat lainnya (${gunung.length - _initialVisibleCount})',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF79A8C5)),
                    minimumSize: const Size(48, 44),
                    padding: const EdgeInsets.symmetric(
                      horizontal: RanahSpacing.lg,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(RanahRadii.sm),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActivityVolcanoRow extends StatelessWidget {
  const _ActivityVolcanoRow({
    required this.gunung,
    required this.level,
    required this.onViewReport,
  });

  final GunungRecord gunung;
  final ActivityLevelPresentation level;
  final VoidCallback onViewReport;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(RanahSpacing.md),
    decoration: BoxDecoration(
      color: RanahColors.cardBlue,
      borderRadius: BorderRadius.circular(RanahRadii.md),
      border: Border.all(color: Colors.white.withValues(alpha: .16)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(RanahRadii.sm),
              child: Container(
                width: 48,
                height: 48,
                color: RanahColors.backgroundStart,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.landscape_outlined,
                  color: Colors.white70,
                ),
              ),
            ),
            const SizedBox(width: RanahSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gunung.nama.trim().isEmpty
                        ? 'Nama gunung belum tersedia'
                        : gunung.nama.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: RanahSpacing.xs),
                  Text(
                    _region(gunung),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.25,
                      color: Color(0xFFE0E6EF),
                    ),
                  ),
                  const SizedBox(height: RanahSpacing.xs),
                  Text(
                    _activityStatus(gunung.statusAktivitas),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                      color: Color(level.textColor),
                    ),
                  ),
                  const SizedBox(height: RanahSpacing.xs),
                  Text(
                    'Sumber: ${_sourceName(gunung.sumberData)} · '
                    'Diambil server: ${_formatDateTime(gunung.waktuPengambilan)}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.25,
                      color: Color(0xFFE0E6EF),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: RanahSpacing.sm),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            onPressed: onViewReport,
            icon: const Icon(Icons.open_in_new_rounded, size: 18),
            label: const Text('Lihat Laporan'),
            style: OutlinedButton.styleFrom(
              foregroundColor: RanahColors.white,
              side: BorderSide(color: Colors.white.withValues(alpha: .55)),
              padding: const EdgeInsets.symmetric(horizontal: RanahSpacing.md),
              minimumSize: const Size(48, 48),
              tapTargetSize: MaterialTapTargetSize.padded,
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

String _activityStatus(String? value) {
  final status = value?.trim();
  return status == null || status.isEmpty
      ? 'Status aktivitas belum tersedia'
      : status;
}

String _sourceName(String? value) {
  final source = value?.trim();
  return source == null || source.isEmpty ? 'Belum tersedia' : source;
}

class _EmptySearchResult extends StatelessWidget {
  const _EmptySearchResult();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: RanahColors.cardBlue,
      borderRadius: BorderRadius.circular(RanahRadii.sm),
      border: Border.all(color: Colors.white.withValues(alpha: .16)),
    ),
    child: const Column(
      children: [
        Icon(Icons.search_off, size: 30, color: Color(0xFFC7D2E0)),
        SizedBox(height: 7),
        Text('Tidak ada data gunung yang cocok dengan pencarian.'),
      ],
    ),
  );
}

String _region(GunungRecord gunung) {
  final values = [gunung.kabupaten, gunung.provinsi]
      .whereType<String>()
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList();
  return values.isEmpty
      ? 'Lokasi administratif belum tersedia'
      : values.join(', ');
}

String _formatDateTime(DateTime? value) {
  if (value == null) return 'Belum tersedia';
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/${local.year} $hour:$minute';
}
