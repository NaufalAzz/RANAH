import 'dart:async';

import '../services/mobile_location_provider.dart';

import 'package:ranah_accessibility/ranah_accessibility.dart';

import '../pages/mitigation_page.dart';
import '../pages/contact_complaint_page.dart';

import 'package:flutter/material.dart';

import '../models/news_item.dart';
import '../models/notification_item.dart';
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
    this.locationProvider,
    this.newsRepository,
    this.voiceEngine,
    this.notificationsRepository,
    this.complaintApi,
    this.mediaPicker,
    this.internetStatusMonitor,
    this.mapTilesEnabled = true,
    super.key,
  });

  final MobileLocationProvider? locationProvider;
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
  DeviceLocationFix? _sharedLocation;
  Timer? _newsTimer;
  Timer? _notificationTimer;
  int _earthquakeCount = 0;
  late final NotificationsRepository _notificationsRepository;
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
    _notificationsRepository =
        widget.notificationsRepository ?? NotificationsRepository();
    _internetStatusMonitor =
        widget.internetStatusMonitor ?? InternetStatusMonitor();
    _internetStatusMonitor.start();
    _loadNews();
    _loadEarthquakeCount();
    _notificationTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _loadEarthquakeCount(),
    );
    _newsTimer = Timer.periodic(
      const Duration(minutes: 15),
      (_) => _loadNews(),
    );
  }

  Future<void> _loadEarthquakeCount() async {
    final feed = await _notificationsRepository.load();
    if (!mounted) return;
    if (feed.error != null) {
      setState(() => _earthquakeCount = 0);
      return;
    }
    setState(
      () => _earthquakeCount = feed.items
          .where((item) => item.kind == NotificationKind.earthquake)
          .length,
    );
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
    _newsTimer?.cancel();
    _notificationTimer?.cancel();
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
    if (!_showingNotifications) _loadEarthquakeCount();
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
    final responsiveNavigationHeight = bottomNavigationHeight < 82
        ? 82.0
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
        initialLocation: _sharedLocation,
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
                          notificationCount: _earthquakeCount,
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
                                    offstage:
                                        index != _selectedIndex ||
                                        _showingNotifications,
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
                                          child: TickerMode(
                                            enabled:
                                                index == _selectedIndex &&
                                                !_showingNotifications,
                                            child: pages[index],
                                          ),
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
                                        child: TickerMode(
                                          enabled: _showingNotifications,
                                          child: NotificationsPage(
                                            repository:
                                                _notificationsRepository,
                                          ),
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
                child: Container(
                  width: contentWidth,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryDark,
                    border: Border(
                      top: BorderSide(color: Color(0x22FFFFFF), width: 1.0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x33000511),
                        blurRadius: 16,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
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
                        icon: _VoiceNavigationIcon(),
                        selectedIcon: _VoiceNavigationIcon(),
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

class _VoiceNavigationIcon extends StatelessWidget {
  const _VoiceNavigationIcon();

  @override
  Widget build(BuildContext context) => Transform.translate(
    offset: const Offset(0, -5),
    child: Container(
      key: const ValueKey('voice-navigation-circle'),
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF385D7B), Color(0xFF343461)],
        ),
        border: Border.all(color: const Color(0xFF92BFCB), width: 1.5),
      ),
      child: const Icon(Icons.mic_rounded, color: Colors.white, size: 26),
    ),
  );
}
