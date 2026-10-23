import 'package:flutter/material.dart';

import '../pages/gunung_report_page.dart';
import '../services/api_service.dart';
import '../widgets/app_background.dart';

const _activityLevels =
    <({String label, String key, Color color, IconData icon})>[
      (
        label: 'Level IV - Awas',
        key: 'iv',
        color: Color(0xFFEF5555),
        icon: Icons.warning_rounded,
      ),
      (
        label: 'Level III - Siaga',
        key: 'iii',
        color: Color(0xFFF28B39),
        icon: Icons.warning_amber_rounded,
      ),
      (
        label: 'Level II - Waspada',
        key: 'ii',
        color: Color(0xFFE7B938),
        icon: Icons.change_circle_outlined,
      ),
      (
        label: 'Level I - Normal',
        key: 'i',
        color: Color(0xFF45B978),
        icon: Icons.check_circle_outline_rounded,
      ),
    ];

class VolcanicActivityPage extends StatefulWidget {
  const VolcanicActivityPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<VolcanicActivityPage> createState() => _VolcanicActivityPageState();
}

class _VolcanicActivityPageState extends State<VolcanicActivityPage> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  late Future<List<dynamic>> _futureGunung;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _futureGunung = _apiService.getGunung();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final request = _apiService.getGunung();
    setState(() => _futureGunung = request);
    try {
      await request;
    } catch (_) {
      // FutureBuilder menampilkan keadaan gagal.
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
          FutureBuilder<List<dynamic>>(
            future: _futureGunung,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return _ActivityMessage(
                  icon: Icons.cloud_off_outlined,
                  message: 'Data aktivitas gunung belum dapat dimuat.',
                  action: FilledButton.icon(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Coba lagi'),
                  ),
                );
              }

              final all = (snapshot.data ?? []).whereType<Map>().toList();
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
                    _DataNotice(),
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
                                      _levelKey(item['status_aktivitas']) ==
                                      level.key,
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
                        message:
                            'Tidak ada gunung yang cocok dengan pencarian.',
                      )
                    else ...[
                      for (final level in _activityLevels)
                        _LevelSection(
                          level: level,
                          items: visible
                              .where(
                                (item) =>
                                    _levelKey(item['status_aktivitas']) ==
                                    level.key,
                              )
                              .toList(),
                          onOpenReport: _openReport,
                        ),
                      if (unverified.isNotEmpty)
                        _UnverifiedSection(
                          items: unverified,
                          onOpenReport: _openReport,
                        ),
                    ],
                    const SizedBox(height: 12),
                    const Text(
                      'Pengelompokan mengikuti teks status yang dikirim API RANAH. '
                      'Status dan sumbernya belum diverifikasi terhadap PVMBG; '
                      'data ini bukan peringatan resmi.',
                      style: TextStyle(
                        color: Color(0xFFE2EDF5),
                        fontSize: 12,
                        height: 1.4,
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
      MaterialPageRoute<void>(
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xE8200B59), Color(0xE5101736)],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: .12)),
      ),
      child: Row(
        children: [
          const Icon(Icons.landscape_outlined, color: Colors.white, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'INFORMASI RANAH',
                  style: TextStyle(
                    color: Color(0xFF8BC8FF),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .8,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Tingkat Aktivitas Gunung Api',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '$total data gunung dari API RANAH',
                  style: const TextStyle(
                    color: Color(0xFFD5DCE7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DataNotice extends StatelessWidget {
  const _DataNotice();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xE8163854),
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: const Color(0xFF5883A1)),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline_rounded, color: Color(0xFFFFD278), size: 21),
        SizedBox(width: 9),
        Expanded(
          child: Text(
            'Data API RANAH. Status aktivitas belum diverifikasi ke sumber resmi.',
            style: TextStyle(color: Colors.white, fontSize: 12, height: 1.35),
          ),
        ),
      ],
    ),
  );
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
                  fontSize: 9,
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
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item['status_aktivitas']?.toString().trim().isNotEmpty == true
                      ? item['status_aktivitas'].toString()
                      : 'Belum diverifikasi',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
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
