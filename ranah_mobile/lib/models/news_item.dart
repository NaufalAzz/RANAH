import 'package:flutter/material.dart';
import 'package:ranah_accessibility/ranah_accessibility.dart'
    show newsDayRangeLabel;

class NewsItem {
  const NewsItem({
    required this.id,
    required this.category,
    required this.title,
    required this.summary,
    required this.body,
    required this.publishedAt,
    required this.icon,
    required this.accent,
    this.contentType = 'artikel',
    this.source,
    this.imageCaption,
    this.author,
    this.sourceUrl,
    this.region,
    this.imageUrl,
    this.eventAt,
    this.bulletinDays,
    this.expiresAt,
    this.retrievedAt,
  });

  final String id;
  final String category;
  final String title;
  final String summary;
  final String body;
  final String publishedAt;
  final IconData icon;
  final Color accent;
  final String contentType;
  final String? source;
  final String? imageCaption;
  final String? author;
  final String? sourceUrl;
  final String? region;
  final String? imageUrl;
  final DateTime? eventAt;
  final DateTimeRange? bulletinDays;
  final DateTime? expiresAt;
  final DateTime? retrievedAt;

  String? get timeLabel {
    if (contentType == 'peringatan' && eventAt != null) {
      return 'Berlaku sejak: ${_formatDateTime(eventAt!)}';
    }
    if (bulletinDays case final days?) {
      return 'Kejadian: ${newsDayRangeLabel(days)}';
    }
    if (eventAt != null) return 'Kejadian: ${_formatDate(eventAt!)}';
    if (source?.toUpperCase().contains('BNPB') ?? false) return null;
    return 'Diterbitkan: $publishedAt';
  }

  static String _formatDate(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year}';
  }

  static String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    return '${_formatDate(local)} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}
