import 'package:ranah_accessibility/ranah_accessibility.dart';
import 'package:flutter/material.dart';

import '../data/home_stories.dart';
import '../services/browser_geolocation.dart';
import '../services/news_repository.dart';
import '../models/gunung_data.dart';
import '../services/gunung_repository.dart';
import '../services/administrative_area_lookup.dart';
import '../services/hazard_analysis_repository.dart';
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
  const RanahShell({
    this.newsRepository,
    this.voiceEngine,
    this.gunungRepository,
    this.locationReader,
    this.areaLookup,
    this.hazardAnalysisRepository,
    this.osmLoader,
    this.volcanoMapTilesEnabled = true,
    super.key,
  });

  final NewsRepository? newsRepository;
  final VoiceEngine? voiceEngine;
  final GunungDataRepository? gunungRepository;
  final BrowserLocationReader? locationReader;
  final AdministrativeAreaLookup? areaLookup;
  final HazardAnalysisRepository? hazardAnalysisRepository;
  final MapOsmReferenceLoader? osmLoader;
  final bool volcanoMapTilesEnabled;

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
  final _Page _routeReturnPage = _Page.map;
  BrowserLocation? _mapLocation;
  BrowserAdministrativeArea? _mapArea;
  bool _mapEverOpened = false;
  GunungRecord? _selectedVolcano;
  HomeStory? _selectedStory;
  late final NewsRepository _newsRepository;
  late final GunungDataRepository _gunungRepository;
  List<HomeStory> _newsStories = const [];
  List<GunungRecord> _gunung = const [];
  bool _newsLoading = true;
  bool _gunungLoading = false;
  bool _gunungLoaded = false;
  String? _newsError;
  String? _gunungError;
  bool _menuOpen = false;

  @override
  void initState() {
    super.initState();
    _newsRepository = widget.newsRepository ?? NewsRepository();
    _gunungRepository = widget.gunungRepository ?? GunungRepository();
    _page = Uri.base.path == '/admin' || Uri.base.path.startsWith('/admin/')
        ? _Page.adminLogin
        : _Page.home;
    _loadNews();
  }

  Future<void> _loadNews() async {
    if (!_newsLoading) {
      setState(() {
        _newsLoading = true;
        _newsError = null;
      });
    }
    try {
      final items = await _newsRepository.load();
      if (!mounted) return;
      setState(() {
        _newsStories = items;
        _newsLoading = false;
        _newsError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _newsLoading = false;
        _newsError = error.toString();
      });
    }
  }

  Future<void> _loadGunung() async {
    if (_gunungLoading) return;
    setState(() {
      _gunungLoading = true;
      _gunungError = null;
    });
    try {
      final records = await _gunungRepository.loadGunung();
      if (!mounted) return;
      setState(() {
        _gunung = records;
        _gunungLoading = false;
        _gunungLoaded = true;
        _gunungError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _gunungLoading = false;
        _gunungError = error.toString();
      });
    }
  }

  @override
  void dispose() {
    _newsRepository.close();
    if (_gunungRepository case final GunungRepository repository) {
      repository.close();
    }
    super.dispose();
  }

  void _navigate(_Page page) {
    setState(() {
      if (page == _Page.map) _mapEverOpened = true;
      _page = page;
      _menuOpen = false;
    });
  }

  void _openVolcanoReport(GunungRecord volcano, _Page returnPage) {
    setState(() {
      _selectedVolcano = volcano;
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
    if (!_gunungLoaded && !_gunungLoading) _loadGunung();
    setState(() {
      _activityReturnPage = returnPage;
      _page = _Page.activity;
      _menuOpen = false;
    });
  }

  void _openContacts() {
    setState(() {
      _contactsReturnPage = _page;
      _page = _Page.contact;
      _menuOpen = false;
    });
  }

  void _onMapAreaChanged(BrowserAdministrativeArea? area) {
    setState(() => _mapArea = area);
    if (area?.province?.isNotEmpty == true &&
        !_gunungLoaded &&
        !_gunungLoading) {
      _loadGunung();
    }
  }

  Future<void> _openVoice() async {
    setState(() => _menuOpen = false);
    final destination = await showVoiceNavigation(
      context,
      engine: widget.voiceEngine,
    );
    if (!mounted || destination == null) return;
    switch (destination) {
      case VoiceDestination.home:
        _navigate(_Page.home);
      case VoiceDestination.map:
        _navigate(_Page.map);
      case VoiceDestination.news:
        _navigate(_Page.news);
      case VoiceDestination.guide:
        _openMitigationGuide();
      case VoiceDestination.contacts:
        _openContacts();
      case VoiceDestination.activity:
        _openActivity(_page);
      case VoiceDestination.notifications:
        _openNotifications();
      case VoiceDestination.menu:
        setState(() => _menuOpen = true);
    }
  }

  void _onDestination(RanahDestination destination) {
    switch (destination) {
      case RanahDestination.home:
        _navigate(_Page.home);
      case RanahDestination.map:
        _navigate(_Page.map);
      case RanahDestination.voice:
        _openVoice();
      case RanahDestination.news:
        _navigate(_Page.news);
      case RanahDestination.menu:
        setState(() => _menuOpen = !_menuOpen);
    }
  }

  RanahDestination get _selectedDestination {
    if (_page == _Page.home ||
        (_page == _Page.story && _storyReturnPage == _Page.home)) {
      return RanahDestination.home;
    }
    if (_page == _Page.map ||
        _page == _Page.activity ||
        _page == _Page.volcanoReport) {
      return RanahDestination.map;
    }
    if (_page == _Page.news || _page == _Page.story) {
      return RanahDestination.news;
    }
    return RanahDestination.home;
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 600;
          final selected = _selectedDestination;
          return Stack(
            children: [
              Column(
                children: [
                  RanahHeader(
                    selected: selected,
                    onSelect: _onDestination,
                    onNotifications: _openNotifications,
                  ),
                  Expanded(
                    child: RanahBackground(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (_mapEverOpened)
                            Positioned.fill(
                              child: Offstage(
                                offstage: _page != _Page.map,
                                child: _buildMapPage(),
                              ),
                            ),
                          if (_page != _Page.map)
                            Positioned.fill(child: _buildOtherPage()),
                        ],
                      ),
                    ),
                  ),
                  if (compact)
                    RanahBottomNavigation(
                      selected: selected,
                      onSelect: _onDestination,
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
                  top: compact ? null : 48,
                  bottom: compact ? 80 : null,
                  right: 16,
                  child: _MenuPopup(
                    onActivity: () => _openActivity(_page),
                    onContact: _openContacts,
                    onMitigation: _openMitigationGuide,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildMapPage() => MapPage(
    onActivityTap: () => _openActivity(_Page.map),
    currentLocation: _mapLocation,
    currentArea: _mapArea,
    onLocationChanged: (location) => setState(() {
      _mapLocation = location;
      if (location == null) _mapArea = null;
    }),
    onAreaChanged: _onMapAreaChanged,
    locationReader: widget.locationReader ?? readBrowserLocation,
    areaLookup: widget.areaLookup ?? lookupBrowserAdministrativeArea,
    hazardAnalysisRepository: widget.hazardAnalysisRepository,
    osmLoader: widget.osmLoader,
    gunung: _gunung,
    gunungLoading: _gunungLoading,
    gunungError: _gunungError,
    onRetryGunung: _loadGunung,
    onOpenReport: (volcano) => _openVolcanoReport(volcano, _Page.map),
    onOpenEvacuation: () => _navigate(_Page.evacuationRoute),
  );

  Widget _buildOtherPage() {
    if (_page == _Page.home) {
      return HomePage(
        onOpenContacts: _openContacts,
        stories: _newsStories,
        isLoading: _newsLoading,
        error: _newsError,
        onRetry: _loadNews,
        onStoryTap: (story) => _openStory(story, _Page.home),
      );
    }
    if (_page == _Page.evacuationRoute) {
      return EvacuationRoutePage(
        onBack: () => _navigate(_routeReturnPage),
        currentLocation: _mapLocation,
      );
    }
    if (_page == _Page.activity) {
      return VolcanicActivityPage(
        onBack: () => _navigate(_activityReturnPage),
        gunung: _gunung,
        isLoading: _gunungLoading,
        error: _gunungError,
        onRetry: _loadGunung,
        onViewReport: (volcano) => _openVolcanoReport(volcano, _Page.activity),
      );
    }
    if (_page == _Page.volcanoReport) {
      return VolcanoReportPage(
        gunungId: _selectedVolcano!.id,
        namaGunung: _selectedVolcano!.nama,
        repository: _gunungRepository,
        tilesEnabled: widget.volcanoMapTilesEnabled,
        onBack: () => _navigate(_reportReturnPage),
      );
    }
    if (_page == _Page.news) {
      return NewsPage(
        stories: _newsStories,
        isLoading: _newsLoading,
        error: _newsError,
        onRetry: _loadNews,
        onStoryTap: (story) => _openStory(story, _Page.news),
      );
    }
    if (_page == _Page.story && _selectedStory != null) {
      return NewsDetailPage(
        story: _selectedStory!,
        onBack: () => _navigate(_storyReturnPage),
      );
    }
    if (_page == _Page.mitigation) {
      return MitigationGuidePage(
        onBack: () => _navigate(_mitigationReturnPage),
      );
    }
    if (_page == _Page.notifications) {
      return NotificationsPage(
        onBack: () => _navigate(_notificationsReturnPage),
      );
    }
    if (_page == _Page.contact) {
      return EmergencyContactsPage(
        onBack: () => _navigate(_contactsReturnPage),
      );
    }
    return _PlaceholderPage(page: _page, onBack: () => _navigate(_Page.home));
  }
}

class _MenuPopup extends StatelessWidget {
  const _MenuPopup({
    required this.onActivity,
    required this.onContact,
    required this.onMitigation,
  });

  final VoidCallback onActivity;
  final VoidCallback onContact;
  final VoidCallback onMitigation;

  @override
  Widget build(BuildContext context) => Container(
    width: MediaQuery.sizeOf(context).width < 352
        ? MediaQuery.sizeOf(context).width - RanahSpacing.xxl
        : 320,
    padding: const EdgeInsets.all(RanahSpacing.md),
    decoration: BoxDecoration(
      color: RanahColors.backgroundMiddle,
      borderRadius: BorderRadius.circular(RanahRadii.md),
      border: Border.all(color: const Color(0xFF537895)),
      boxShadow: [
        BoxShadow(
          color: Color(0x44000000),
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MenuOption(
          icon: Icons.landscape_outlined,
          title: 'Aktivitas Gunung Api',
          description:
              'Lihat daftar gunung dan laporan aktivitas yang tersedia.',
          onTap: onActivity,
        ),
        const SizedBox(height: RanahSpacing.sm),
        _MenuOption(
          icon: Icons.health_and_safety_outlined,
          title: 'Panduan Mitigasi',
          description: 'Langkah sebelum, saat, dan setelah erupsi.',
          onTap: onMitigation,
        ),
        const SizedBox(height: RanahSpacing.sm),
        _MenuOption(
          icon: Icons.phone_in_talk_rounded,
          title: 'Kontak Darurat & Pengaduan',
          description: 'Daftar kontak dan formulir laporan kejadian.',
          onTap: onContact,
        ),
      ],
    ),
  );
}

class _MenuOption extends StatelessWidget {
  const _MenuOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(RanahRadii.md),
    elevation: 2,
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(RanahSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(RanahRadii.md),
          border: Border.all(color: const Color(0xFFE3E9F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFEAE6F7),
                borderRadius: BorderRadius.circular(RanahRadii.sm),
              ),
              child: Icon(icon, color: const Color(0xFF24106B), size: 25),
            ),
            const SizedBox(width: RanahSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF15243A),
                      fontSize: 15,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: RanahSpacing.xs),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Color(0xFF65748A),
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: RanahSpacing.xs),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF65748A)),
          ],
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
              borderRadius: BorderRadius.circular(RanahRadii.md),
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
                RanahBackButton(onPressed: onBack, label: 'Kembali ke Beranda'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
