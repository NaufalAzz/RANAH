import 'package:flutter/material.dart';

import '../pages/gunung_api_page.dart';
import '../services/news_repository.dart';
import '../theme/app_theme.dart';
import 'main_shell.dart';

class RanahApp extends StatelessWidget {
  const RanahApp({this.newsRepository, super.key});

  final NewsRepository? newsRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RANAH',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: MainShell(newsRepository: newsRepository),
      routes: {
        '/uji-api-gunung': (context) => const GunungApiPage(),
      },
    );
  }
}
