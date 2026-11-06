import 'package:ranah_accessibility/ranah_accessibility.dart' as learning;
import 'package:flutter/material.dart';

enum MitigationStage { before, during, evacuation, after }

class MitigationGuide {
  const MitigationGuide({
    required this.stage,
    required this.label,
    required this.accent,
    required this.cardColors,
    required this.steps,
    required this.notice,
    this.placeholder = false,
  });

  final MitigationStage stage;
  final String label;
  final Color accent;
  final List<Color> cardColors;
  final List<String> steps;
  final String notice;
  final bool placeholder;
}

/// Compatibility projection of the shared, source-attributed learning content.
final mitigationGuides = [
  for (var i = 0; i < learning.mitigationLessons.length; i++)
    MitigationGuide(
      stage: MitigationStage.values[i],
      label: learning.mitigationLessons[i].title,
      accent: learning.mitigationLessons[i].accent,
      cardColors: const [Color(0xFF133D5C), Color(0xFF103954)],
      steps: learning.mitigationLessons[i].steps
          .map((step) => step.action)
          .toList(growable: false),
      notice:
          'Ringkasan edukasi RANAH dari ${learning.mitigationLessons[i].steps.map((step) => step.source.organization).toSet().join(' · ')}. Diakses ${learning.GuideSource.checkedAt}. Ikuti arahan PVMBG/BPBD setempat.',
    ),
];
