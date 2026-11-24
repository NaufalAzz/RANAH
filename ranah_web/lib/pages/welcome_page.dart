import 'package:flutter/material.dart';
import 'package:ranah_accessibility/ranah_accessibility.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({required this.onFinished, super.key});
  final VoidCallback onFinished;

  @override
  Widget build(BuildContext context) =>
      RanahIntro(onFinished: onFinished, wideLayout: true);
}
