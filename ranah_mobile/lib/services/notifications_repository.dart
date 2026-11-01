import 'package:flutter/material.dart';

import '../models/notification_item.dart';
import '../models/weather_forecast.dart';
import 'api_service.dart';
import 'gunung_local_store.dart';
import 'notification_api.dart';
import 'notification_cache_store.dart';

class NotificationFeedSnapshot {
  const NotificationFeedSnapshot({
    required this.items,
    required this.isFromCache,
    this.lastSyncedAt,
    this.sourceUpdatedAt,
    this.error,
  });

  final List<NotificationItem> items;
  final bool isFromCache;
  final DateTime? lastSyncedAt;
  final DateTime? sourceUpdatedAt;
  final Object? error;
}

class NotificationsRepository {
  NotificationsRepository({
    NotificationApi? api,
    WeatherForecastApi? weatherApi,
    NotificationCacheStore? store,
  }) : _api = api ?? ApiService(),
       _weatherApi =
           weatherApi ??
           (api is WeatherForecastApi
               ? api as WeatherForecastApi
               : ApiService()),
       _store = store ?? GunungLocalStore.instance;

  final NotificationApi _api;
  final WeatherForecastApi _weatherApi;
  final NotificationCacheStore _store;

  Future<List<WeatherArea>> loadWeatherAreas() async {
    final areas = <WeatherArea>[];
    for (final value in await _weatherApi.getWeatherAreas()) {
      if (value is! Map) {
        throw const FormatException('Item wilayah prakiraan tidak sesuai.');
      }
      final area = WeatherArea.fromJson(Map<String, dynamic>.from(value));
      if (area.province.toLowerCase() == 'sumatera barat') areas.add(area);
    }
    return List.unmodifiable(areas);
  }

  Future<WeatherForecast> loadWeatherForecast(String adm4) async {
    final response = await _weatherApi.getWeatherForecast(adm4);
    final forecast = WeatherForecast.fromEnvelope(response);
    if (forecast.area != null && forecast.area!.adm4 != adm4) {
      throw const FormatException('Kode wilayah prakiraan tidak cocok.');
    }
    return forecast;
  }

  Future<NotificationFeedSnapshot> load() async {
    try {
      final response = await _api.getNotifications();
      final raw = <Map<String, dynamic>>[];
      final items = <NotificationItem>[];
      for (final value in response.items) {
        if (value is! Map) {
          throw const FormatException('Format item notifikasi tidak sesuai.');
        }
        final item = Map<String, dynamic>.from(value);
        if (!_isCurrentSumbarBmkgItem(item)) continue;
        items.add(_parse(item));
        raw.add(item);
      }
      final checkedAt = DateTime.now();
      try {
        await _store.saveNotifications(
          raw,
          checkedAt: checkedAt,
          sourceUpdatedAt: response.sourceUpdatedAt,
        );
      } catch (_) {
        // Keep the live API result visible even if local persistence fails.
      }
      return NotificationFeedSnapshot(
        items: items,
        isFromCache: false,
        lastSyncedAt: checkedAt,
        sourceUpdatedAt: response.sourceUpdatedAt,
      );
    } catch (error) {
      try {
        final cached = await _store.readNotifications();
        final lastSyncedAt = await _store.readLastSync(
          'notifications_last_sync',
        );
        final sourceUpdatedAt = await _store.readLastSync(
          'notifications_source_last_sync',
        );
        if (cached.isNotEmpty || lastSyncedAt != null) {
          return NotificationFeedSnapshot(
            items: cached.where(_isCurrentSumbarBmkgItem).map(_parse).toList(),
            isFromCache: true,
            lastSyncedAt: lastSyncedAt,
            sourceUpdatedAt: sourceUpdatedAt,
            error: error,
          );
        }
      } catch (_) {
        // The original API error is more useful than a cache read error.
      }
      return NotificationFeedSnapshot(
        items: const [],
        isFromCache: false,
        error: error,
      );
    }
  }

  bool _isCurrentSumbarBmkgItem(Map<String, dynamic> item) {
    if (item['sumber'] != 'BMKG' ||
        item['cakupan_wilayah'] != 'Sumatera Barat') {
      return false;
    }
    final now = DateTime.now();
    return switch (item['jenis_konten']) {
      'kejadian' => _isRecentEarthquake(item, now),
      'peringatan' => _isActiveWeatherAlert(item, now),
      _ => false,
    };
  }

  bool _isRecentEarthquake(Map<String, dynamic> item, DateTime now) {
    final eventAt = DateTime.tryParse(item['waktu_kejadian']?.toString() ?? '');
    final days =
        int.tryParse(item['rentang_gempa_hari']?.toString() ?? '') ?? 7;
    return item['status'] == 'informasi' &&
        eventAt != null &&
        !eventAt.isBefore(now.subtract(Duration(days: days))) &&
        !eventAt.isAfter(now);
  }

  bool _isActiveWeatherAlert(Map<String, dynamic> item, DateTime now) {
    final startsAt = DateTime.tryParse(
      item['waktu_kejadian']?.toString() ?? '',
    );
    final expiresAt = DateTime.tryParse(
      item['waktu_berakhir']?.toString() ?? '',
    );
    return item['status'] == 'aktif' &&
        startsAt != null &&
        expiresAt != null &&
        !startsAt.isAfter(now) &&
        expiresAt.isAfter(now);
  }

  NotificationItem _parse(Map<String, dynamic> json) {
    final id = json['id']?.toString().trim() ?? '';
    final title = json['judul']?.toString().trim() ?? '';
    final summary = json['ringkasan']?.toString().trim() ?? '';
    final category = json['kategori']?.toString().trim() ?? '';
    final kindValue = json['jenis_konten']?.toString();
    final published = DateTime.tryParse(
      json['waktu_publikasi']?.toString() ?? '',
    );
    final eventAt = DateTime.tryParse(json['waktu_kejadian']?.toString() ?? '');
    final retrievedAt = DateTime.tryParse(
      json['waktu_pengambilan']?.toString() ?? '',
    );
    if (id.isEmpty ||
        title.isEmpty ||
        summary.isEmpty ||
        category.isEmpty ||
        (published == null && retrievedAt == null)) {
      throw const FormatException('Field wajib notifikasi tidak valid.');
    }
    final source = _optional(json['sumber']);
    final sourceUrl = _httpsUrl(json['url_sumber']);
    final status = _optional(json['status']);
    final kind = switch (category.toLowerCase()) {
      final value when value.contains('gempa') || value.contains('tsunami') =>
        NotificationKind.earthquake,
      final value
          when value.contains('gunung') ||
              (source?.contains('MAGMA') ?? false) =>
        NotificationKind.volcanoStatus,
      _ => NotificationKind.latestNews,
    };
    final accent = kind == NotificationKind.earthquake
        ? const Color(0xFFB7791F)
        : kind == NotificationKind.volcanoStatus
        ? const Color(0xFFE47B43)
        : const Color(0xFF5273C8);

    return NotificationItem(
      id: id,
      kind: kind,
      targetId: id,
      title: title,
      timeLabel: eventAt != null
          ? _formatDateTime(eventAt)
          : published != null
          ? _formatDateTime(published)
          : 'Waktu publikasi sumber tidak tersedia',
      summary: summary,
      icon: kind == NotificationKind.earthquake
          ? Icons.vibration_rounded
          : kind == NotificationKind.volcanoStatus
          ? Icons.crisis_alert_outlined
          : kindValue == 'peringatan'
          ? Icons.warning_amber_rounded
          : Icons.newspaper_rounded,
      accent: accent,
      category: category,
      source: source,
      sourceUrl: sourceUrl,
      region: _optional(json['wilayah']),
      status: status,
      importance: _optional(json['tingkat_kepentingan']),
      eventAt: eventAt,
      publishedAt: published,
      retrievedAt: retrievedAt,
      expiresAt: DateTime.tryParse(json['waktu_berakhir']?.toString() ?? ''),
    );
  }

  String? _optional(dynamic value) {
    if (value is! String || value.trim().isEmpty) return null;
    return value.trim();
  }

  String? _httpsUrl(dynamic value) {
    if (value is! String || value.trim().isEmpty) return null;
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      return null;
    }
    return uri.toString();
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}
