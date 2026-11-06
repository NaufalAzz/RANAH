import 'package:ranah_accessibility/ranah_accessibility.dart';

import '../models/mitigation_guide.dart';

final mitigationGuides = [
  for (final lesson in mitigationLessons)
    MitigationGuide(
      id: lesson.id,
      title: lesson.title,
      color: lesson.accent,
      icon: lesson.icon,
      steps: lesson.steps.map((step) => step.action).toList(growable: false),
      sourceTitle: lesson.steps
          .map((step) => step.source.title)
          .toSet()
          .join(' · '),
      sourceOrganization: lesson.steps
          .map((step) => step.source.organization)
          .toSet()
          .join(' · '),
      sourceUrl: lesson.steps.first.source.url,
      sourceAccessedAt: GuideSource.checkedAt,
    ),
];
