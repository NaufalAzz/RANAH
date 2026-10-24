import 'package:flutter/material.dart';

import '../pages/gunung_report_page.dart';
import '../services/gunung_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/app_page_banner.dart';
import '../widgets/app_background.dart';
import '../widgets/gunung_freshness_notice.dart';
import '../widgets/ranah_page_route.dart';

const _activityLevels =
    <({String label, String key, Color color, IconData icon})>[
      (
        label: 'Level IV - Awas',
        key: 'iv',
        color: AppColors.danger,
        icon: Icons.warning_rounded,
      ),
      (
        label: 'Level III - Siaga',
        key: 'iii',
        color: AppColors.watch,
        icon: Icons.warning_amber_rounded,
      ),
      (
        label: 'Level II - Waspada',
        key: 'ii',
        color: AppColors.warning,
        icon: Icons.change_circle_outlined,
      ),
      (
        label: 'Level I - Normal',
        key: 'i',
        color: AppColors.normal,
        icon: Icons.check_circle_outline_rounded,
      ),
    ];

class VolcanicActivityPage extends StatefulWidget {
  const VolcanicActivityPage({
    super.key,
    required this.onBack,
    this.repository,
  });

  final VoidCallback onBack;
  final GunungDataRepository? repository;

  @override
  State<VolcanicActivityPage> createState() => _VolcanicActivityPageState();
}

class _VolcanicActivityPageState extends State<VolcanicActivityPage> {
  late final GunungDataRepository _repository;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _items = [];
  DateTime? _lastCheckedAt;
  Object? _syncError;
  bool _isLoading = true;
  bool _isFromCache = true;
  bool _apiReturnedEmpty = false;
  bool _syncing = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? GunungRepository();
    _initialize();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      final cached = await _repository.readGunungCache();
      if (!mounted) return;
      setState(() {
        _items = cached.items;
        _lastCheckedAt = cached.lastCheckedAt;
        _isFromCache = true;
        _isLoading = _items.isEmpty && _lastCheckedAt == null;
      });
    } catch (_) {
      // Network sync below is still useful if the local database cannot open.
    }
    await _reload();
  }

  Future<void> _reload() async {
    if (_syncing) return;
    setState(() {
      _syncing = true;
      _syncError = null;
      if (_items.isEmpty && _lastCheckedAt == null) _isLoading = true;
    });
    try {
      final snapshot = await _repository.syncGunung();
      if (!mounted) return;
      setState(() {
        _items = snapshot.items;
        _lastCheckedAt = snapshot.lastCheckedAt;
        _isFromCache = false;
        _apiReturnedEmpty = snapshot.apiReturnedEmpty;
        _syncError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _syncError = Object());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _syncing = false;
        });
      }
    }
  }

  String _status(dynamic value) {
    final status = value?.toString().trim() ?? '';
    return status.isEmpty ? 'Belum diverifikasi' : status;
  }

  String? _levelKey(dynamic value) {
    final status = _status(value).toLowerCase();
    final match = RegExp(r'\blevel\s*(iv|iii|ii|i|4|3|2|1)\b')
        .firstMatch(status);
    if (match == null) return null;
    return switch (match.group(1)) {
      '4' => 'iv',
      '3' => 'iii',
      '2' => 'ii',
      '1' => 'i',
      final key => key,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B233A),
      appBar: AppBar(
        leading: IconButton(
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Kembali',
        ),
        title: const Text('Aktivitas Gunung Api'),
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Muat ulang data',
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(decoration: AppBackground.decoration),
          ColoredBox(color: const Color(0x66091C30)),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_items.isEmpty && _syncError != null)
            _ActivityMessage(
              icon: Icons.cloud_off_outlined,
              message: 'Data gunung belum tersedia di perangkat saat offline.',
              action: FilledButton.icon(
                onPressed: _reload,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba lagi'),
              ),
            )
          else
            _buildActivityList(),
        ],
      ),
    );
  }

  Widget _buildActivityList() {
    final all = _items;
    final visible = all.where(_matchesSearch).toList();
    final unverified = visible
        .where((item) => _levelKey(item['status_aktivitas']) == null)
        .toList();
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          _TitlePanel(total: all.length),
          const SizedBox(height: 12),
          GunungFreshnessNotice(
            isFromCache: _isFromCache,
            lastCheckedAt: _lastCheckedAt,
            hasError: _syncError != null,
            apiReturnedEmpty: _apiReturnedEmpty && all.isNotEmpty,
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.15,
            children: [
              for (final level in _activityLevels)
                _LevelCountCard(
                  level: level,
                  count: visible
                      .where(
                        (item) =>
                            _levelKey(item['status_aktivitas']) == level.key,
                      )
                      .length,
                ),
            ],
          ),
          const SizedBox(height: 12),
          _SearchField(
            controller: _searchController,
            query: _query,
            onChanged: (value) => setState(() => _query = value),
            onClear: () {
              _searchController.clear();
              setState(() => _query = '');
            },
          ),
          const SizedBox(height: 16),
          if (all.isEmpty)
            const _ActivityMessage(
              icon: Icons.landscape_outlined,
              message: 'Belum ada data gunung dari API RANAH.',
            )
          else if (visible.isEmpty)
            const _ActivityMessage(
              icon: Icons.search_off_rounded,
              message: 'Tidak ada gunung yang cocok dengan pencarian.',
            )
          else ...[
            for (final level in _activityLevels)
              _LevelSection(
                level: level,
                items: visible
                    .where(
                      (item) =>
                          _levelKey(item['status_aktivitas']) == level.key,
                    )
                    .toList(),
                onOpenReport: _openReport,
              ),
            if (unverified.isNotEmpty)
              _UnverifiedSection(items: unverified, onOpenReport: _openReport),
          ],
          const SizedBox(height: 12),
          const Text(
            'Pengelompokan mengikuti teks status yang dikirim API RANAH. '
            'Status dan sumbernya belum diverifikasi terhadap PVMBG; '
            'data ini bukan peringatan resmi.',
            style: TextStyle(
              color: Color(0xFFE2EDF5),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  bool _matchesSearch(Map item) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;
    return [
          item['nama'],
          item['provinsi'],
          item['kabupaten'],
          item['status_aktivitas'],
        ]
        .where((value) => value != null)
        .any((value) => value.toString().toLowerCase().contains(query));
  }

  void _openReport(Map item) {
    final id = item['id'];
    if (id is! int) return;
    Navigator.of(context).push(
      RanahPageRoute<void>(
        context: context,
        builder: (_) => GunungReportPage(
          gunungId: id,
          namaGunung: item['nama']?.toString(),
        ),
      ),
    );
  }
}

class _TitlePanel extends StatelessWidget {
  const _TitlePanel({required this.total});
  final int total;

  @override
  Widget build(BuildContext context) {
    return AppPageBanner(
      icon: Icons.landscape_outlined,
      eyebrow: 'INFORMASI RANAH',
      title: 'Tingkat Aktivitas Gunung Api',
      subtitle: '$total data gunung dari API RANAH',
      minHeight: 0,
      padding: const EdgeInsets.all(AppSpacing.md),
      iconSize: 38,
      iconGap: AppSpacing.sm,
      eyebrowStyle: AppTypography.bannerEyebrow.copyWith(fontSize: 13),
      gradient: const LinearGradient(
        colors: [Color(0xE8200B59), Color(0xE5101736)],
      ),
      borderRadius: BorderRadius.circular(AppRadii.compact),
      border: Border.all(color: Colors.white.withValues(alpha: .12)),
    );
  }
}

class _LevelCountCard extends StatelessWidget {
  const _LevelCountCard({required this.level, required this.count});
  final ({String label, String key, Color color, IconData icon}) level;
  final int count;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0xD9173551),
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: level.color.withValues(alpha: .8)),
    ),
    child: Row(
      children: [
        Icon(level.icon, color: level.color, size: 23),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$count',
                style: TextStyle(
                  color: level.color,
                  fontSize: 20,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                level.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: level.color,
                  fontSize: 13,
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
  const _SearchField({
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.onClear,
  });
  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    onChanged: onChanged,
    decoration: InputDecoration(
      hintText: 'Cari nama gunung atau provinsi',
      prefixIcon: const Icon(Icons.search_rounded),
      suffixIcon: query.isEmpty
          ? null
          : IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Hapus pencarian',
            ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide.none,
      ),
    ),
  );
}

class _LevelSection extends StatelessWidget {
  const _LevelSection({
    required this.level,
    required this.items,
    required this.onOpenReport,
  });
  final ({String label, String key, Color color, IconData icon}) level;
  final List<Map> items;
  final ValueChanged<Map> onOpenReport;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xD9163552),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: .17)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 11, 12, 8),
            child: Text(
              '${level.label}  •  ${items.length} gunung',
              style: TextStyle(
                color: level.color,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          for (final item in items)
            _GunungRow(
              item: item,
              statusColor: level.color,
              onOpenReport: onOpenReport,
            ),
        ],
      ),
    );
  }
}

class _UnverifiedSection extends StatelessWidget {
  const _UnverifiedSection({required this.items, required this.onOpenReport});
  final List<Map> items;
  final ValueChanged<Map> onOpenReport;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: const Color(0xD9163552),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFE1B95C)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 11, 12, 8),
          child: Text(
            'Belum diverifikasi  •  ${items.length} gunung',
            style: const TextStyle(
              color: Color(0xFFFFD278),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        for (final item in items)
          _GunungRow(
            item: item,
            statusColor: const Color(0xFFFFD278),
            onOpenReport: onOpenReport,
          ),
      ],
    ),
  );
}

class _GunungRow extends StatelessWidget {
  const _GunungRow({
    required this.item,
    required this.statusColor,
    required this.onOpenReport,
  });
  final Map item;
  final Color statusColor;
  final ValueChanged<Map> onOpenReport;

  @override
  Widget build(BuildContext context) {
    final nama = item['nama']?.toString() ?? 'Nama gunung belum tersedia';
    final lokasi = [item['kabupaten'], item['provinsi']]
        .where((value) => value != null && value.toString().trim().isNotEmpty)
        .join(', ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: .14)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF214C68),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.landscape_rounded,
              color: Color(0xFFBFD9E8),
              size: 28,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  lokasi.isEmpty ? 'Lokasi belum tersedia' : lokasi,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFD1E0E9),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item['status_aktivitas']?.toString().trim().isNotEmpty == true
                      ? item['status_aktivitas'].toString()
                      : 'Belum diverifikasi',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          TextButton(
            onPressed: item['id'] is int ? () => onOpenReport(item) : null,
            child: const Text('Lihat Laporan'),
          ),
        ],
      ),
    );
  }
}

class _ActivityMessage extends StatelessWidget {
  const _ActivityMessage({
    required this.icon,
    required this.message,
    this.action,
  });
  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 42),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          if (action != null) ...[const SizedBox(height: 12), action!],
        ],
      ),
    ),
  );
}
