import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../data/volcanic_activity_data.dart';
import '../models/gunung_data.dart';
import '../services/gunung_repository.dart';
import '../services/ranah_api_client.dart';
import '../theme/ranah_theme.dart';
import '../widgets/ranah_full_width_title_background.dart';
import '../widgets/ranah_header.dart';
import '../widgets/volcano_interactive_map.dart';

class VolcanoReportPage extends StatefulWidget {
  const VolcanoReportPage({
    required this.gunungId,
    required this.onBack,
    this.namaGunung,
    this.repository,
    this.tilesEnabled = true,
    this.mapController,
    super.key,
  });

  final int gunungId;
  final VoidCallback onBack;
  final String? namaGunung;
  final GunungDataRepository? repository;
  final bool tilesEnabled;
  final MapController? mapController;

  @override
  State<VolcanoReportPage> createState() => _VolcanoReportPageState();
}

class _VolcanoReportPageState extends State<VolcanoReportPage> {
  bool _showKrb = true;
  bool _panelCollapsed = false;
  late final GunungDataRepository _repository;
  GunungDetailRecord? _detail;
  Object? _error;
  bool _loading = true;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? GunungRepository();
    _loadDetail();
  }

  @override
  void didUpdateWidget(covariant VolcanoReportPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gunungId != widget.gunungId) {
      _detail = null;
      _error = null;
      _panelCollapsed = false;
      _showKrb = true;
      _loadDetail();
    }
  }

  Future<void> _loadDetail() async {
    final generation = ++_loadGeneration;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await _repository.loadDetail(widget.gunungId);
      if (!mounted || generation != _loadGeneration) return;
      setState(() => _detail = detail);
    } catch (error) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() => _error = error);
    } finally {
      if (mounted && generation == _loadGeneration) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final mobile = constraints.maxWidth < 700;
      final panelWidth = mobile
          ? math.min(constraints.maxWidth - 16, constraints.maxWidth * .50)
          : 380.0;
      final panelInset = mobile ? 8.0 : 18.0;
      final availableHeight = math.max(
        0.0,
        constraints.maxHeight - panelInset * 2,
      );
      final mapAreaHeight = math.max(0.0, constraints.maxHeight - 124);
      final panelMaxHeight = math.min(
        availableHeight * (mobile ? .72 : .84),
        math.max(0.0, mapAreaHeight - 180),
      );
      final gunung = _detail?.gunung;
      return Column(
        children: [
          const _ReportTitleBanner(),
          const SizedBox(height: RanahSpacing.sm),
          _ReportBackBar(
            status: gunung?.statusAktivitas,
            onBack: widget.onBack,
          ),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (gunung != null)
                  Positioned.fill(
                    child: VolcanoInteractiveMap(
                      gunung: gunung,
                      showKrb: _showKrb,
                      tilesEnabled: widget.tilesEnabled,
                      mapController: widget.mapController,
                    ),
                  )
                else
                  const Positioned.fill(
                    child: ColoredBox(color: Color(0xFF102B43)),
                  ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: IgnorePointer(
                    child: _MapDisclosure(
                      text: _showKrb
                          ? 'KRB BIG jika tersedia - bukan panduan evakuasi'
                          : 'Peta interaktif - zona KRB disembunyikan',
                      warning: _showKrb,
                    ),
                  ),
                ),
                Positioned(
                  left: panelInset,
                  top: panelInset,
                  child: SizedBox(
                    width: panelWidth,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: panelMaxHeight),
                      child: _loading
                          ? const _ReportState(
                              icon: Icons.sync,
                              title: 'Memuat laporan gunung',
                              message: 'Mengambil data dari server RANAH...',
                              loading: true,
                            )
                          : _detail == null
                          ? _ReportState(
                              icon: _isNotFound(_error)
                                  ? Icons.search_off
                                  : Icons.cloud_off_outlined,
                              title: _isNotFound(_error)
                                  ? 'Data gunung tidak ditemukan'
                                  : 'Laporan belum dapat dimuat',
                              message:
                                  _error?.toString() ??
                                  'Data detail gunung belum tersedia.',
                              action: FilledButton.icon(
                                onPressed: _loadDetail,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Coba lagi'),
                              ),
                            )
                          : _ReportPanel(
                              detail: _detail!,
                              showKrb: _showKrb,
                              collapsed: _panelCollapsed,
                              maxContentHeight: math.max(
                                0.0,
                                panelMaxHeight - 58,
                              ),
                              onToggleCollapsed: () => setState(
                                () => _panelCollapsed = !_panelCollapsed,
                              ),
                              onToggleKrb: () =>
                                  setState(() => _showKrb = !_showKrb),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );

  bool _isNotFound(Object? error) =>
      error is RanahApiException && error.statusCode == 404;
}

class _ReportState extends StatelessWidget {
  const _ReportState({
    required this.icon,
    required this.title,
    required this.message,
    this.loading = false,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final bool loading;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Container(
    width: 380,
    padding: const EdgeInsets.all(RanahSpacing.lg),
    decoration: BoxDecoration(
      color: const Color(0xE9154770),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: const Color(0xFF4B91B4)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (loading)
          const CircularProgressIndicator()
        else
          Icon(icon, size: 30, color: Colors.white70),
        const SizedBox(height: RanahSpacing.sm),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: RanahSpacing.xs),
        Text(message, textAlign: TextAlign.center),
        if (action != null) ...[
          const SizedBox(height: RanahSpacing.md),
          action!,
        ],
      ],
    ),
  );
}

class _ReportTitleBanner extends StatelessWidget {
  const _ReportTitleBanner();

  @override
  Widget build(BuildContext context) => RanahFullWidthTitleBackground(
    color: const Color(0xFF17003E),
    child: Container(
      constraints: const BoxConstraints(minHeight: 76),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                  'SIAGA BENCANA',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: .9,
                    color: Color(0xFF91A8D0),
                  ),
                ),
                Text(
                  'Aktivitas Gunung Api',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                Text(
                  'Memantau aktivitas gunung api',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Color(0xFFC1C8D7)),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _ReportBackBar extends StatelessWidget {
  const _ReportBackBar({required this.status, required this.onBack});

  final String? status;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Container(
    height: 48,
    padding: const EdgeInsets.symmetric(horizontal: RanahSpacing.md),
    color: const Color(0xFF12304C),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        RanahBackButton(onPressed: onBack),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: Color(
                  activityLevelPresentation(_activityLevel(status)).color,
                ).withValues(alpha: .88),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                _display(status, 'Status aktivitas belum tersedia'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: _activityLevel(status) == null
                      ? Colors.white
                      : const Color(0xFF332308),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _ReportPanel extends StatelessWidget {
  const _ReportPanel({
    required this.detail,
    required this.showKrb,
    required this.collapsed,
    required this.maxContentHeight,
    required this.onToggleCollapsed,
    required this.onToggleKrb,
  });

  final GunungDetailRecord detail;
  final bool showKrb;
  final bool collapsed;
  final double maxContentHeight;
  final VoidCallback onToggleCollapsed;
  final VoidCallback onToggleKrb;

  @override
  Widget build(BuildContext context) {
    final gunung = detail.gunung;
    final report = detail.laporan.isEmpty ? null : detail.laporan.first;
    final photoUrl = _safeImageUrl(report?.foto);
    return Container(
      key: ValueKey('report-panel-${gunung.id}'),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xD9154770),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF4B91B4)),
        boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 5)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                key: ValueKey('report-panel-toggle-${gunung.id}'),
                tooltip: collapsed
                    ? 'Buka panel laporan'
                    : 'Ciutkan panel laporan',
                onPressed: onToggleCollapsed,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 32,
                  height: 36,
                ),
                icon: Icon(
                  collapsed ? Icons.expand_more : Icons.expand_less,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: RanahSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Laporan Gunung Api',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: Color(0xFFE3ECF5)),
                    ),
                    Text(
                      gunung.nama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: collapsed
                ? const SizedBox.shrink()
                : ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: maxContentHeight),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: RanahSpacing.sm),
                          AspectRatio(
                            aspectRatio: 1.78,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: photoUrl == null
                                  ? const _ReportPhotoPlaceholder()
                                  : Image.network(
                                      photoUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, error, _) {
                                        debugPrint(
                                          'Foto laporan gunung ${gunung.id} gagal dimuat: $error',
                                        );
                                        return const _ReportPhotoPlaceholder();
                                      },
                                    ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              top: RanahSpacing.xs,
                            ),
                            child: Text(
                              report == null
                                  ? 'Foto laporan tidak tersedia.'
                                  : photoUrl == null
                                  ? 'Foto laporan tidak tersedia dari sumber API.'
                                  : 'Foto dari laporan sumber.',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          const SizedBox(height: RanahSpacing.sm),
                          SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              onPressed: onToggleKrb,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: const Color(0xFF164D79),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                ),
                                alignment: Alignment.centerLeft,
                                side: const BorderSide(
                                  color: Color(0xFF7AB2D2),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              child: Text(
                                showKrb
                                    ? 'Sembunyikan Zona KRB'
                                    : 'Tampilkan Peta KRB',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                          if (showKrb)
                            const Padding(
                              padding: EdgeInsets.only(top: RanahSpacing.xs),
                              child: Text(
                                'Poligon hanya ditampilkan bila cocok dengan ID gunung dan berstatus terverifikasi. Data sumber dapat lama; bukan panduan evakuasi.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFFFD77D),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          const SizedBox(height: RanahSpacing.sm),
                          _ReportSection(
                            title: 'Lokasi Administratif dan Geografis',
                            body: _region(gunung),
                          ),
                          _ReportSection(
                            title: 'Koordinat',
                            body: _coordinates(gunung),
                          ),
                          if (report == null)
                            const _ReportSection(
                              title: 'Laporan Pengamatan',
                              body: 'Belum ada laporan pengamatan tersimpan untuk gunung ini.',
                            )
                          else ...[
                            _ReportSection(
                              title: 'Periode Pengamatan',
                              body: _period(report),
                            ),
                            _ReportSection(
                              title: 'Klimatologi',
                              body: _display(
                                report.dataKlimatologi,
                                'Belum tersedia pada laporan.',
                              ),
                            ),
                            _ReportSection(
                              title: 'Pengamatan Visual',
                              body: _display(
                                report.pengamatanVisual,
                                'Belum tersedia pada laporan.',
                              ),
                            ),
                            _ReportSection(
                              title: 'Rekomendasi',
                              body: _display(
                                report.rekomendasi,
                                'Belum tersedia pada laporan.',
                              ),
                            ),
                            _ReportSection(
                              title: 'Sumber dan Pembaruan',
                              body:
                                  'Sumber: ${_display(report.sumber, 'Belum tersedia')}\n'
                                  'Waktu publikasi sumber: ${_formatDateTime(report.waktuPublikasi)}\n'
                                  'Waktu pengambilan server: ${_formatDateTime(report.waktuPengambilan)}',
                            ),
                            if (_safeSourceUrl(report.urlSumber)
                                case final url?)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: RanahSpacing.sm,
                                ),
                                child: SelectableText(
                                  'URL sumber: ${_safeDisplayUrl(url)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFD8E6F2),
                                  ),
                                ),
                              ),
                          ],
                          const SizedBox(height: RanahSpacing.sm),
                          const Text(
                            'Status dan laporan berasal dari API RANAH. Peta dasar memerlukan internet. '
                            'Batas KRB bersumber dari layer BIG bila tersedia; data dapat lama dan bukan panduan evakuasi.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFFFD77D),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ReportPhotoPlaceholder extends StatelessWidget {
  const _ReportPhotoPlaceholder();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: Color(0xFF26384A),
    child: Center(
      child: Icon(Icons.photo_outlined, color: Color(0xFFB8C3CF), size: 32),
    ),
  );
}

class _ReportSection extends StatelessWidget {
  const _ReportSection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: RanahSpacing.sm),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: RanahSpacing.xs),
        Text(
          body,
          style: const TextStyle(
            fontSize: 12,
            height: 1.15,
            color: Color(0xFFF0F3F8),
          ),
        ),
      ],
    ),
  );
}

class _MapDisclosure extends StatelessWidget {
  const _MapDisclosure({required this.text, required this.warning});

  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: warning ? const Color(0xE9663D0B) : const Color(0xD9102B42),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(
        color: warning ? const Color(0xFFFFC04B) : Colors.white30,
      ),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: warning ? const Color(0xFFFFE6AC) : Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

int? _activityLevel(String? status) {
  final value = RegExp(
    r'^\s*Level\s+(IV|III|II|I)\b',
    caseSensitive: false,
  ).firstMatch(status ?? '')?.group(1)?.toUpperCase();
  return switch (value) {
    'I' => 1,
    'II' => 2,
    'III' => 3,
    'IV' => 4,
    _ => null,
  };
}

String _display(String? value, String fallback) {
  final text = value?.trim() ?? '';
  return text.isEmpty ? fallback : text;
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

String _coordinates(GunungRecord gunung) {
  final latitude = gunung.latitude;
  final longitude = gunung.longitude;
  if (latitude == null || longitude == null) return 'Koordinat belum tersedia.';
  if (gunung.statusValidasiKoordinat?.toLowerCase() != 'terverifikasi') {
    return 'Koordinat tersimpan tetapi belum terverifikasi.';
  }
  final source = _display(
    gunung.sumberKoordinat,
    'Sumber koordinat tidak tersedia',
  );
  return '$latitude, $longitude\nSumber: $source';
}

String _period(GunungReportRecord report) {
  if (report.periodeWaktu != null) return report.periodeWaktu!;
  final start = report.periodeMulai;
  final end = report.periodeSelesai;
  if (start == null && end == null) return 'Periode tidak tersedia.';
  return '${start ?? 'Tidak tersedia'} - ${end ?? 'Tidak tersedia'}';
}

String _formatDateTime(DateTime? value) {
  if (value == null) return 'belum tersedia';
  final date = value.toLocal();
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$day/$month/${date.year} $hour:$minute';
}

String? _safeImageUrl(String? value) {
  final uri = Uri.tryParse(value ?? '');
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty) {
    return null;
  }
  return uri.toString();
}

String? _safeSourceUrl(String? value) {
  final uri = Uri.tryParse(value ?? '');
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.host != 'magma.esdm.go.id' ||
      uri.userInfo.isNotEmpty) {
    return null;
  }
  return uri.toString();
}

String _safeDisplayUrl(String value) {
  final uri = Uri.parse(value);
  return uri.replace(query: null, fragment: null).toString();
}
