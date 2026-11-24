import 'package:flutter/material.dart';
import 'package:ranah_accessibility/ranah_accessibility.dart';

class IntroSplashPage extends StatelessWidget {
  const IntroSplashPage({required this.onFinished, super.key});
  final VoidCallback onFinished;

  @override
  Widget build(BuildContext context) => RanahIntro(onFinished: onFinished);
}
