import 'package:flutter/material.dart';

import '../data/sample_news.dart';
import '../models/notification_item.dart';
import '../pages/home_page.dart';
import '../pages/map_page.dart';
import '../pages/menu_page.dart';
import '../pages/news_page.dart';
import '../pages/notifications_page.dart';
import '../widgets/brand_header.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  bool _showingNotifications = false;
  String? _notificationNewsId;
  int _notificationSelectionRevision = 0;

  void _openTab(int index) => setState(() {
    _selectedIndex = index;
    _showingNotifications = false;
  });

  void _toggleNotifications() =>
      setState(() => _showingNotifications = !_showingNotifications);

  void _openNotificationDestination(NotificationItem item) {
    switch (item.kind) {
      case NotificationKind.latestNews:
        final newsId = item.targetId;
        final exists = sampleNews.any((news) => news.id == newsId);
        if (newsId == null || !exists) {
          _showDestinationUnavailable('Artikel berita terkait tidak tersedia.');
          return;
        }
        setState(() {
          _notificationNewsId = newsId;
          _notificationSelectionRevision++;
          _selectedIndex = 2;
          _showingNotifications = false;
        });
        return;
      case NotificationKind.earthquake:
      case NotificationKind.evacuation:
        setState(() {
          _selectedIndex = 1;
          _showingNotifications = false;
        });
        _showDestinationUnavailable(
          item.kind == NotificationKind.earthquake
              ? 'Peta masih berupa ilustrasi; rincian gempa resmi belum tersedia.'
              : 'Peta masih berupa ilustrasi; rute dan titik aman resmi belum tersedia.',
        );
        return;
      case NotificationKind.volcanoActivity:
      case NotificationKind.volcanoStatus:
        _showDestinationUnavailable(
          item.kind == NotificationKind.volcanoActivity
              ? 'Detail laporan aktivitas gunung api belum tersedia.'
              : 'Informasi status gunung api belum tersedia.',
        );
        return;
    }
  }

  void _showDestinationUnavailable(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomePage(onOpenNews: () => _openTab(2)),
      const MapPage(),
      NewsPage(
        initialNewsId: _notificationNewsId,
        selectionRevision: _notificationSelectionRevision,
      ),
      const MenuPage(),
    ];

    return PopScope<Object?>(
      canPop: !_showingNotifications,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _showingNotifications) {
          setState(() => _showingNotifications = false);
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final contentWidth = constraints.maxWidth < 560
                  ? constraints.maxWidth
                  : 560.0;

              // Keep a tight, finite height around the shell so the tab viewport
              // and its ListView children receive valid layout constraints on web
              // as well as on compact mobile screens.
              return Center(
                child: SizedBox(
                  width: contentWidth,
                  height: constraints.maxHeight,
                  child: Column(
                    children: [
                      BrandHeader(onOpenNotifications: _toggleNotifications),
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            IndexedStack(
                              index: _selectedIndex,
                              children: pages,
                            ),
                            if (_showingNotifications)
                              Positioned.fill(
                                child: NotificationsPage(
                                  onNotificationTap:
                                      _openNotificationDestination,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        bottomNavigationBar: SizedBox(
          height: 68,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final contentWidth = constraints.maxWidth < 560
                  ? constraints.maxWidth
                  : 560.0;
              return Center(
                child: SizedBox(
                  width: contentWidth,
                  child: NavigationBar(
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: _openTab,
                    labelBehavior:
                        NavigationDestinationLabelBehavior.alwaysShow,
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.home_outlined),
                        selectedIcon: Icon(Icons.home_rounded),
                        label: 'Beranda',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.map_outlined),
                        selectedIcon: Icon(Icons.map_rounded),
                        label: 'Peta',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.newspaper_outlined),
                        selectedIcon: Icon(Icons.newspaper_rounded),
                        label: 'Berita',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.menu_rounded),
                        selectedIcon: Icon(Icons.grid_view_rounded),
                        label: 'Menu',
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
