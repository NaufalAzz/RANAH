import 'package:flutter/material.dart';

class MitigationGuide {
  const MitigationGuide({
    required this.id,
    required this.title,
    required this.color,
    required this.icon,
    required this.steps,
    required this.sourceTitle,
    required this.sourceOrganization,
    required this.sourceUrl,
    required this.sourceAccessedAt,
  });

  final String id;
  final String title;
  final Color color;
  final IconData icon;
  final List<String> steps;
  final String sourceTitle;
  final String sourceOrganization;
  final String sourceUrl;
  final String sourceAccessedAt;
}
