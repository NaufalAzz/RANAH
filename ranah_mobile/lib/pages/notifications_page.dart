import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/notification_item.dart';
import '../models/weather_forecast.dart';
import '../services/notifications_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/app_card_surface.dart';
import '../widgets/app_page_banner.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({this.repository, super.key});

  final NotificationsRepository? repository;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final NotificationsRepository _repository;
  late Future<NotificationFeedSnapshot> _feed;
  String _category = 'Semua';
  late Future<List<WeatherArea>> _weatherAreas;
  Object? _weatherAreaError;
  WeatherArea? _selectedWeatherArea;
  WeatherForecast? _forecast;
  Object? _forecastError;
  bool _forecastLoading = false;
  int _forecastRequest = 0;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? NotificationsRepository();
    _feed = _repository.load();
    _weatherAreas = _loadWeatherAreas();
  }

  Future<void> _reload() async {
    setState(() => _feed = _repository.load());
    await _feed;
    if (_category == 'Cuaca' && _selectedWeatherArea != null) {
      await _loadForecast(_selectedWeatherArea!);
    }
  }

  Future<void> _loadForecast(WeatherArea area) async {
    final request = ++_forecastRequest;
    setState(() {
      _forecastLoading = true;
      _forecastError = null;
      _forecast = null;
    });
    try {
      final result = await _repository.loadWeatherForecast(area.adm4);
      if (mounted &&
          request == _forecastRequest &&
          _selectedWeatherArea?.adm4 == area.adm4) {
        setState(() => _forecast = result);
      }
    } catch (error) {
      if (mounted &&
          request == _forecastRequest &&
          _selectedWeatherArea?.adm4 == area.adm4) {
        setState(() => _forecastError = error);
      }
    } finally {
      if (mounted && request == _forecastRequest) {
        setState(() => _forecastLoading = false);
      }
    }
  }

  void _selectCategory(String category) {
    setState(() => _category = category);
    if (category != 'Cuaca') _reloadNotificationsOnly();
  }

  void _reloadNotificationsOnly() {
    setState(() => _feed = _repository.load());
  }

  Future<void> _selectWeatherArea(WeatherArea? area) async {
    setState(() {
      _selectedWeatherArea = area;
      _forecast = null;
      _forecastError = null;
    });
    if (area != null) await _loadForecast(area);
  }

  Future<List<WeatherArea>> _loadWeatherAreas() async {
    try {
      return await _repository.loadWeatherAreas();
    } catch (error) {
      _weatherAreaError = error;
      return const [];
    }
  }

  void _retryWeatherAreas() {
    setState(() {
      _weatherAreaError = null;
      _selectedWeatherArea = null;
      _forecast = null;
      _weatherAreas = _loadWeatherAreas();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppBackground.decoration,
      child: Stack(
        children: [
          const Positioned(top: 112, right: -76, child: _BackgroundRings()),
          FutureBuilder<NotificationFeedSnapshot>(
            future: _feed,
            builder: (context, snapshot) {
              final result = snapshot.data;
              final allItems = result?.items ?? const <NotificationItem>[];
              const categories = ['Semua', 'Gempa', 'Cuaca', 'Peringatan'];
              final items = _category == 'Semua'
                  ? allItems
                  : allItems
                        .where(
                          (item) => switch (_category) {
                            'Gempa' => item.kind == NotificationKind.earthquake,
                            'Peringatan' =>
                              item.kind == NotificationKind.latestNews &&
                                  item.status == 'aktif',
                            _ => false,
                          },
                        )
                        .toList();
              return ListView(
                padding: const EdgeInsets.only(top: 18, bottom: 28),
                children: [
                  const _NotificationBanner(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 25, 18, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Notifikasi Sumatera Barat',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Muat ulang notifikasi',
                              onPressed:
                                  snapshot.connectionState ==
                                      ConnectionState.waiting
                                  ? null
                                  : _reload,
                              icon: const Icon(
                                Icons.refresh,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        if (result?.isFromCache == true)
                          const _StatusMessage(
                            text: 'Menampilkan cache lokal. Informasi mungkin tidak terbaru.',
                            warning: true,
                          )
                        else if (result?.lastSyncedAt != null)
                          _StatusMessage(
                            text:
                                'Terakhir diperiksa aplikasi ${_formatDateTime(result!.lastSyncedAt!)} · Waktu pengambilan sumber ditampilkan per item.',
                          ),
                        if (result != null)
                          _StatusMessage(
                            text: result.sourceUpdatedAt == null
                                ? 'Sinkronisasi sumber BMKG belum tercatat oleh server.'
                                : 'Sinkronisasi sumber BMKG terakhir ${_formatDateTime(result.sourceUpdatedAt!)}.',
                            warning: result.sourceUpdatedAt == null,
                          ),
                        if (snapshot.connectionState ==
                                ConnectionState.waiting &&
                            result == null)
                          const Padding(
                            padding: EdgeInsets.all(28),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (result?.error != null && result!.items.isEmpty)
                          _ErrorState(
                            message: result.error.toString(),
                            onRetry: _reload,
                          )
                        else if (result != null) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final category in categories)
                                ChoiceChip(
                                  label: Text(category),
                                  selected: _category == category,
                                  onSelected: (_) => _selectCategory(category),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ] else
                          const SizedBox(height: 12),
                        if (_category == 'Cuaca') ...[
                          _WeatherForecastSection(
                            areas: _weatherAreas,
                            selectedArea: _selectedWeatherArea,
                            areasError: _weatherAreaError,
                            forecast: _forecast,
                            loading: _forecastLoading,
                            error: _forecastError,
                            onAreaChanged: _selectWeatherArea,
                            onRetryAreas: _retryWeatherAreas,
                            onRetryForecast: _selectedWeatherArea == null
                                ? null
                                : () => _loadForecast(_selectedWeatherArea!),
                          ),
                        ],
                        if (_category != 'Cuaca' &&
                            snapshot.connectionState !=
                                ConnectionState.waiting &&
                            result != null &&
                            items.isEmpty &&
                            result.error == null)
                          const _EmptyNotifications(),
                        for (var index = 0; index < items.length; index++) ...[
                          _NotificationCard(item: items[index]),
                          if (index < items.length - 1)
                            const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NotificationBanner extends StatelessWidget {
  const _NotificationBanner();

  @override
  Widget build(BuildContext context) => const AppPageBanner(
    icon: Icons.notifications_none_rounded,
    eyebrow: 'INFORMASI RANAH',
    title: 'Notifikasi',
    subtitle: 'Gempa terbaru dan peringatan cuaca aktif dari BMKG',
    minHeight: 88,
    padding: EdgeInsets.symmetric(horizontal: 34, vertical: 14),
    iconSize: 38,
    iconGap: 19,
    eyebrowStyle: TextStyle(
      color: AppColors.bannerEyebrow,
      fontSize: 14,
      height: 1.15,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.8,
    ),
    subtitleStyle: TextStyle(
      color: Color(0xFFC8C0D5),
      fontSize: 14,
      height: 1.15,
    ),
  );
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({required this.text, this.warning = false});
  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: TextStyle(
        color: warning ? const Color(0xFFFFD788) : const Color(0xFFD5E2ED),
        fontSize: 12,
      ),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
    ),
    child: Column(
      children: [
        const Icon(
          Icons.cloud_off_outlined,
          color: AppColors.primary,
          size: 32,
        ),
        const SizedBox(height: 8),
        const Text(
          'Notifikasi belum dapat dimuat dari server.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF68717E), fontSize: 12),
        ),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Coba lagi'),
        ),
      ],
    ),
  );
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
    ),
    child: const Text(
      'Belum ada notifikasi dari sumber yang terhubung.',
      textAlign: TextAlign.center,
      style: TextStyle(color: Color(0xFF68717E), fontSize: 14),
    ),
  );
}

class _WeatherForecastSection extends StatelessWidget {
  const _WeatherForecastSection({
    required this.areas,
    required this.selectedArea,
    required this.areasError,
    required this.forecast,
    required this.loading,
    required this.error,
    required this.onAreaChanged,
    required this.onRetryAreas,
    required this.onRetryForecast,
  });

  final Future<List<WeatherArea>> areas;
  final WeatherArea? selectedArea;
  final Object? areasError;
  final WeatherForecast? forecast;
  final bool loading;
  final Object? error;
  final ValueChanged<WeatherArea?> onAreaChanged;
  final VoidCallback onRetryAreas;
  final VoidCallback? onRetryForecast;

  @override
  Widget build(BuildContext context) => FutureBuilder<List<WeatherArea>>(
    future: areas,
    builder: (context, snapshot) {
      final available = snapshot.data ?? const <WeatherArea>[];
      return AppCardSurface(
        variant: AppCardVariant.notification,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Prakiraan Cuaca BMKG',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pilih kelurahan dari daftar ADM4 Sumatera Barat yang dikonfigurasi. Prakiraan bukan pengamatan cuaca aktual.',
              style: TextStyle(color: Color(0xFF68717E), fontSize: 12),
            ),
            const SizedBox(height: 12),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else if (areasError != null)
              _WeatherError(
                message: 'Daftar wilayah belum dapat dimuat: $areasError',
                onRetry: onRetryAreas,
              )
            else if (available.isEmpty)
              const Text(
                'Belum ada wilayah prakiraan Sumatera Barat yang dikonfigurasi di server.',
              )
            else
              DropdownButtonFormField<String>(
                initialValue: selectedArea?.adm4,
                decoration: const InputDecoration(
                  labelText: 'Wilayah prakiraan',
                ),
                items: [
                  for (final area in available)
                    DropdownMenuItem(
                      value: area.adm4,
                      child: Text(area.label, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (value) {
                  final matches = available.where((area) => area.adm4 == value);
                  onAreaChanged(matches.isEmpty ? null : matches.first);
                },
              ),
            if (selectedArea != null) ...[
              const SizedBox(height: 12),
              Text(
                'Prakiraan Cuaca — ${selectedArea!.village}, ${selectedArea!.district}, ${selectedArea!.city}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              if (loading)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (error != null)
                _WeatherError(
                  message: 'Prakiraan belum dapat dimuat: $error',
                  onRetry: onRetryForecast,
                ),
              if (!loading && error == null && forecast != null) ...[
                if (forecast!.isStale || forecast!.status == 'data_lama')
                  const Text(
                    'Data prakiraan terakhir sudah lama; periksa waktu pembuatan sebelum digunakan.',
                    style: TextStyle(color: Color(0xFF9A5E00)),
                  ),
                if (forecast!.status == 'belum_tersedia')
                  const Text(
                    'Prakiraan belum tersedia dari sinkronisasi server.',
                  ),
                for (final interval in forecast!.intervals.take(8))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(interval.condition),
                    subtitle: Text(
                      '${_formatDateTime(interval.localTime)}${interval.temperature == null ? '' : ' · ${interval.temperature!.round()}°C'}${interval.humidity == null ? '' : ' · RH ${interval.humidity}%'}${interval.windSpeed == null ? '' : ' · Angin ${interval.windSpeed!.toStringAsFixed(1)} km/jam'}',
                    ),
                  ),
                if (forecast!.intervals.isEmpty &&
                    forecast!.status != 'belum_tersedia')
                  const Text(
                    'Tidak ada interval prakiraan mendatang pada data tersimpan.',
                  ),
                if (forecast!.analysisAt != null)
                  Text(
                    'Data dibuat ${_formatDateTime(forecast!.analysisAt!)} · Sumber: BMKG',
                    style: const TextStyle(
                      color: Color(0xFF68717E),
                      fontSize: 12,
                    ),
                  ),
                if (forecast!.retrievedAt != null)
                  Text(
                    'Diambil server ${_formatDateTime(forecast!.retrievedAt!)}',
                    style: const TextStyle(
                      color: Color(0xFF68717E),
                      fontSize: 12,
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

class _WeatherError extends StatelessWidget {
  const _WeatherError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(message, style: const TextStyle(color: Color(0xFF9A5E00))),
      TextButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh),
        label: const Text('Coba lagi'),
      ),
    ],
  );
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item});
  final NotificationItem item;

  @override
  Widget build(BuildContext context) => AppCardSurface(
    variant: AppCardVariant.notification,
    padding: const EdgeInsets.all(AppSpacing.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: AppSizes.minimumTapTarget,
          height: AppSizes.minimumTapTarget,
          decoration: BoxDecoration(
            color: item.accent.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(AppRadii.card),
          ),
          child: Icon(item.icon, color: item.accent, size: 25),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      (item.category ?? item.kindLabel).toUpperCase(),
                      style: TextStyle(
                        color: item.accent,
                        fontSize: 13,
                        letterSpacing: 0.35,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (item.status != null)
                    Text(
                      _statusLabel(item.status!),
                      style: TextStyle(
                        color: item.status == 'aktif'
                            ? item.accent
                            : const Color(0xFF68717E),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                item.title,
                style: const TextStyle(
                  color: Color(0xFF202733),
                  fontSize: 18,
                  height: 1.25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                item.summary,
                style: const TextStyle(
                  color: Color(0xFF68717E),
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              if (item.region != null)
                _MetadataLine(label: 'Wilayah', value: item.region!),
              if (item.eventAt != null)
                _MetadataLine(
                  label: 'Kejadian/mulai',
                  value: _formatDateTime(item.eventAt!),
                ),
              if (item.publishedAt != null)
                _MetadataLine(
                  label: 'Publikasi',
                  value: _formatDateTime(item.publishedAt!),
                ),
              if (item.expiresAt != null)
                _MetadataLine(
                  label: 'Berakhir',
                  value: _formatDateTime(item.expiresAt!),
                ),
              if (item.retrievedAt != null)
                _MetadataLine(
                  label: 'Diambil RANAH',
                  value: _formatDateTime(item.retrievedAt!),
                ),
              if (item.importance != null)
                _MetadataLine(label: 'Tingkat sumber', value: item.importance!),
              _MetadataLine(
                label: 'Sumber',
                value: item.source ?? 'Tidak tersedia',
              ),
              if (item.sourceUrl != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () async {
                      final uri = Uri.parse(item.sourceUrl!);
                      final opened = await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                      if (!opened && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tautan sumber tidak dapat dibuka.'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Buka sumber asli'),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _MetadataLine extends StatelessWidget {
  const _MetadataLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text(
      '$label: $value',
      style: const TextStyle(color: Color(0xFF68717E), fontSize: 12),
    ),
  );
}

class _BackgroundRings extends StatelessWidget {
  const _BackgroundRings();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 190,
    height: 190,
    child: DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.035),
          width: 20,
        ),
      ),
    ),
  );
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} '
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

String _statusLabel(String status) => switch (status) {
  'aktif' => 'AKTIF',
  'kedaluwarsa' => 'KEDALUWARSA',
  'sudah_diperbarui' => 'SUDAH DIPERBARUI',
  _ => status.toUpperCase(),
};
