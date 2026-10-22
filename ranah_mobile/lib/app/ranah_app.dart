import 'package:flutter/material.dart';

import '../pages/gunung_api_page.dart';
import '../theme/app_theme.dart';
import 'main_shell.dart';

class RanahApp extends StatelessWidget {
  const RanahApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RANAH',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const MainShell(),
      routes: {
        '/uji-api-gunung': (context) => const GunungApiPage(),
      },
    );
  }
}
