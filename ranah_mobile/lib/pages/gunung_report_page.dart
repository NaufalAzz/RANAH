import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/gunung_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/app_page_banner.dart';
import '../widgets/gunung_freshness_notice.dart';
import '../widgets/ranah_page_route.dart';
import '../widgets/volcano_interactive_map.dart';

class GunungReportPage extends StatefulWidget {
  const GunungReportPage({
    super.key,
    required this.gunungId,
    this.namaGunung,
    this.repository,
    this.showMapTiles = true,
  });

  final int gunungId;
  final String? namaGunung;
  final GunungDataRepository? repository;
  final bool showMapTiles;

  @override
  State<GunungReportPage> createState() => _GunungReportPageState();
}

class _GunungReportPageState extends State<GunungReportPage> {
  late final GunungDataRepository _repository;
  Map<String, dynamic>? _data;
  DateTime? _lastCheckedAt;
  Object? _syncError;
  bool _isLoading = true;
  bool _isFromCache = true;
  bool _syncing = false;
  List<Map<String, dynamic>> _mapItems = [];

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? GunungRepository();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final list = await _repository.readGunungCache();
      if (mounted) setState(() => _mapItems = list.items);
    } catch (_) {
      // The selected detail can still provide a single cached map marker.
    }
    try {
      final cached = await _repository.readDetailCache(widget.gunungId);
      if (!mounted) return;
      if (cached != null) {
        setState(() {
          _data = cached.data;
          _lastCheckedAt = cached.lastCheckedAt;
          _isFromCache = true;
          _isLoading = false;
        });
      }
    } catch (_) {
      // Continue with a network attempt when local storage is unavailable.
    }
    if (!mounted) return;
    await _muatUlang();
  }

  Future<void> _muatUlang() async {
    if (_syncing) return;
    setState(() {
      _syncing = true;
      _syncError = null;
    });
    try {
      final snapshot = await _repository.syncDetail(widget.gunungId);
      if (!mounted) return;
      setState(() {
        _data = snapshot.data;
        _mergeMapGunung(snapshot.data['gunung']);
        _lastCheckedAt = snapshot.lastCheckedAt;
        _isFromCache = false;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B233A),
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Kembali',
        ),
        title: const Text('Laporan Gunung Api'),
        actions: [
          IconButton(
            onPressed: _muatUlang,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Muat ulang laporan',
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(decoration: AppBackground.decoration),
          const ColoredBox(color: Color(0x66091C30)),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_data == null)
            _ReportState(
              icon: Icons.cloud_off_outlined,
              title: 'Laporan belum tersedia offline',
              message: 'Data gunung ini belum tersimpan di perangkat.',
              action: FilledButton.icon(
                onPressed: _muatUlang,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba lagi'),
              ),
            )
          else
            _buildReport(_data!),
        ],
      ),
    );
  }

  Widget _buildReport(Map<String, dynamic> data) {
    final gunung = data['gunung'] is Map
        ? Map<String, dynamic>.from(data['gunung'] as Map)
        : <String, dynamic>{};
    final rawReports = data['laporan'];
    final reports = rawReports is List
        ? rawReports.whereType<Map>().map(Map<String, dynamic>.from).toList()
        : <Map<String, dynamic>>[];
    final laporan = reports.isNotEmpty ? reports.first : null;
    final reportData = laporan ?? <String, dynamic>{};
    final mapItems = _itemsWithCurrentGunung(gunung);

    return RefreshIndicator(
      onRefresh: _muatUlang,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          const _ReportHeading(),
          const SizedBox(height: 10),
          GunungFreshnessNotice(
            isFromCache: _isFromCache,
            lastCheckedAt: _lastCheckedAt,
            sourceRetrievedAt: gunungTime(_data),
            hasError: _syncError != null,
          ),
          const SizedBox(height: 10),
          VolcanoInteractiveMap(
            items: mapItems,
            selectedId: widget.gunungId,
            onOpenDetail: _openMapDetail,
            tilesEnabled: widget.showMapTiles,
          ),
          const SizedBox(height: 10),
          _StatusBadge(
            status: _text(gunung['status_aktivitas'], 'Belum diverifikasi'),
          ),
          const SizedBox(height: 12),
          if (laporan == null)
            const _ReportState(
              icon: Icons.description_outlined,
              title: 'Belum ada laporan pengamatan',
              message:
                  'Belum ada laporan terkait yang tersimpan untuk gunung ini.',
            )
          else
            _ReportCard(
              nama: _text(gunung['nama'], widget.namaGunung ?? 'Gunung api'),
              imageUrl: _imageUrl(laporan['foto']),
              fallbackPhotoPath: laporan['foto']?.toString(),
            ),
          const SizedBox(height: 10),
          _InfoSection(
            title: 'Lokasi Administratif dan Geografis',
            icon: Icons.place_outlined,
            rows: [
              ('Kabupaten', _text(gunung['kabupaten'], 'Belum tersedia')),
              ('Provinsi', _text(gunung['provinsi'], 'Belum tersedia')),
              (
                'Koordinat',
                _coordinates(gunung['latitude'], gunung['longitude']),
              ),
            ],
          ),
          if (laporan != null) ...[
            const SizedBox(height: 10),
            _InfoSection(
              title: 'Periode Pengamatan',
              icon: Icons.calendar_month_outlined,
              rows: [
                ('Periode', _period(reportData)),
                if (_text(reportData['periode_waktu'], '').isNotEmpty)
                  ('Waktu', _text(reportData['periode_waktu'], '')),
              ],
            ),
            const SizedBox(height: 10),
            _InfoSection(
              title: 'Klimatologi',
              icon: Icons.cloud_outlined,
              rows: [
                (
                  'Data',
                  _text(reportData['data_klimatologi'], 'Belum tersedia'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _InfoSection(
              title: 'Pengamatan Visual',
              icon: Icons.visibility_outlined,
              rows: [
                (
                  'Data',
                  _text(reportData['pengamatan_visual'], 'Belum tersedia'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _InfoSection(
              title: 'Rekomendasi',
              icon: Icons.shield_outlined,
              rows: [
                (
                  'Arahan tercatat',
                  _text(reportData['rekomendasi'], 'Belum tersedia'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _InfoSection(
              title: 'Sumber dan Pembaruan',
              icon: Icons.source_outlined,
              rows: [
                ('Sumber', _text(reportData['sumber'], 'Belum tersedia')),
                (
                  'Waktu publikasi',
                  _publicationDate(reportData['waktu_publikasi']),
                ),
                (
                  'Data diambil server',
                  _text(
                    reportData['waktu_pengambilan'] ??
                        gunung['waktu_pengambilan'],
                    'Belum tersedia',
                  ),
                ),
              ],
            ),
            if (_validSourceUrl(reportData['url_sumber']) case final sourceUrl?)
              TextButton.icon(
                onPressed: () => _openSource(context, sourceUrl),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Buka laporan MAGMA'),
                style: TextButton.styleFrom(foregroundColor: Colors.white),
              ),
          ],
          const SizedBox(height: 10),
          _EstimatedZone(radius: gunung['radius_perkiraan_km']),
          const SizedBox(height: 12),
          const Text(
            'Data ditampilkan sesuai respons API RANAH. Status dan rekomendasi '
            'perlu merujuk sumber resmi. Zona perkiraan bukan batas KRB resmi. '
            'RANAH bukan pengganti arahan PVMBG dan BPBD.',
            style: TextStyle(
              color: Color(0xFFE2EDF5),
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _itemsWithCurrentGunung(
    Map<String, dynamic> gunung,
  ) {
    final items = List<Map<String, dynamic>>.from(_mapItems);
    final index = items.indexWhere(
      (item) => item['id'].toString() == gunung['id']?.toString(),
    );
    if (index < 0) {
      items.add(gunung);
    } else {
      items[index] = {...items[index], ...gunung};
    }
    return items;
  }

  void _mergeMapGunung(dynamic raw) {
    if (raw is! Map) return;
    final gunung = Map<String, dynamic>.from(raw);
    final id = gunung['id']?.toString();
    if (id == null) return;
    final index = _mapItems.indexWhere((item) => item['id']?.toString() == id);
    if (index < 0) {
      _mapItems = [..._mapItems, gunung];
    } else {
      _mapItems[index] = {..._mapItems[index], ...gunung};
    }
  }

  void _openMapDetail(Map<String, dynamic> item) {
    final id = int.tryParse(item['id']?.toString() ?? '');
    if (id == null || id == widget.gunungId) return;
    Navigator.of(context).push(
      RanahPageRoute<void>(
        context: context,
        builder: (_) => GunungReportPage(
          gunungId: id,
          namaGunung: item['nama']?.toString(),
          repository: _repository,
          showMapTiles: widget.showMapTiles,
        ),
      ),
    );
  }

  String? _imageUrl(dynamic value) {
    final raw = value?.toString().trim() ?? '';
    final uri = Uri.tryParse(raw);
    if (uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty) {
      return raw;
    }
    return null;
  }

  String _coordinates(dynamic latitude, dynamic longitude) {
    if (latitude == null || longitude == null) {
      return 'Koordinat belum tersedia';
    }
    return '$latitude, $longitude';
  }

  String _period(Map<String, dynamic> report) {
    final start = _text(report['periode_mulai'], '');
    final end = _text(report['periode_selesai'], '');
    if (start.isEmpty && end.isEmpty) return 'Periode belum tersedia';
    if (start.isNotEmpty && end.isNotEmpty) return '$start sampai $end';
    return start.isEmpty ? 'Sampai $end' : 'Mulai $start';
  }

  String _publicationDate(dynamic value) {
    final text = _text(value, 'Belum tersedia');
    final parsed = DateTime.tryParse(text);
    if (parsed == null) return text;
    final local = parsed.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }

  String? _validSourceUrl(dynamic value) {
    final uri = Uri.tryParse(value?.toString() ?? '');
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host != 'magma.esdm.go.id') {
      return null;
    }
    return uri.toString();
  }

  Future<void> _openSource(BuildContext context, String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host != 'magma.esdm.go.id') {
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tautan sumber tidak dapat dibuka.')),
      );
    }
  }

  String? gunungTime(Map<String, dynamic>? data) {
    final gunung = data?['gunung'];
    final reports = data?['laporan'];
    if (reports is List && reports.isNotEmpty && reports.first is Map) {
      final report = reports.first as Map;
      final retrieved = report['waktu_pengambilan']?.toString();
      if (retrieved != null && retrieved.isNotEmpty) return retrieved;
    }
    return gunung is Map ? gunung['waktu_pengambilan']?.toString() : null;
  }

  String _text(dynamic value, String fallback) {
    if (value == null || value.toString().trim().isEmpty) return fallback;
    return value.toString().trim();
  }
}

class _ReportHeading extends StatelessWidget {
  const _ReportHeading();

  @override
  Widget build(BuildContext context) => const AppPageBanner(
    icon: Icons.landscape_outlined,
    eyebrow: 'INFORMASI RANAH',
    title: 'Aktivitas Gunung Api',
    subtitle: 'Laporan dan informasi yang tersedia',
    minHeight: 0,
    padding: EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm,
    ),
    iconSize: 38,
    iconGap: AppSpacing.sm,
    eyebrowStyle: TextStyle(
      color: AppColors.bannerEyebrow,
      fontSize: 13,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.8,
    ),
    gradient: LinearGradient(colors: [Color(0xE8200B59), Color(0xE5101736)]),
    borderRadius: BorderRadius.all(Radius.circular(AppRadii.compact)),
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF5C04D),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: Color(0xFF382500),
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.nama,
    required this.imageUrl,
    required this.fallbackPhotoPath,
  });
  final String nama;
  final String? imageUrl;
  final String? fallbackPhotoPath;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xE5173A5B),
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: const Color(0xFF397394)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Laporan Gunung Api',
          style: TextStyle(
            color: Color(0xFF9ED7FF),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          nama,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 9),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            width: double.infinity,
            height: 148,
            child: imageUrl == null
                ? _PhotoUnavailable(path: fallbackPhotoPath)
                : Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _PhotoUnavailable(path: fallbackPhotoPath),
                  ),
          ),
        ),
      ],
    ),
  );
}

class _PhotoUnavailable extends StatelessWidget {
  const _PhotoUnavailable({this.path});
  final String? path;

  @override
  Widget build(BuildContext context) {
    final pathValue = path;
    final hasPath = pathValue != null && pathValue.trim().isNotEmpty;
    return Container(
      color: const Color(0xFF23445B),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.image_not_supported_outlined,
              color: Color(0xFFD0E0E9),
              size: 34,
            ),
            const SizedBox(height: 5),
            Text(
              hasPath
                  ? 'Foto belum dapat ditampilkan'
                  : 'Foto laporan belum tersedia',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.title,
    required this.icon,
    required this.rows,
  });
  final String title;
  final IconData icon;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xE5173A5B),
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: const Color(0xFF397394)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF9ED7FF), size: 19),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final row in rows) ...[
          if (rows.length > 1)
            Text(
              row.$1,
              style: const TextStyle(
                color: Color(0xFFD1E5F1),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          Text(
            row.$2,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          if (row != rows.last) const SizedBox(height: 7),
        ],
      ],
    ),
  );
}

class _EstimatedZone extends StatelessWidget {
  const _EstimatedZone({required this.radius});
  final dynamic radius;

  @override
  Widget build(BuildContext context) {
    final hasRadius = radius != null && radius.toString().trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xE5173A5B),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFF397394)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.radar_rounded, color: Color(0xFFFFD278), size: 21),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Zona perkiraan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasRadius
                      ? 'Radius perkiraan: $radius km. Bukan batas KRB resmi.'
                      : 'Data radius perkiraan belum tersedia. Batas KRB resmi tidak ditampilkan.',
                  style: const TextStyle(
                    color: Color(0xFFE6EDF2),
                    fontSize: 13,
                    height: 1.35,
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

class _ReportState extends StatelessWidget {
  const _ReportState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 44),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(color: Color(0xFFE2EDF5)),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[const SizedBox(height: 14), action!],
        ],
      ),
    ),
  );
}
