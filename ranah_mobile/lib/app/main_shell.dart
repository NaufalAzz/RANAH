import 'package:ranah_accessibility/ranah_accessibility.dart';

import '../pages/mitigation_page.dart';
import '../pages/contact_complaint_page.dart';

import 'package:flutter/material.dart';

import '../models/news_item.dart';
import '../pages/home_page.dart';
import '../pages/gunung_report_page.dart';
import '../pages/map_page.dart';
import '../pages/menu_page.dart';
import '../pages/news_page.dart';
import '../pages/notifications_page.dart';
import '../pages/volcanic_activity_page.dart';
import '../services/news_repository.dart';
import '../services/notifications_repository.dart';
import '../services/complaint_api.dart';
import '../services/complaint_media_picker.dart';
import '../services/internet_status_monitor.dart';
import '../widgets/news_feed_notice.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_header.dart';
import '../widgets/ranah_page_route.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    this.newsRepository,
    this.voiceEngine,
    this.notificationsRepository,
    this.complaintApi,
    this.mediaPicker,
    this.internetStatusMonitor,
    this.mapTilesEnabled = true,
    super.key,
  });

  final NewsRepository? newsRepository;
  final VoiceEngine? voiceEngine;
  final NotificationsRepository? notificationsRepository;
  final ComplaintApi? complaintApi;
  final ComplaintMediaPicker? mediaPicker;
  final InternetStatusMonitor? internetStatusMonitor;
  final bool mapTilesEnabled;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  bool _showingNotifications = false;
  String? _notificationNewsId;
  int _notificationSelectionRevision = 0;
  late final NewsRepository _newsRepository;
  late final InternetStatusMonitor _internetStatusMonitor;
  List<NewsItem> _newsItems = const [];
  bool _newsUsingFallback = false;
  bool _newsFromCache = false;
  bool _newsLoading = true;
  Object? _newsError;

  @override
  void initState() {
    super.initState();
    _newsRepository = widget.newsRepository ?? NewsRepository();
    _internetStatusMonitor =
        widget.internetStatusMonitor ?? InternetStatusMonitor();
    _internetStatusMonitor.start();
    _loadNews();
  }

  Future<void> _loadNews() async {
    final result = await _newsRepository.load();
    if (!mounted) return;
    setState(() {
      _newsItems = result.items;
      _newsUsingFallback = result.isUsingFallback;
      _newsFromCache = result.isFromCache;
      _newsError = result.error;
      _newsLoading = false;
    });
    if (result.hasUpdates) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(NewsFeedNotice.updated());
      });
    }
  }

  @override
  void dispose() {
    _internetStatusMonitor.dispose();
    super.dispose();
  }

  void _openTab(int index) {
    setState(() {
      _selectedIndex = index;
      _showingNotifications = false;
    });
  }

  void _openContacts() {
    Navigator.of(context).push(
      RanahPageRoute<void>(
        context: context,
        builder: (_) => ContactComplaintPage(
          onBack: () => Navigator.of(context).pop(),
          complaintApi: widget.complaintApi,
          mediaPicker: widget.mediaPicker,
        ),
      ),
    );
  }

  Future<void> _openVoice() async {
    final destination = await showVoiceNavigation(
      context,
      engine: widget.voiceEngine,
    );
    if (!mounted || destination == null) return;
    switch (destination) {
      case VoiceDestination.home:
        _openTab(0);
      case VoiceDestination.map:
        _openTab(1);
      case VoiceDestination.news:
        _openTab(2);
      case VoiceDestination.menu:
        _openTab(3);
      case VoiceDestination.contacts:
        _openContacts();
      case VoiceDestination.notifications:
        setState(() => _showingNotifications = true);
      case VoiceDestination.guide:
        Navigator.of(context).push(
          RanahPageRoute<void>(
            context: context,
            builder: (_) =>
                MitigationPage(onBackToHome: () => Navigator.of(context).pop()),
          ),
        );
      case VoiceDestination.activity:
        Navigator.of(context).push(
          RanahPageRoute<void>(
            context: context,
            builder: (_) =>
                VolcanicActivityPage(onBack: () => Navigator.of(context).pop()),
          ),
        );
    }
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

  @override
  Widget build(BuildContext context) {
    final animationsDisabled = MediaQuery.of(context).disableAnimations;
    final transitionDuration = animationsDisabled
        ? Duration.zero
        : const Duration(milliseconds: 240);
    final scaledNavigationLabelSize = MediaQuery.textScalerOf(context)
        .scale(AppTypography.label.fontSize!);
    final bottomNavigationHeight =
        scaledNavigationLabelSize + AppSizes.bottomNavigationLabelClearance;
    final responsiveNavigationHeight =
        bottomNavigationHeight < AppSizes.bottomNavigationHeight
        ? AppSizes.bottomNavigationHeight
        : bottomNavigationHeight;

    final pages = <Widget>[
      HomePage(
        onOpenContacts: _openContacts,
        onOpenNews: _openNews,
        items: _newsItems,
        isUsingFallback: _newsUsingFallback,
        isFromCache: _newsFromCache,
        loadError: _newsError,
        isLoading: _newsLoading,
        onRetry: _loadNews,
      ),
      MapPage(
        tilesEnabled: widget.mapTilesEnabled,
        onOpenReport: (item) {
          final id = int.tryParse(item['id']?.toString() ?? '');
          if (id == null) return;
          Navigator.of(context).push(
            RanahPageRoute<void>(
              context: context,
              builder: (_) => GunungReportPage(
                gunungId: id,
                namaGunung: item['nama']?.toString(),
              ),
            ),
          );
        },
        onOpenActivity: () => Navigator.of(context).push(
          RanahPageRoute<void>(
            context: context,
            builder: (_) =>
                VolcanicActivityPage(onBack: () => Navigator.of(context).pop()),
          ),
        ),
      ),
      NewsPage(
        initialNewsId: _notificationNewsId,
        selectionRevision: _notificationSelectionRevision,
        items: _newsItems,
        loadError: _newsError,
        isLoading: _newsLoading,
        onRetry: _loadNews,
      ),
      MenuPage(
        complaintApi: widget.complaintApi,
        mediaPicker: widget.mediaPicker,
      ),
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
              final contentWidth =
                  constraints.maxWidth < AppSizes.maxContentWidth
                  ? constraints.maxWidth
                  : AppSizes.maxContentWidth;

              return Center(
                child: SizedBox(
                  width: contentWidth,
                  height: constraints.maxHeight,
                  child: Column(
                    children: [
                      ValueListenableBuilder<bool>(
                        valueListenable: _internetStatusMonitor.isOnline,
                        builder: (context, isOnline, child) => BrandHeader(
                          isOnline: isOnline,
                          onOpenNotifications: _toggleNotifications,
                        ),
                      ),
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            for (var index = 0; index < pages.length; index++)
                              Positioned.fill(
                                key: ValueKey('main-tab-$index'),
                                child: IgnorePointer(
                                  ignoring: index != _selectedIndex,
                                  child: Offstage(
                                    offstage: index != _selectedIndex,
                                    child: ExcludeSemantics(
                                      excluding: index != _selectedIndex,
                                      child: AnimatedOpacity(
                                        opacity: index == _selectedIndex
                                            ? 1
                                            : 0,
                                        duration: transitionDuration,
                                        curve: Curves.easeOutCubic,
                                        child: AnimatedSlide(
                                          offset: index == _selectedIndex
                                              ? Offset.zero
                                              : const Offset(0.025, 0),
                                          duration: transitionDuration,
                                          curve: Curves.easeOutCubic,
                                          child: pages[index],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            Positioned.fill(
                              child: IgnorePointer(
                                ignoring: !_showingNotifications,
                                child: Offstage(
                                  offstage: !_showingNotifications,
                                  child: ExcludeSemantics(
                                    excluding: !_showingNotifications,
                                    child: AnimatedOpacity(
                                      opacity: _showingNotifications ? 1 : 0,
                                      duration: transitionDuration,
                                      curve: Curves.easeOutCubic,
                                      child: AnimatedSlide(
                                        offset: _showingNotifications
                                            ? Offset.zero
                                            : const Offset(0, -0.025),
                                        duration: transitionDuration,
                                        curve: Curves.easeOutCubic,
                                        child: NotificationsPage(
                                          repository:
                                              widget.notificationsRepository,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
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
          height: responsiveNavigationHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final contentWidth =
                  constraints.maxWidth < AppSizes.maxContentWidth
                  ? constraints.maxWidth
                  : AppSizes.maxContentWidth;

              return Center(
                child: SizedBox(
                  width: contentWidth,
                  child: NavigationBar(
                    height: responsiveNavigationHeight,
                    selectedIndex: _selectedIndex < 2
                        ? _selectedIndex
                        : _selectedIndex + 1,
                    onDestinationSelected: (index) {
                      if (index == 2) {
                        _openVoice();
                      } else {
                        _openTab(index < 2 ? index : index - 1);
                      }
                    },
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
                        icon: Icon(Icons.mic_none_rounded),
                        selectedIcon: Icon(Icons.mic_rounded),
                        label: 'Suara',
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
