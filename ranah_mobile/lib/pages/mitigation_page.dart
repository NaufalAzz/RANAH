import 'package:flutter/material.dart';
import 'package:ranah_accessibility/ranah_accessibility.dart';

class MitigationPage extends StatelessWidget {
  const MitigationPage({required this.onBackToHome, super.key});
  final VoidCallback onBackToHome;
  @override
  Widget build(BuildContext context) =>
      MitigationLearningPage(onBack: onBackToHome);
}
