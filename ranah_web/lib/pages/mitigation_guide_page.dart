import 'package:flutter/material.dart';
import 'package:ranah_accessibility/ranah_accessibility.dart';

class MitigationGuidePage extends StatelessWidget {
  const MitigationGuidePage({required this.onBack, super.key});
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) => MitigationLearningPage(onBack: onBack);
}
