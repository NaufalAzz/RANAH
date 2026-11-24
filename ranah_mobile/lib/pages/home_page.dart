import 'package:ranah_accessibility/ranah_accessibility.dart';

import '../data/sample_emergency_contacts.dart';

import 'package:flutter/material.dart';

import '../models/news_item.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/app_card_surface.dart';
import '../widgets/news_artwork.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    required this.onOpenNews,
    this.onOpenContacts,
    this.items = const [],
    this.isUsingFallback = false,
    this.isFromCache = false,
    this.loadError,
    this.isLoading = false,
    this.onRetry,
    super.key,
  });

  final VoidCallback? onOpenContacts;

  final ValueChanged<NewsItem> onOpenNews;
  final List<NewsItem> items;
  final bool isUsingFallback;
  final bool isFromCache;
  final Object? loadError;
  final bool isLoading;
  final VoidCallback? onRetry;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _featuredIndex = 0;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: padangContactRegion,
    builder: (context, _, _) => _contactContent(context),
  );

  Widget _contactContent(BuildContext context) {
    final featuredIndex = _featuredIndex < widget.items.length
        ? _featuredIndex
        : 0;
    final latest = [
      for (var index = 0; index < widget.items.length; index++)
        if (index != featuredIndex) widget.items[index],
    ];

    return DecoratedBox(
      decoration: AppBackground.decoration,
      child: Stack(
        children: [
          const Positioned(
            right: -150,
            top: 100,
            child: _HomeBackgroundRing(size: 330),
          ),
          const Positioned(
            left: -210,
            bottom: 90,
            child: _HomeBackgroundRing(size: 360),
          ),
          Positioned.fill(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xs,
                AppSpacing.lg,
                AppSpacing.xs,
                AppSpacing.xl,
              ),
              children: [
                EmergencyContactsCard(
                  onOpenAll: widget.onOpenContacts,
                  contacts: [
                    for (final contact in sampleEmergencyContacts.take(3))
                      QuickEmergencyContact(
                        name: contact.organization,
                        icon: contact.icon,
                        numbers: contact.dialNumbers,
                        verified: contact.numberVerified,
                        source:
                            '${contact.sourceTitle} (${contact.sourceOrganization}), diakses ${contact.sourceAccessedAt}.\n${contact.sourceUrl}',
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (widget.items.isEmpty)
                  _NoPublishedNews(
                    loadError: widget.loadError,
                    isLoading: widget.isLoading,
                    onRetry: widget.onRetry,
                  )
                else
                  _FeaturedNewsCarousel(
                    items: widget.items,
                    leadLabel: widget.isUsingFallback
                        ? 'Berita Utama'
                        : widget.isFromCache
                        ? 'Berita Tersimpan'
                        : 'Berita Terbaru',
                    onTap: widget.onOpenNews,
                    onIndexChanged: (index) =>
                        setState(() => _featuredIndex = index),
                  ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C6FF),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: const [
                          BoxShadow(color: Color(0x6600C6FF), blurRadius: 6),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.isFromCache
                          ? 'Berita Tersimpan'
                          : 'Berita Terbaru',
                      style: AppTypography.sectionTitle.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final item in latest) ...[
                  _LatestNewsCard(item: item, onTap: widget.onOpenNews),
                  const SizedBox(height: AppSpacing.md),
                ],
                const SizedBox(height: 4),
                const _SafetyNote(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeBackgroundRing extends StatelessWidget {
  const _HomeBackgroundRing({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppBackground.ringColor,
            width: AppBackground.ringWidth,
          ),
        ),
      ),
    );
  }
}

class _NoPublishedNews extends StatelessWidget {
  const _NoPublishedNews({
    this.loadError,
    this.isLoading = false,
    this.onRetry,
  });

  final Object? loadError;
  final bool isLoading;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            isLoading
                ? 'Memuat berita dari server...'
                : loadError == null
                ? 'Belum ada berita yang dipublikasikan.'
                : 'Berita belum dapat dimuat dari server. Periksa koneksi lalu coba lagi.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(),
            )
          else if (loadError != null && onRetry != null)
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
            ),
        ],
      ),
    );
  }
}

class _FeaturedNewsCarousel extends StatefulWidget {
  const _FeaturedNewsCarousel({
    required this.items,
    required this.leadLabel,
    required this.onTap,
    required this.onIndexChanged,
  });

  final List<NewsItem> items;
  final String leadLabel;
  final ValueChanged<NewsItem> onTap;
  final ValueChanged<int> onIndexChanged;

  @override
  State<_FeaturedNewsCarousel> createState() => _FeaturedNewsCarouselState();
}

class _FeaturedNewsCarouselState extends State<_FeaturedNewsCarousel> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showPrevious() {
    if (_currentIndex == 0) return;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _showNext() {
    if (_currentIndex >= widget.items.length - 1) return;
    _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final carouselHeight = constraints.maxWidth / 1.78;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: carouselHeight,
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.items.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                  widget.onIndexChanged(index);
                },
                itemBuilder: (context, index) => _FeaturedNewsCard(
                  item: widget.items[index],
                  leadLabel: widget.leadLabel,
                  onTap: () => widget.onTap(widget.items[index]),
                  canGoPrevious: index > 0,
                  canGoNext: index < widget.items.length - 1,
                  onPrevious: _showPrevious,
                  onNext: _showNext,
                ),
              ),
            ),
            if (widget.items.length > 1) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < widget.items.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _currentIndex ? 22 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _currentIndex
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

class _SafetyNote extends StatelessWidget {
  const _SafetyNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2C44).withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1D5778).withValues(alpha: 0.8),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF70D2D7).withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF70D2D7).withValues(alpha: 0.35),
              ),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFF70D2D7),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'RANAH membantu menyajikan informasi. Ikuti arahan resmi petugas kebencanaan.',
              style: AppTypography.bodyCompact.copyWith(
                color: const Color(0xFFE1EDF5),
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedNewsCard extends StatelessWidget {
  const _FeaturedNewsCard({
    required this.item,
    required this.leadLabel,
    required this.onTap,
    required this.canGoPrevious,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
  });

  final NewsItem item;
  final String leadLabel;
  final VoidCallback onTap;
  final bool canGoPrevious;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return AppCardSurface(
      variant: AppCardVariant.news,
      showBorder: false,
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          NewsArtwork(item: item, featured: true),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Color(0x55000000),
                  Color(0xDD0A051C),
                ],
                stops: [0.35, 0.65, 1.0],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            left: 12,
            top: 11,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE53935), Color(0xFFC62828)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.all(Radius.circular(20)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x55E53935),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                child: Text(
                  leadLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: item.accent.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: item.accent.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Text(
                    item.category.toUpperCase(),
                    style: TextStyle(
                      color: item.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17.5,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    shadows: [
                      Shadow(
                        color: Color(0x99000000),
                        blurRadius: 6,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton(
                onPressed: canGoPrevious ? onPrevious : null,
                tooltip: 'Berita utama sebelumnya',
                style: _carouselArrowStyle(),
                icon: const Icon(Icons.chevron_left_rounded, size: 23),
              ),
            ),
          ),
          Positioned(
            right: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton(
                onPressed: canGoNext ? onNext : null,
                tooltip: 'Berita utama berikutnya',
                style: _carouselArrowStyle(),
                icon: const Icon(Icons.chevron_right_rounded, size: 23),
              ),
            ),
          ),
        ],
      ),
    );
  }

  ButtonStyle _carouselArrowStyle() => IconButton.styleFrom(
    foregroundColor: Colors.white,
    backgroundColor: const Color(0x6615083B),
    disabledForegroundColor: Colors.white.withValues(alpha: 0.25),
    disabledBackgroundColor: const Color(0x2215083B),
    minimumSize: const Size(
      AppSizes.minimumTapTarget,
      AppSizes.minimumTapTarget,
    ),
    shape: const CircleBorder(
      side: BorderSide(color: Color(0x2EFFFFFF), width: 1.0),
    ),
  );
}

class _LatestNewsCard extends StatelessWidget {
  const _LatestNewsCard({required this.item, required this.onTap});

  final NewsItem item;
  final ValueChanged<NewsItem> onTap;

  @override
  Widget build(BuildContext context) {
    return AppCardSurface(
      variant: AppCardVariant.news,
      onTap: () => onTap(item),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 88,
              height: 88,
              child: NewsArtwork(item: item),
            ),
          ),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _CategoryLabel(label: item.category, color: item.accent),
                const SizedBox(height: 4),
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 13,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.timeLabel ?? 'Tanggal kejadian belum tersedia',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryLabel extends StatelessWidget {
  const _CategoryLabel({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.28), width: 1.0),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
