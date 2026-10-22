import 'package:flutter/material.dart';

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
  });

  final String id;
  final String category;
  final String title;
  final String summary;
  final String body;
  final String publishedAt;
  final IconData icon;
  final Color accent;
}
