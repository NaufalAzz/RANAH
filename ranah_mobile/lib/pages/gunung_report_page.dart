import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../widgets/app_background.dart';

class GunungReportPage extends StatefulWidget {
  const GunungReportPage({super.key, required this.gunungId, this.namaGunung});

  final int gunungId;
  final String? namaGunung;

  @override
  State<GunungReportPage> createState() => _GunungReportPageState();
}

class _GunungReportPageState extends State<GunungReportPage> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _apiService.getDetailGunung(widget.gunungId);
  }

  Future<void> _muatUlang() async {
    final request = _apiService.getDetailGunung(widget.gunungId);
    setState(() => _future = request);
    try {
      await request;
    } catch (_) {
      // FutureBuilder menampilkan keadaan gagal.
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
          FutureBuilder<Map<String, dynamic>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return _ReportState(
                  icon: Icons.cloud_off_outlined,
                  title: 'Laporan belum dapat dimuat',
                  message: 'Periksa koneksi atau coba muat ulang data.',
                  action: FilledButton.icon(
                    onPressed: _muatUlang,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Coba lagi'),
                  ),
                );
              }

              final data = snapshot.data ?? {};
              final gunung = data['gunung'] is Map
                  ? Map<String, dynamic>.from(data['gunung'] as Map)
                  : <String, dynamic>{};
              final rawReports = data['laporan'];
              final laporan =
                  rawReports is List &&
                      rawReports.isNotEmpty &&
                      rawReports.first is Map
                  ? Map<String, dynamic>.from(rawReports.first as Map)
                  : null;
              final reportData = laporan ?? <String, dynamic>{};

              return RefreshIndicator(
                onRefresh: _muatUlang,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                  children: [
                    const _ReportHeading(),
                    const SizedBox(height: 10),
                    _ReportMapPlaceholder(
                      nama: _text(
                        gunung['nama'],
                        widget.namaGunung ?? 'Gunung api',
                      ),
                      hasCoordinates:
                          gunung['latitude'] != null &&
                          gunung['longitude'] != null,
                    ),
                    const SizedBox(height: 10),
                    _StatusBadge(
                      status: _text(
                        gunung['status_aktivitas'],
                        'Belum diverifikasi',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ReportCard(
                      nama: _text(
                        gunung['nama'],
                        widget.namaGunung ?? 'Gunung api',
                      ),
                      imageUrl: _imageUrl(laporan?['foto']),
                      fallbackPhotoPath: laporan?['foto']?.toString(),
                    ),
                    const SizedBox(height: 10),
                    _InfoSection(
                      title: 'Lokasi Administratif dan Geografis',
                      icon: Icons.place_outlined,
                      rows: [
                        (
                          'Kabupaten',
                          _text(gunung['kabupaten'], 'Belum tersedia'),
                        ),
                        (
                          'Provinsi',
                          _text(gunung['provinsi'], 'Belum tersedia'),
                        ),
                        (
                          'Koordinat',
                          _coordinates(gunung['latitude'], gunung['longitude']),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _InfoSection(
                      title: 'Periode Pengamatan',
                      icon: Icons.calendar_month_outlined,
                      rows: [('Periode', _period(reportData))],
                    ),
                    const SizedBox(height: 10),
                    _InfoSection(
                      title: 'Klimatologi',
                      icon: Icons.cloud_outlined,
                      rows: [
                        (
                          'Data',
                          _text(
                            reportData['data_klimatologi'],
                            'Belum tersedia',
                          ),
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
                          _text(
                            reportData['pengamatan_visual'],
                            'Belum tersedia',
                          ),
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
                        (
                          'Sumber',
                          _text(reportData['sumber'], 'Belum tersedia'),
                        ),
                        (
                          'Waktu publikasi',
                          _text(
                            reportData['waktu_publikasi'],
                            'Belum tersedia',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _EstimatedZone(radius: gunung['radius_perkiraan_km']),
                    const SizedBox(height: 12),
                    const Text(
                      'Data ditampilkan sesuai respons API RANAH. Status dan rekomendasi '
                      'perlu merujuk sumber resmi. Zona perkiraan bukan batas KRB resmi. '
                      'RANAH bukan pengganti arahan PVMBG dan BPBD.',
                      style: TextStyle(
                        color: Color(0xFFE2EDF5),
                        fontSize: 12,
                        height: 1.45,
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

  String _text(dynamic value, String fallback) {
    if (value == null || value.toString().trim().isEmpty) return fallback;
    return value.toString().trim();
  }
}

class _ReportHeading extends StatelessWidget {
  const _ReportHeading();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xE8200B59), Color(0xE5101736)],
      ),
      borderRadius: BorderRadius.circular(9),
    ),
    child: const Row(
      children: [
        Icon(Icons.landscape_outlined, color: Colors.white, size: 38),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'INFORMASI RANAH',
                style: TextStyle(
                  color: Color(0xFF8BC8FF),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .8,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Aktivitas Gunung Api',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Laporan dan informasi yang tersedia',
                style: TextStyle(color: Color(0xFFD0C9E7), fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ReportMapPlaceholder extends StatelessWidget {
  const _ReportMapPlaceholder({
    required this.nama,
    required this.hasCoordinates,
  });
  final String nama;
  final bool hasCoordinates;

  @override
  Widget build(BuildContext context) => Container(
    height: 154,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: Colors.white.withValues(alpha: .26)),
      gradient: const LinearGradient(
        colors: [Color(0xFF21465B), Color(0xFF17384C)],
      ),
    ),
    child: Stack(
      children: [
        const Positioned.fill(
          child: CustomPaint(painter: _TerrainPlaceholderPainter()),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_on_rounded,
                color: Color(0xFFFFC46B),
                size: 34,
              ),
              Text(
                nama,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                hasCoordinates
                    ? 'Koordinat tersedia; peta belum terhubung'
                    : 'Peta lokasi belum tersedia',
                style: const TextStyle(color: Color(0xFFE0E9EF), fontSize: 11),
              ),
            ],
          ),
        ),
        const Positioned(
          left: 8,
          top: 8,
          child: _MapLabel(text: 'ILUSTRASI - BUKAN PETA AKTUAL'),
        ),
      ],
    ),
  );
}

class _TerrainPlaceholderPainter extends CustomPainter {
  const _TerrainPlaceholderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF76A18C).withValues(alpha: .18);
    for (var index = 0; index < 5; index++) {
      canvas.drawCircle(
        Offset(size.width * index / 4, size.height * .9),
        size.height * .43,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MapLabel extends StatelessWidget {
  const _MapLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xD9161725),
      borderRadius: BorderRadius.circular(5),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
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
          fontSize: 12,
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
            fontSize: 11,
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
              style: const TextStyle(color: Colors.white, fontSize: 11),
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
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          Text(
            row.$2,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
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
                    fontSize: 12,
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
