import 'package:flutter/material.dart';

import '../data/volcanic_activity_data.dart';
import '../data/home_stories.dart';
import '../data/sample_notifications.dart';
import '../pages/map_page.dart';
import '../pages/evacuation_route_page.dart';
import '../pages/news_detail_page.dart';
import '../pages/news_page.dart';
import '../pages/notifications_page.dart';
import '../pages/home_page.dart';
import '../pages/emergency_contacts_page.dart';
import '../pages/admin_login_page.dart';
import '../pages/admin_panel_page.dart';
import '../pages/mitigation_guide_page.dart';
import '../pages/volcanic_activity_page.dart';
import '../pages/volcano_report_page.dart';
import '../theme/ranah_theme.dart';
import '../widgets/ranah_background.dart';
import '../widgets/ranah_header.dart';

enum _Page {
  home,
  map,
  evacuationRoute,
  activity,
  volcanoReport,
  news,
  contact,
  mitigation,
  notifications,
  story,
  adminLogin,
  adminPreview,
}

class RanahShell extends StatefulWidget {
  const RanahShell({super.key});

  @override
  State<RanahShell> createState() => _RanahShellState();
}

class _RanahShellState extends State<RanahShell> {
  late _Page _page;
  _Page _reportReturnPage = _Page.map;
  _Page _storyReturnPage = _Page.home;
  _Page _mitigationReturnPage = _Page.home;
  _Page _notificationsReturnPage = _Page.home;
  _Page _activityReturnPage = _Page.map;
  _Page _contactsReturnPage = _Page.home;
  _Page _routeReturnPage = _Page.map;
  bool _mapLocationDetails = false;
  Offset _manualMapPinPosition = const Offset(.23, .60);
  bool _manualMapLocationChosen = false;
  late VolcanoActivitySample _selectedVolcano;
  HomeStory? _selectedStory;
  bool _menuOpen = false;

  @override
  void initState() {
    super.initState();
    _page = Uri.base.path == '/admin' || Uri.base.path.startsWith('/admin/')
        ? _Page.adminLogin
        : _Page.home;
    _selectedVolcano = volcanicActivitySamples.firstWhere(
      (volcano) => volcano.name == 'Gunung Marapi',
    );
  }

  void _navigate(_Page page) {
    setState(() {
      _page = page;
      _menuOpen = false;
    });
  }

  void _openVolcanoReport(String name, _Page returnPage) {
    setState(() {
      _selectedVolcano = volcanicActivitySamples.firstWhere(
        (volcano) => volcano.name == name,
        orElse: () => volcanicActivitySamples.first,
      );
      _reportReturnPage = returnPage;
      _page = _Page.volcanoReport;
      _menuOpen = false;
    });
  }

  void _openStory(HomeStory story, _Page returnPage) {
    setState(() {
      _selectedStory = story;
      _storyReturnPage = returnPage;
      _page = _Page.story;
      _menuOpen = false;
    });
  }

  void _openMitigationGuide() {
    setState(() {
      _mitigationReturnPage = _page;
      _page = _Page.mitigation;
      _menuOpen = false;
    });
  }

  void _openNotifications() {
    setState(() {
      if (_page != _Page.notifications) {
        _notificationsReturnPage = _page;
      }
      _page = _Page.notifications;
      _menuOpen = false;
    });
  }

  void _openActivity(_Page returnPage) {
    setState(() {
      _activityReturnPage = returnPage;
      _page = _Page.activity;
      _menuOpen = false;
    });
  }

  void _openEvacuationRoute(_Page returnPage) {
    setState(() {
      _routeReturnPage = returnPage;
      _page = _Page.evacuationRoute;
      _menuOpen = false;
    });
  }

  void _openNotificationDestination(SampleNotification notification) {
    switch (notification.destination) {
      case SampleNotificationDestination.volcanicActivity:
        _openActivity(_Page.notifications);
      case SampleNotificationDestination.volcanoReport:
        final volcanoName = notification.volcanoName;
        if (volcanoName != null) {
          _openVolcanoReport(volcanoName, _Page.notifications);
        }
      case null:
        return;
    }
  }

  void _openContacts() {
    setState(() {
      _contactsReturnPage = _page;
      _page = _Page.contact;
      _menuOpen = false;
    });
  }

  void _onDestination(RanahDestination destination) {
    switch (destination) {
      case RanahDestination.home:
        _navigate(_Page.home);
      case RanahDestination.map:
        _navigate(_Page.map);
      case RanahDestination.news:
        _navigate(_Page.news);
      case RanahDestination.menu:
        setState(() => _menuOpen = !_menuOpen);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_page == _Page.adminLogin) {
      return AdminLoginPage(
        onBack: () => _navigate(_Page.home),
        onPreview: () => _navigate(_Page.adminPreview),
      );
    }
    if (_page == _Page.adminPreview) {
      return AdminPanelPage(onExit: () => _navigate(_Page.adminLogin));
    }
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              RanahHeader(
                selected:
                    _page == _Page.home ||
                        (_page == _Page.story && _storyReturnPage == _Page.home)
                    ? RanahDestination.home
                    : _page == _Page.map ||
                          _page == _Page.activity ||
                          _page == _Page.volcanoReport
                    ? RanahDestination.map
                    : _page == _Page.news || _page == _Page.story
                    ? RanahDestination.news
                    : RanahDestination.home,
                onSelect: _onDestination,
                onNotifications: _openNotifications,
              ),
              Expanded(
                child: RanahBackground(
                  child: _page == _Page.home
                      ? HomePage(
                          onStoryTap: (story) => _openStory(story, _Page.home),
                        )
                      : _page == _Page.map
                      ? MapPage(
                          onActivityTap: () => _openActivity(_Page.map),
                          onMountainTap: (mountain) =>
                              _openVolcanoReport(mountain.name, _Page.map),
                          onEvacuationRouteTap: () =>
                              _openEvacuationRoute(_Page.map),
                          showLocationDetails: _mapLocationDetails,
                          onLocationDetailsChanged: (show) {
                            _mapLocationDetails = show;
                          },
                          manualPinPosition: _manualMapPinPosition,
                          manualLocationChosen: _manualMapLocationChosen,
                          onManualPinChanged: (position) => setState(() {
                            _manualMapPinPosition = position;
                            _manualMapLocationChosen = true;
                          }),
                        )
                      : _page == _Page.evacuationRoute
                      ? EvacuationRoutePage(
                          onBack: () => _navigate(_routeReturnPage),
                        )
                      : _page == _Page.activity
                      ? VolcanicActivityPage(
                          onBack: () => _navigate(_activityReturnPage),
                          onViewReport: (volcano) =>
                              _openVolcanoReport(volcano.name, _Page.activity),
                        )
                      : _page == _Page.volcanoReport
                      ? VolcanoReportPage(
                          volcano: _selectedVolcano,
                          onBack: () => _navigate(_reportReturnPage),
                        )
                      : _page == _Page.news
                      ? NewsPage(
                          onStoryTap: (story) => _openStory(story, _Page.news),
                        )
                      : _page == _Page.story && _selectedStory != null
                      ? NewsDetailPage(
                          story: _selectedStory!,
                          onBack: () => _navigate(_storyReturnPage),
                        )
                      : _page == _Page.mitigation
                      ? MitigationGuidePage(
                          onBack: () => _navigate(_mitigationReturnPage),
                        )
                      : _page == _Page.notifications
                      ? NotificationsPage(
                          onBack: () => _navigate(_notificationsReturnPage),
                          onNotificationTap: _openNotificationDestination,
                        )
                      : _page == _Page.contact
                      ? EmergencyContactsPage(
                          onBack: () => _navigate(_contactsReturnPage),
                        )
                      : _PlaceholderPage(
                          page: _page,
                          onBack: () => _navigate(_Page.home),
                        ),
                ),
              ),
            ],
          ),
          if (_menuOpen) ...[
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _menuOpen = false),
                child: const SizedBox.expand(),
              ),
            ),
            Positioned(
              top: 48,
              right: 16,
              child: _MenuPopup(
                onContact: _openContacts,
                onMitigation: _openMitigationGuide,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MenuPopup extends StatelessWidget {
  const _MenuPopup({required this.onContact, required this.onMitigation});

  final VoidCallback onContact;
  final VoidCallback onMitigation;

  @override
  Widget build(BuildContext context) => Container(
    width: 190,
    padding: const EdgeInsets.all(4),
    decoration: const BoxDecoration(
      color: Color(0xE9092240),
      boxShadow: [
        BoxShadow(
          color: Color(0x44000000),
          blurRadius: 8,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MenuOption(
          label: 'KONTAK DARURAT',
          color: RanahColors.eruption,
          onTap: onContact,
        ),
        const SizedBox(height: 3),
        _MenuOption(
          label: 'PANDUAN MITIGASI',
          color: const Color(0xFF00695C),
          onTap: onMitigation,
        ),
      ],
    ),
  );
}

class _MenuOption extends StatelessWidget {
  const _MenuOption({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 48,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Container(
            height: 48,
            width: double.infinity,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.page, required this.onBack});

  final _Page page;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final (title, subtitle) = switch (page) {
      _Page.map => ('Peta', 'Halaman peta belum diimplementasikan.'),
      _Page.evacuationRoute => (
        'Jalur Evakuasi',
        'Detail jalur evakuasi tidak tersedia.',
      ),
      _Page.activity => (
        'Laporan Aktivitas Gunung',
        'Daftar aktivitas gunung belum diimplementasikan.',
      ),
      _Page.volcanoReport => (
        'Laporan Gunung',
        'Detail laporan gunung belum diimplementasikan.',
      ),
      _Page.news => ('Berita', 'Halaman berita belum diimplementasikan.'),
      _Page.contact => (
        'Kontak Darurat',
        'Halaman kontak belum diimplementasikan.',
      ),
      _Page.mitigation => (
        'Panduan Mitigasi',
        'Halaman panduan mitigasi belum diimplementasikan.',
      ),
      _Page.notifications => (
        'Notifikasi',
        'Halaman notifikasi belum diimplementasikan.',
      ),
      _Page.story => (
        'Detail Berita',
        'Halaman detail berita belum diimplementasikan.',
      ),
      _Page.home => ('Beranda', ''),
      _Page.adminLogin => ('Masuk Admin', ''),
      _Page.adminPreview => ('Pratinjau Admin', ''),
    };
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: RanahColors.cardBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(subtitle, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Kembali ke Beranda'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
