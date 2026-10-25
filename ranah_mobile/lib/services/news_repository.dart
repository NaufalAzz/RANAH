import 'package:flutter/material.dart';

import '../data/sample_news.dart';
import '../models/news_item.dart';
import '../theme/app_theme.dart';
import 'api_service.dart';
import 'gunung_local_store.dart';
import 'news_api.dart';

class NewsFeedSnapshot {
  const NewsFeedSnapshot({
    required this.items,
    required this.isUsingFallback,
    required this.isFromCache,
    this.cacheWriteFailed = false,
    this.lastSyncedAt,
    this.error,
    this.hasUpdates = false,
  });

  final List<NewsItem> items;
  final bool isUsingFallback;
  final bool isFromCache;
  final bool cacheWriteFailed;
  final DateTime? lastSyncedAt;
  final Object? error;
  final bool hasUpdates;
}

class NewsRepository {
  NewsRepository({NewsApi? api, GunungLocalStore? localStore})
    : _api = api ?? ApiService(),
      _localStore = localStore ?? GunungLocalStore.instance;

  final NewsApi _api;
  final GunungLocalStore _localStore;

  Future<NewsFeedSnapshot> load() async {
    late final List<Map<String, dynamic>> rawItems;
    late final List<NewsItem> items;
    try {
      final response = await _api.getBerita();
      rawItems = <Map<String, dynamic>>[];
      items = <NewsItem>[];
      for (final rawItem in response) {
        if (rawItem is! Map) {
          throw const FormatException('Format item berita tidak sesuai.');
        }
        final json = Map<String, dynamic>.from(rawItem);
        if (_isInactiveWarning(json)) continue;
        items.add(_parse(json));
        rawItems.add(json);
      }
    } catch (error) {
      return _offlineResult(error);
    }

    final checkedAt = DateTime.now();
    var hasUpdates = true;
    try {
      hasUpdates = await _localStore.saveNewsIfChanged(
        rawItems,
        checkedAt: checkedAt,
      );
      return NewsFeedSnapshot(
        items: items,
        isUsingFallback: false,
        isFromCache: false,
        lastSyncedAt: checkedAt,
        hasUpdates: hasUpdates,
      );
    } catch (error) {
      // Display fresh server data even if SQLite could not persist it.
      return NewsFeedSnapshot(
        items: items,
        isUsingFallback: false,
        isFromCache: false,
        cacheWriteFailed: true,
        lastSyncedAt: checkedAt,
        error: error,
        hasUpdates: hasUpdates,
      );
    }
  }

  Future<NewsFeedSnapshot> _offlineResult(Object error) async {
    try {
      final cachedItems = await _localStore.readNews();
      final lastSyncedAt = await _localStore.readLastSync('news_last_sync');
      if (cachedItems.isNotEmpty || lastSyncedAt != null) {
        return NewsFeedSnapshot(
          items: cachedItems
              .where((item) => !_isInactiveWarning(item))
              .map(_parse)
              .toList(),
          isUsingFallback: false,
          isFromCache: true,
          lastSyncedAt: lastSyncedAt,
          error: error,
        );
      }
    } catch (_) {
      // Keep the original sync error and use clearly labeled demo content.
    }
    return NewsFeedSnapshot(
      items: sampleNews,
      isUsingFallback: true,
      isFromCache: false,
      error: error,
    );
  }

  NewsItem _parse(Map<String, dynamic> json) {
    final rawId = json['id'];
    final id = rawId?.toString().trim() ?? '';
    final category = json['kategori']?.toString().trim() ?? '';
    final title = json['judul']?.toString().trim() ?? '';
    final body = json['isi']?.toString().trim() ?? '';
    final published = DateTime.tryParse(
      json['waktu_publikasi']?.toString() ?? '',
    );
    if (id.isEmpty ||
        category.isEmpty ||
        title.isEmpty ||
        body.isEmpty ||
        published == null) {
      throw const FormatException('Field berita wajib tidak valid.');
    }

    final categoryKey = category.toLowerCase();
    final type = json['jenis_konten']?.toString().trim();
    final contentType =
        const {'artikel', 'kejadian', 'peringatan'}.contains(type)
        ? type!
        : 'artikel';
    final accent =
        categoryKey.contains('erupsi') || categoryKey.contains('gunung')
        ? AppColors.eruption
        : categoryKey.contains('gempa') || categoryKey.contains('tsunami')
        ? const Color(0xFFB7791F)
        : categoryKey.contains('imbauan') || categoryKey.contains('bantuan')
        ? AppColors.teal
        : const Color(0xFFB7791F);
    final icon =
        categoryKey.contains('erupsi') || categoryKey.contains('gunung')
        ? Icons.landscape_rounded
        : categoryKey.contains('gempa') || categoryKey.contains('tsunami')
        ? Icons.waves_rounded
        : contentType == 'peringatan'
        ? Icons.warning_amber_rounded
        : Icons.newspaper_rounded;
    final summaryText = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    final summary = summaryText.length <= 180
        ? summaryText
        : '${summaryText.substring(0, 177)}…';
    final publishedAt = _formatPublicationDate(published);
    final source = _optionalString(json['sumber']);
    final imageUrl = _validImageUrl(json['gambar']);

    final expiresAt = DateTime.tryParse(
      json['waktu_berakhir']?.toString() ?? '',
    );
    return NewsItem(
      id: id,
      category: category,
      title: title,
      summary: summary,
      body: body,
      publishedAt: publishedAt,
      icon: icon,
      accent: accent,
      source: source,
      contentType: contentType,
      sourceUrl: _validHttpsUrl(json['url_sumber']),
      region: _optionalString(json['wilayah']),
      imageUrl: imageUrl,
      eventAt: DateTime.tryParse(json['waktu_kejadian']?.toString() ?? ''),
      expiresAt: expiresAt,
      retrievedAt: DateTime.tryParse(
        json['waktu_pengambilan']?.toString() ?? '',
      ),
    );
  }

  String _formatPublicationDate(DateTime published) {
    final localDate = published.toLocal();
    return '${localDate.day.toString().padLeft(2, '0')}-'
        '${localDate.month.toString().padLeft(2, '0')}-'
        '${localDate.year}';
  }

  bool _isInactiveWarning(Map<String, dynamic> json) {
    if (json['jenis_konten']?.toString() != 'peringatan') return false;
    final expiresAt = DateTime.tryParse(
      json['waktu_berakhir']?.toString() ?? '',
    );
    return expiresAt == null || !expiresAt.isAfter(DateTime.now());
  }

  String? _optionalString(dynamic value) {
    if (value is! String || value.trim().isEmpty) return null;
    return value.trim();
  }

  String? _validHttpsUrl(dynamic value) {
    if (value is! String || value.trim().isEmpty) return null;
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.scheme != 'https') {
      return null;
    }
    return uri.toString();
  }

  String? _validImageUrl(dynamic value) {
    if (value is! String || value.trim().isEmpty) return null;
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        (uri.scheme != 'https' && uri.scheme != 'http')) {
      return null;
    }
    return uri.toString();
  }
}
