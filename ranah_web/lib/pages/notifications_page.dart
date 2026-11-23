import 'package:flutter/material.dart';
import 'package:ranah_accessibility/ranah_accessibility.dart';

import '../models/bmkg_notification.dart';
import '../services/notifications_repository.dart';
import '../services/browser_geolocation.dart';
import '../services/administrative_area_lookup.dart';
import '../theme/ranah_theme.dart';
import '../widgets/ranah_full_width_title_background.dart';
import '../widgets/ranah_header.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({
    required this.onBack,
    this.repository,
    this.forecastRepository,
    this.locationReader = readBrowserLocation,
    this.areaLookup = lookupBrowserAdministrativeArea,
    super.key,
  });

  final VoidCallback onBack;
  final BmkgNotificationRepository? repository;
  final BmkgForecastRepository? forecastRepository;
  final Future<BrowserLocation> Function() locationReader;
  final AdministrativeAreaLookup areaLookup;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final BmkgNotificationRepository _repository;
  BmkgForecastRepository? _forecastRepository;
  BmkgNotificationFeed? _feed;
  Object? _error;
  bool _loading = true;
  String _category = 'Semua';
  List<BmkgWeatherArea> _weatherAreas = const [];
  Object? _weatherAreaError;
  bool _weatherAreasLoading = false;
  BmkgWeatherArea? _selectedWeatherArea;
  BmkgWeatherForecast? _forecast;
  Object? _forecastError;
  bool _forecastLoading = false;
  bool _weatherLocationLoading = false;
  String? _weatherLocationError;
  int _feedRequestId = 0;
  int _forecastRequestId = 0;

  @override
  void initState() {
    super.initState();
    final repository = widget.repository ?? NotificationsRepository();
    _repository = repository;
    _forecastRepository = widget.forecastRepository;
    if (_forecastRepository == null && repository is BmkgForecastRepository) {
      _forecastRepository = repository as BmkgForecastRepository;
    }
    _load(page: 1);
    _loadWeatherAreas();
  }

  Future<void> _load({required int page}) async {
    final requestId = ++_feedRequestId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final feed = await _repository.load(page: page, kind: _kindForCategory());
      if (mounted && requestId == _feedRequestId) setState(() => _feed = feed);
    } catch (error) {
      if (mounted && requestId == _feedRequestId) {
        setState(() => _error = error);
      }
    } finally {
      if (mounted && requestId == _feedRequestId) {
        setState(() => _loading = false);
      }
    }
  }

  String? _kindForCategory() => switch (_category) {
    'Gempa' => 'kejadian',
    'Peringatan' => 'peringatan',
    _ => null,
  };

  void _selectCategory(String category) {
    if (_category == category) return;
    setState(() => _category = category);
    if (category != 'Cuaca') {
      _load(page: 1);
    } else if (!_weatherAreasLoading && _weatherAreas.isNotEmpty) {
      _resolveCurrentWeather();
    }
  }

  Future<void> _loadWeatherAreas() async {
    final repository = _forecastRepository;
    if (repository == null) return;
    setState(() {
      _weatherAreasLoading = true;
      _weatherAreaError = null;
    });
    try {
      final areas = await repository.loadWeatherAreas();
      if (!mounted) return;
      final selected = areas.where(
        (area) => area.adm4 == _selectedWeatherArea?.adm4,
      );
      setState(() {
        _weatherAreas = areas;
        _selectedWeatherArea = selected.isEmpty ? null : selected.first;
      });
      if (_category == 'Cuaca' && areas.isNotEmpty) _resolveCurrentWeather();
    } catch (error) {
      if (mounted) setState(() => _weatherAreaError = error);
    } finally {
      if (mounted) setState(() => _weatherAreasLoading = false);
    }
  }

  Future<void> _resolveCurrentWeather() async {
    if (_weatherLocationLoading) return;
    setState(() {
      _weatherLocationLoading = true;
      _weatherLocationError = null;
      _selectedWeatherArea = null;
      _forecast = null;
    });
    try {
      final fix = await widget.locationReader();
      if (!fix.isValid) {
        throw const FormatException('Koordinat lokasi tidak valid.');
      }
      final address = await widget.areaLookup(fix);
      if (!mounted) return;
      final matches = _weatherAreas
          .where(
            (area) => matchesWeatherArea(
              areaVillage: area.village,
              areaDistrict: area.district,
              areaCity: area.city,
              areaProvince: area.province,
              locationVillage: address?.village ?? address?.locality,
              locationDistrict: address?.district,
              locationCity: address?.regency,
              locationProvince: address?.province,
            ),
          )
          .toList();
      if (matches.length != 1) {
        setState(
          () => _weatherLocationError = 'Prakiraan untuk lokasi saat ini belum tersedia pada wilayah BMKG yang terverifikasi.',
        );
      } else {
        await _selectWeatherArea(matches.single);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _weatherLocationError =
              'Lokasi belum dapat dibaca. Izinkan lokasi lalu coba lagi.',
        );
      }
    } finally {
      if (mounted) setState(() => _weatherLocationLoading = false);
    }
  }

  Future<void> _selectWeatherArea(BmkgWeatherArea? area) async {
    setState(() {
      _selectedWeatherArea = area;
      _forecast = null;
      _forecastError = null;
    });
    if (area != null) await _loadWeatherForecast(area);
  }

  Future<void> _loadWeatherForecast(BmkgWeatherArea area) async {
    final repository = _forecastRepository;
    if (repository == null) return;
    final requestId = ++_forecastRequestId;
    setState(() {
      _forecastLoading = true;
      _forecastError = null;
    });
    try {
      final forecast = await repository.loadWeatherForecast(area.adm4);
      if (mounted &&
          requestId == _forecastRequestId &&
          _selectedWeatherArea?.adm4 == area.adm4) {
        setState(() => _forecast = forecast);
      }
    } catch (error) {
      if (mounted &&
          requestId == _forecastRequestId &&
          _selectedWeatherArea?.adm4 == area.adm4) {
        setState(() => _forecastError = error);
      }
    } finally {
      if (mounted && requestId == _forecastRequestId) {
        setState(() => _forecastLoading = false);
      }
    }
  }

  String _emptyMessage() {
    if (_category == 'Peringatan') {
      if (_error != null) {
        return 'Pemeriksaan notifikasi gagal. Status peringatan terbaru belum dapat dipastikan.';
      }
      final state = _feed?.sourceStatuses['peringatan_dini_cuaca'];
      if (state?.status == 'berhasil') {
        return 'Belum ada peringatan dini cuaca aktif untuk wilayah yang dipilih berdasarkan data terakhir yang berhasil diperiksa.';
      }
      if (state?.status == 'gagal' || state?.status == 'sebagian_gagal') {
        return 'Pemeriksaan peringatan BMKG gagal. Data terakhir yang berhasil diperiksa tetap dipertahankan.';
      }
      return 'Belum ada informasi peringatan yang dapat dipastikan karena feed belum pernah berhasil diperiksa.';
    }
    return 'Tidak ada informasi aktif yang relevan untuk Sumatera Barat saat ini.';
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth > RanahLayout.maxContentWidth
          ? RanahLayout.maxContentWidth
          : constraints.maxWidth;
      final horizontal = width < 600 ? 20.0 : 36.0;
      final feed = _feed;
      final visibleItems = (feed?.items ?? const <BmkgNotification>[])
          .where(
            (item) => switch (_category) {
              'Gempa' => item.kind == 'kejadian',
              'Peringatan' => item.kind == 'peringatan',
              'Cuaca' => false,
              _ => true,
            },
          )
          .toList(growable: false);
      return RanahPageScrollLayout(
        maxContentWidth: width,
        title: _NotificationsBanner(
          maxContentWidth: width,
          onRefresh: _category == 'Cuaca'
              ? (_weatherLocationLoading ? null : _resolveCurrentWeather)
              : (_loading ? null : () => _load(page: feed?.currentPage ?? 1)),
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontal,
                RanahSpacing.md,
                horizontal,
                0,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: RanahBackButton(onPressed: widget.onBack),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontal,
                RanahSpacing.md,
                horizontal,
                0,
              ),
              child: const Text(
                'Notifikasi BMKG · Sumatera Barat',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (feed != null)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontal,
                  RanahSpacing.md,
                  horizontal,
                  0,
                ),
                child: NotificationOverview(
                  earthquakes: feed.items
                      .where((item) => item.kind == 'kejadian')
                      .length,
                  warnings: feed.items.where((item) => item.isWarning).length,
                  updatedLabel: 'Data BMKG yang tampil pada halaman ini',
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontal,
                RanahSpacing.md,
                horizontal,
                0,
              ),
              child: Material(
                color: Colors.transparent,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final category in const [
                      'Semua',
                      'Gempa',
                      'Cuaca',
                      'Peringatan',
                    ])
                      ChoiceChip(
                        label: Text(category),
                        selected: _category == category,
                        selectedColor: const Color(0xFF2A7398),
                        backgroundColor: const Color(0xFF174664),
                        labelStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                        checkmarkColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF5E91AA)),
                        onSelected: (_) => _selectCategory(category),
                      ),
                  ],
                ),
              ),
            ),
            if (feed != null)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontal,
                  RanahSpacing.sm,
                  horizontal,
                  0,
                ),
                child: _SourceStatusPanel(statuses: feed.sourceStatuses),
              ),
            if (_loading && feed == null && _category != 'Cuaca')
              const Padding(
                padding: EdgeInsets.all(RanahSpacing.xxxl),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null && feed == null && _category != 'Cuaca')
              Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontal,
                  RanahSpacing.md,
                  horizontal,
                  0,
                ),
                child: _FeedError(
                  error: _error!,
                  onRetry: () => _load(page: 1),
                ),
              )
            else ...[
              if (_error != null && _category != 'Cuaca')
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontal,
                    RanahSpacing.sm,
                    horizontal,
                    0,
                  ),
                  child: const _FeedMessage(
                    text: 'Pembaruan gagal. Menampilkan hasil permintaan terakhir yang berhasil.',
                    color: Color(0xFFFFE0A6),
                  ),
                ),
              if (_loading && _category != 'Cuaca')
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: LinearProgressIndicator(),
                ),
              if (_category == 'Cuaca')
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontal,
                    RanahSpacing.md,
                    horizontal,
                    0,
                  ),
                  child: _WeatherForecastPanel(
                    areas: _weatherAreas,
                    selectedArea: _selectedWeatherArea,
                    areaLoading: _weatherAreasLoading,
                    areaError: _weatherAreaError,
                    forecast: _forecast,
                    forecastLoading: _forecastLoading,
                    forecastError: _forecastError,
                    locationLoading: _weatherLocationLoading,
                    locationError: _weatherLocationError,
                    onRetryLocation: _resolveCurrentWeather,
                    onRetryAreas: _loadWeatherAreas,
                    onRetryForecast: _selectedWeatherArea == null
                        ? null
                        : () => _loadWeatherForecast(_selectedWeatherArea!),
                  ),
                )
              else if (feed == null || visibleItems.isEmpty)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontal,
                    RanahSpacing.md,
                    horizontal,
                    0,
                  ),
                  child: _EmptyFeed(message: _emptyMessage()),
                )
              else ...[
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontal,
                    0,
                    horizontal,
                    RanahSpacing.sm,
                  ),
                  child: _FeedMessage(
                    text:
                        '${feed.total} informasi · halaman ${feed.currentPage} dari ${feed.lastPage}',
                    color: const Color(0xFFD7E0EA),
                  ),
                ),
                for (var index = 0; index < visibleItems.length; index++)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontal,
                      0,
                      horizontal,
                      index == visibleItems.length - 1 ? 0 : RanahSpacing.lg,
                    ),
                    child: _NotificationCard(
                      notification: visibleItems[index],
                      index: index,
                    ),
                  ),
                if (feed.lastPage > 1)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontal,
                      RanahSpacing.lg,
                      horizontal,
                      RanahSpacing.lg,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton(
                          onPressed: _loading || feed.currentPage <= 1
                              ? null
                              : () => _load(page: feed.currentPage - 1),
                          child: const Text('Sebelumnya'),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            '${feed.currentPage}/${feed.lastPage}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        OutlinedButton(
                          onPressed:
                              _loading || feed.currentPage >= feed.lastPage
                              ? null
                              : () => _load(page: feed.currentPage + 1),
                          child: const Text('Berikutnya'),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ],
        ),
      );
    },
  );
}

class _NotificationsBanner extends StatelessWidget {
  const _NotificationsBanner({
    required this.maxContentWidth,
    required this.onRefresh,
  });

  final double maxContentWidth;
  final VoidCallback? onRefresh;

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
      child: Row(
        children: [
          const Icon(
            Icons.notifications_none_rounded,
            size: RanahPageHeaderStyle.iconSize,
          ),
          const SizedBox(width: RanahPageHeaderStyle.iconGap),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SIAGA BENCANA',
                  maxLines: 1,
                  style: RanahPageHeaderStyle.kicker,
                ),
                Text(
                  'Notifikasi',
                  maxLines: 1,
                  style: RanahPageHeaderStyle.title,
                ),
                Text(
                  'Peringatan dan informasi terkini',
                  maxLines: 1,
                  style: RanahPageHeaderStyle.subtitle,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRefresh,
            tooltip: 'Muat ulang notifikasi',
            constraints: const BoxConstraints.tightFor(width: 44, height: 48),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.refresh, size: 19),
          ),
        ],
      ),
    ),
  );
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.index});

  final BmkgNotification notification;
  final int index;

  @override
  Widget build(BuildContext context) {
    final danger = notification.isWarning;
    final accent = danger ? RanahColors.eruption : const Color(0xFF176D9A);
    final itemTime = notification.eventAt ?? notification.publishedAt;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(RanahRadii.sm),
      child: Container(
        key: ValueKey('notification-card-$index'),
        constraints: const BoxConstraints(minHeight: 84),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F7FC),
          borderRadius: BorderRadius.circular(RanahRadii.md),
          border: Border.all(color: const Color(0xFFA6C8DC)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: danger
                    ? const Color(0xFFFFECEC)
                    : const Color(0xFFDDEFFA),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                danger
                    ? Icons.warning_amber_rounded
                    : notification.category.toLowerCase().contains('gempa')
                    ? Icons.vibration_rounded
                    : Icons.info_outline_rounded,
                color: accent,
                size: 24,
              ),
            ),
            const SizedBox(width: RanahSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Wrap(
                    spacing: RanahSpacing.md,
                    runSpacing: RanahSpacing.xs,
                    children: [
                      Text(
                        danger
                            ? 'PERINGATAN AKTIF'
                            : notification.category.toUpperCase(),
                        style: TextStyle(
                          color: accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        itemTime == null
                            ? 'Waktu sumber tidak tersedia'
                            : '${notification.isWarning
                                  ? 'Berlaku'
                                  : notification.eventAt == null
                                  ? 'Terbit'
                                  : 'Kejadian'} ${_formatTime(itemTime)}',
                        style: const TextStyle(
                          color: RanahColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: RanahSpacing.xs),
                  Text(
                    notification.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF1D2636),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: RanahSpacing.xs),
                  Text(
                    notification.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: RanahColors.muted,
                      fontSize: 16,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: RanahSpacing.xs),
                  Text(
                    notification.region ?? 'Wilayah dari sumber tidak tersedia',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: RanahColors.muted,
                      fontSize: 12,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: RanahSpacing.xs),
                  Text(
                    notification.source ?? 'Sumber tidak tersedia',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: RanahColors.muted,
                      fontSize: 12,
                      height: 1.1,
                    ),
                  ),
                  if (notification.retrievedAt != null) ...[
                    const SizedBox(height: RanahSpacing.xs),
                    Text(
                      'Data diambil ${_formatTime(notification.retrievedAt!)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: RanahColors.muted,
                        fontSize: 11,
                        height: 1.1,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceStatusPanel extends StatelessWidget {
  const _SourceStatusPanel({required this.statuses});

  final Map<String, BmkgSyncState> statuses;

  @override
  Widget build(BuildContext context) {
    const sources = <String, String>{
      'gempa': 'Gempa',
      'prakiraan_cuaca': 'Prakiraan cuaca',
      'peringatan_dini_cuaca': 'Peringatan dini',
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF102B43),
        borderRadius: BorderRadius.circular(RanahRadii.sm),
        border: Border.all(color: const Color(0xFF45627B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pemeriksaan sumber BMKG',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          for (final entry in sources.entries)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${entry.value}: ${_statusSummary(statuses[entry.key])}',
                style: const TextStyle(
                  color: Color(0xFFD7E0EA),
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String _statusSummary(BmkgSyncState? state) {
  if (state == null || state.status == 'belum_diperiksa') {
    return 'belum pernah diperiksa oleh server.';
  }
  if (state.status == 'wilayah_belum_dikonfigurasi') {
    return 'belum tersedia karena kode ADM4 terverifikasi belum dikonfigurasi.';
  }
  final checked = state.lastAttemptAt == null
      ? 'waktu pemeriksaan belum tersedia'
      : 'diperiksa ${_formatTime(state.lastAttemptAt!)}';
  final lastSuccess = state.lastSuccessAt == null
      ? 'belum ada pemeriksaan yang berhasil'
      : 'terakhir berhasil ${_formatTime(state.lastSuccessAt!)}';
  final result = switch (state.status) {
    'berhasil' => 'berhasil; $lastSuccess',
    'memeriksa' => 'sedang diperiksa; $lastSuccess',
    'sebagian_gagal' => 'sebagian wilayah gagal; $lastSuccess',
    'gagal' => 'gagal dihubungi/diproses; $lastSuccess',
    _ => 'status belum diketahui; $lastSuccess',
  };
  return '$checked, $result.';
}

class _WeatherForecastPanel extends StatelessWidget {
  const _WeatherForecastPanel({
    required this.areas,
    required this.selectedArea,
    required this.areaLoading,
    required this.areaError,
    required this.forecast,
    required this.forecastLoading,
    required this.forecastError,
    required this.locationLoading,
    required this.locationError,
    required this.onRetryLocation,
    required this.onRetryAreas,
    required this.onRetryForecast,
  });

  final List<BmkgWeatherArea> areas;
  final BmkgWeatherArea? selectedArea;
  final bool areaLoading;
  final Object? areaError;
  final BmkgWeatherForecast? forecast;
  final bool forecastLoading;
  final Object? forecastError;
  final bool locationLoading;
  final String? locationError;
  final VoidCallback onRetryLocation;
  final VoidCallback onRetryAreas;
  final VoidCallback? onRetryForecast;

  @override
  Widget build(BuildContext context) {
    final forecastData = forecast;
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF102B43),
          borderRadius: BorderRadius.circular(RanahRadii.md),
          border: Border.all(color: const Color(0xFF45627B)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              selectedArea == null
                  ? 'Prakiraan Cuaca BMKG'
                  : 'Prakiraan Cuaca — ${selectedArea!.village}, ${selectedArea!.district}, ${selectedArea!.city}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Prakiraan BMKG untuk lokasi Anda, bukan pengamatan cuaca langsung.',
              style: TextStyle(color: Color(0xFFD7E0EA), fontSize: 12),
            ),
            const SizedBox(height: 12),
            if (areaLoading || locationLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: LinearProgressIndicator(),
              )
            else if (areaError != null)
              _InlineRetry(
                message: 'Daftar wilayah prakiraan belum dapat dimuat.',
                onPressed: onRetryAreas,
              )
            else if (areas.isEmpty)
              const _FeedMessage(
                text: 'Prakiraan belum tersedia. Server belum memiliki wilayah BMKG terverifikasi.',
                color: Color(0xFFFFE0A6),
              )
            else if (locationError != null)
              _InlineRetry(message: locationError!, onPressed: onRetryLocation)
            else if (selectedArea == null)
              const _FeedMessage(
                text: 'Mencari prakiraan untuk lokasi Anda…',
                color: Color(0xFFD7E0EA),
              ),
            if (selectedArea != null) ...[
              const SizedBox(height: 12),
              if (forecastLoading)
                const Center(child: CircularProgressIndicator())
              else if (forecastError != null)
                _InlineRetry(
                  message: 'Prakiraan belum dapat dimuat dari cache server.',
                  onPressed: onRetryForecast,
                )
              else if (forecastData == null)
                const _FeedMessage(
                  text: 'Prakiraan belum tersedia. Data akan tampil setelah sinkronisasi server berhasil.',
                  color: Color(0xFFD7E0EA),
                )
              else if (forecastData.status == 'belum_tersedia')
                const _FeedMessage(
                  text: 'Belum ada prakiraan tersimpan untuk wilayah ini.',
                  color: Color(0xFFD7E0EA),
                )
              else ...[
                if (forecastData.isStale || forecastData.status == 'data_lama')
                  const _FeedMessage(
                    text: 'Data prakiraan terakhir sudah lama. Periksa waktu pembaruan sebelum menggunakannya.',
                    color: Color(0xFFFFE0A6),
                  ),
                if (forecastData.intervals.isEmpty)
                  const _FeedMessage(
                    text: 'Tidak ada waktu prakiraan mendatang pada data tersimpan.',
                    color: Color(0xFFD7E0EA),
                  )
                else ...[
                  for (final interval in forecastData.intervals.take(8))
                    _WeatherIntervalCard(interval: interval),
                  if (forecastData.analysisAt != null)
                    Text(
                      'Data dibuat ${_formatTime(forecastData.analysisAt!)} · Sumber: BMKG',
                      style: const TextStyle(
                        color: Color(0xFFD7E0EA),
                        fontSize: 11,
                      ),
                    ),
                ],
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _WeatherIntervalCard extends StatelessWidget {
  const _WeatherIntervalCard({required this.interval});

  final BmkgWeatherInterval interval;

  @override
  Widget build(BuildContext context) {
    final facts = <String>[];
    if (interval.temperature != null) {
      facts.add('${interval.temperature!.round()} °C');
    }
    if (interval.humidity != null) {
      facts.add('Kelembapan ${interval.humidity}%');
    }
    if (interval.windSpeed != null) {
      facts.add('Angin ${interval.windSpeed} km/jam');
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF174A7D),
        borderRadius: BorderRadius.circular(RanahRadii.sm),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_outlined, color: Color(0xFFBBD7E7)),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatTime(interval.localTime),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  interval.condition,
                  style: const TextStyle(color: Color(0xFFE0E8F1)),
                ),
                if (facts.isNotEmpty)
                  Text(
                    facts.join(' · '),
                    style: const TextStyle(
                      color: Color(0xFFD7E0EA),
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

class _InlineRetry extends StatelessWidget {
  const _InlineRetry({required this.message, required this.onPressed});

  final String message;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(message, style: const TextStyle(color: Color(0xFFFFE0A6))),
      ),
      TextButton(onPressed: onPressed, child: const Text('Coba lagi')),
    ],
  );
}

class _FeedMessage extends StatelessWidget {
  const _FeedMessage({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: TextStyle(color: color, fontSize: 12, height: 1.35));
}

class _FeedError extends StatelessWidget {
  const _FeedError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFF542B3A),
      borderRadius: BorderRadius.circular(RanahRadii.sm),
      border: Border.all(color: const Color(0xFFFF9B9B)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notifikasi BMKG belum dapat dimuat.',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: RanahSpacing.sm),
        Text('$error', style: const TextStyle(color: Colors.white)),
        const SizedBox(height: RanahSpacing.md),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Coba lagi'),
        ),
      ],
    ),
  );
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed({
    this.message =
        'Tidak ada informasi aktif yang relevan untuk Sumatera Barat saat ini.',
  });

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(RanahRadii.sm),
    ),
    child: Column(
      children: [
        Icon(Icons.notifications_none, size: 34, color: RanahColors.muted),
        SizedBox(height: RanahSpacing.sm),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: RanahColors.ink, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

String _formatTime(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/${local.year} $hour:$minute';
}
