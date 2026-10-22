import 'package:flutter/material.dart';

class MitigationGuide {
  const MitigationGuide({
    required this.id,
    required this.title,
    required this.color,
    required this.icon,
    required this.steps,
  });

  final String id;
  final String title;
  final Color color;
  final IconData icon;
  final List<String> steps;
}
