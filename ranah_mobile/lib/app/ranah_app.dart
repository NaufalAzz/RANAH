import 'package:flutter/material.dart';

import '../pages/gunung_api_page.dart';
import '../pages/intro_splash_page.dart';
import '../theme/app_theme.dart';
import '../services/news_repository.dart';
import '../services/notifications_repository.dart';
import '../services/complaint_api.dart';
import '../services/complaint_media_picker.dart';
import '../services/internet_status_monitor.dart';
import 'main_shell.dart';

class RanahApp extends StatefulWidget {
  const RanahApp({
    this.newsRepository,
    this.notificationsRepository,
    this.complaintApi,
    this.mediaPicker,
    this.internetStatusMonitor,
    super.key,
  });

  final NewsRepository? newsRepository;
  final NotificationsRepository? notificationsRepository;
  final ComplaintApi? complaintApi;
  final ComplaintMediaPicker? mediaPicker;
  final InternetStatusMonitor? internetStatusMonitor;

  @override
  State<RanahApp> createState() => _RanahAppState();
}

class _RanahAppState extends State<RanahApp> {
  bool _showIntro = true;

  void _finishIntro() {
    if (!mounted || !_showIntro) return;
    setState(() => _showIntro = false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RANAH',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: Builder(
        builder: (context) {
          final transitionDuration = MediaQuery.of(context).disableAnimations
              ? Duration.zero
              : const Duration(milliseconds: 240);
          return AnimatedSwitcher(
            duration: transitionDuration,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.02),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: _showIntro
                ? IntroSplashPage(
                    key: const ValueKey('intro-splash'),
                    onFinished: _finishIntro,
                  )
                : MainShell(
                    key: const ValueKey('main-shell'),
                    newsRepository: widget.newsRepository,
                    notificationsRepository: widget.notificationsRepository,
                    complaintApi: widget.complaintApi,
                    mediaPicker: widget.mediaPicker,
                    internetStatusMonitor: widget.internetStatusMonitor,
                  ),
          );
        },
      ),
      routes: {'/uji-api-gunung': (context) => const GunungApiPage()},
    );
  }
}
