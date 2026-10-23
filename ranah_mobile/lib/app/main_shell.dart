import 'package:flutter/material.dart';

import '../data/sample_news.dart';
import '../models/notification_item.dart';
import '../models/news_item.dart';
import '../pages/home_page.dart';
import '../pages/map_page.dart';
import '../pages/menu_page.dart';
import '../pages/news_page.dart';
import '../pages/notifications_page.dart';
import '../pages/volcanic_activity_page.dart';
import '../services/news_repository.dart';
import '../widgets/brand_header.dart';

class MainShell extends StatefulWidget {
  const MainShell({this.newsRepository, super.key});

  final NewsRepository? newsRepository;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  bool _showingNotifications = false;
  String? _notificationNewsId;
  int _notificationSelectionRevision = 0;
  late final NewsRepository _newsRepository;
  List<NewsItem> _newsItems = sampleNews;
  bool _newsUsingFallback = true;
  bool _newsLoading = true;
  bool _newsFromCache = false;
  bool _newsCacheWriteFailed = false;
  DateTime? _newsLastSyncedAt;

  @override
  void initState() {
    super.initState();
    _newsRepository = widget.newsRepository ?? NewsRepository();
    _loadNews();
  }

  Future<void> _loadNews() async {
    final result = await _newsRepository.load();
    if (!mounted) return;
    setState(() {
      _newsItems = result.items;
      _newsUsingFallback = result.isUsingFallback;
      _newsLoading = false;
      _newsFromCache = result.isFromCache;
      _newsCacheWriteFailed = result.cacheWriteFailed;
      _newsLastSyncedAt = result.lastSyncedAt;
    });
  }

  void _openTab(int index) {
    setState(() {
      _selectedIndex = index;
      _showingNotifications = false;
    });
  }

  void _toggleNotifications() {
    setState(() => _showingNotifications = !_showingNotifications);
  }

  void _openNews(NewsItem item) {
    setState(() {
      _notificationNewsId = item.id;
      _notificationSelectionRevision++;
      _selectedIndex = 2;
      _showingNotifications = false;
    });
  }

  void _openNotificationDestination(NotificationItem item) {
    switch (item.kind) {
      case NotificationKind.latestNews:
        final newsId = item.targetId;
        final exists = _newsItems.any((news) => news.id == newsId);

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
        setState(() => _showingNotifications = false);

        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                VolcanicActivityPage(onBack: () => Navigator.of(context).pop()),
          ),
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
      HomePage(
        onOpenNews: _openNews,
        items: _newsItems,
        isUsingFallback: _newsUsingFallback,
        isLoadingNews: _newsLoading,
        isFromCache: _newsFromCache,
        cacheWriteFailed: _newsCacheWriteFailed,
        lastSyncedAt: _newsLastSyncedAt,
      ),
      const MapPage(),
      NewsPage(
        initialNewsId: _notificationNewsId,
        selectionRevision: _notificationSelectionRevision,
        items: _newsItems,
        isUsingFallback: _newsUsingFallback,
        isLoadingNews: _newsLoading,
        isFromCache: _newsFromCache,
        cacheWriteFailed: _newsCacheWriteFailed,
        lastSyncedAt: _newsLastSyncedAt,
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
