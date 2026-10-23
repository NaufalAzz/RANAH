import 'package:flutter/material.dart';

class EmergencyContact {
  const EmergencyContact({
    required this.id,
    required this.name,
    required this.organization,
    required this.displayNumber,
    required this.dialNumbers,
    required this.icon,
    required this.numberVerified,
    required this.sourceTitle,
    required this.sourceOrganization,
    required this.sourceUrl,
    required this.sourceAccessedAt,
    this.note,
  });

  final String id;
  final String name;
  final String organization;
  final String displayNumber;
  final List<String> dialNumbers;
  final IconData icon;
  final bool numberVerified;
  final String sourceTitle;
  final String sourceOrganization;
  final String sourceUrl;
  final String sourceAccessedAt;
  final String? note;

  String get sourceAttribution => numberVerified
      ? '$organization • Sumber: $sourceOrganization'
      : 'Nomor belum diverifikasi';
}
