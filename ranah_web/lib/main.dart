import 'package:flutter/material.dart';

import 'app/ranah_app.dart';
import 'theme/ranah_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RANAH',
      debugShowCheckedModeBanner: false,
      theme: RanahTheme.light,
      home: const RanahShell(),
    );
  }
}
