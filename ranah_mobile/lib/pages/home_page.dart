import 'package:flutter/material.dart';

import '../data/sample_news.dart';
import '../models/news_item.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/app_card_surface.dart';
import '../widgets/news_artwork.dart';
import '../widgets/news_feed_notice.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    required this.onOpenNews,
    this.items = sampleNews,
    this.isUsingFallback = true,
    this.isLoadingNews = false,
    this.isFromCache = false,
    this.cacheWriteFailed = false,
    this.lastSyncedAt,
    super.key,
  });

  final ValueChanged<NewsItem> onOpenNews;
  final List<NewsItem> items;
  final bool isUsingFallback;
  final bool isLoadingNews;
  final bool isFromCache;
  final bool cacheWriteFailed;
  final DateTime? lastSyncedAt;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _featuredIndex = 0;

  @override
  Widget build(BuildContext context) {
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
                NewsFeedNotice(
                  isUsingFallback: widget.isUsingFallback,
                  isLoading: widget.isLoadingNews,
                  isFromCache: widget.isFromCache,
                  cacheWriteFailed: widget.cacheWriteFailed,
                  lastSyncedAt: widget.lastSyncedAt,
                ),
                if (widget.items.isEmpty)
                  const _NoPublishedNews()
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
                const SizedBox(height: AppSpacing.xl),
                Text(
                  widget.isFromCache ? 'Berita Tersimpan' : 'Berita Terbaru',
                  style: AppTypography.sectionTitle.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
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
  const _NoPublishedNews();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Text(
        'Belum ada berita yang dipublikasikan.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white),
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

        return SizedBox(
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
        color: const Color(0xFF123D5B),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFF1D5778)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFF70D2D7),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'RANAH membantu menyajikan informasi. Ikuti arahan resmi petugas kebencanaan.',
              style: AppTypography.bodyCompact.copyWith(
                color: Colors.white,
                height: 1.4,
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
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          NewsArtwork(item: item, featured: true),
          Positioned(
            left: 12,
            top: 11,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: Color(0xFFE83D35),
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                child: Text(
                  leadLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 28,
            right: 28,
            bottom: 13,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.category.toUpperCase(),
                  style: TextStyle(
                    color: item.accent,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    height: 1.12,
                    fontWeight: FontWeight.w800,
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
    backgroundColor: const Color(0x665B5872),
    disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
    disabledBackgroundColor: const Color(0x443C3A4A),
    minimumSize: const Size(
      AppSizes.minimumTapTarget,
      AppSizes.minimumTapTarget,
    ),
    shape: const CircleBorder(),
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
        children: [
          SizedBox(width: 84, child: NewsArtwork(item: item)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CategoryLabel(label: item.category, color: item.accent),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  item.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  item.publishedAt,
                  style: Theme.of(context).textTheme.bodySmall,
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
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        color: color,
        fontSize: 13,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.35,
      ),
    );
  }
}
