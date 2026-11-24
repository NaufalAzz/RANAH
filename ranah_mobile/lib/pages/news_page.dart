import 'package:flutter/material.dart';
import 'package:ranah_accessibility/ranah_accessibility.dart';

import '../models/news_item.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/app_card_surface.dart';
import '../widgets/app_page_banner.dart';
import '../widgets/news_artwork.dart';
import '../widgets/page_motion.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({
    super.key,
    this.initialNewsId,
    this.selectionRevision = 0,
    this.items = const [],
    this.volcanoFilter,
    this.loadError,
    this.isLoading = false,
    this.onRetry,
  });

  final String? initialNewsId;
  final int selectionRevision;
  final Widget? volcanoFilter;
  final List<NewsItem> items;
  final Object? loadError;
  final bool isLoading;
  final VoidCallback? onRetry;

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  static const _allCategories = '__all_categories__';

  final _searchController = TextEditingController();
  String _query = '';
  String _category = _allCategories;
  String _region = '';
  DateTimeRange? _range;
  NewsItem? _selectedItem;

  List<String> get _categories => newsCategories(
    widget.items.map((s) => s.category),
    _category == _allCategories ? '' : _category,
  );

  @override
  void initState() {
    super.initState();
    _selectNewsById(widget.initialNewsId);
  }

  @override
  void didUpdateWidget(covariant NewsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectionRevision != widget.selectionRevision ||
        oldWidget.initialNewsId != widget.initialNewsId) {
      _selectNewsById(widget.initialNewsId);
    } else if (oldWidget.items != widget.items) {
      _selectNewsById(
        _selectedItem?.id ??
            (oldWidget.items.isEmpty ? widget.initialNewsId : null),
      );
    }
  }

  void _selectNewsById(String? id) {
    _selectedItem = null;
    if (id == null) return;
    for (final item in widget.items) {
      if (item.id == id) {
        _selectedItem = item;
        return;
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<NewsItem> get _filteredNews {
    final query = _query.trim().toLowerCase();
    return widget.items.where((item) {
      final matchesCategory =
          _category == _allCategories || item.category == _category;
      final matchesRegion = newsRegionMatches(item.region, _region);
      final matchesDate = newsDateMatches(
        item.eventAt,
        _range,
        bulletinDays: item.bulletinDays,
      );
      final matchesQuery =
          query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.summary.toLowerCase().contains(query) ||
          item.body.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query);
      return matchesCategory && matchesRegion && matchesDate && matchesQuery;
    }).toList();
  }

  void _clearFilters() {
    setState(() {
      _query = '';
      _searchController.clear();
      _category = _allCategories;
      _region = '';
      _range = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppBackground.decoration,
      child: Stack(
        children: [
          const Positioned(
            right: -150,
            top: 130,
            child: _NewsBackgroundRing(size: 330),
          ),
          Positioned.fill(
            child: RanahPageSwitcher(
              rootPageKey: const ValueKey('news-list'),
              child: _selectedItem == null
                  ? _NewsListContent(
                      key: const ValueKey('news-list'),
                      volcanoFilter: widget.volcanoFilter,
                      categories: _categories,
                      regions: widget.items.map((item) => item.region),
                      selectedCategory: _category,
                      selectedRegion: _region,
                      range: _range,
                      searchController: _searchController,
                      items: _filteredNews,
                      hasPublishedNews: widget.items.isNotEmpty,
                      loadError: widget.loadError,
                      isLoading: widget.isLoading,
                      onRetry: widget.onRetry,
                      onQueryChanged: (value) => setState(() => _query = value),
                      onCategorySelected: (value) =>
                          setState(() => _category = value),
                      onRegionSelected: (value) =>
                          setState(() => _region = value),
                      onRangeSelected: (value) =>
                          setState(() => _range = value),
                      onClearFilters: _clearFilters,
                      onItemSelected: (item) =>
                          setState(() => _selectedItem = item),
                    )
                  : _NewsDetailContent(
                      key: ValueKey('news-detail-${_selectedItem!.title}'),
                      item: _selectedItem!,
                      onBack: () => setState(() => _selectedItem = null),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _filterDecoration(String label) => InputDecoration(
  labelText: label,
  labelStyle: const TextStyle(color: AppColors.mutedOnDark),
  filled: true,
  fillColor: const Color(0x8C123D5B),
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  enabledBorder: const OutlineInputBorder(
    borderSide: BorderSide(color: Color(0x6689A4BA)),
  ),
  focusedBorder: const OutlineInputBorder(
    borderSide: BorderSide(color: AppColors.bannerEyebrow, width: 1.5),
  ),
);

class _NewsBackgroundRing extends StatelessWidget {
  const _NewsBackgroundRing({required this.size});

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
            color: Colors.white.withValues(alpha: 0.035),
            width: 28,
          ),
        ),
      ),
    );
  }
}

class _NewsListContent extends StatelessWidget {
  const _NewsListContent({
    required this.categories,
    required this.regions,
    required this.selectedCategory,
    required this.selectedRegion,
    required this.range,
    required this.searchController,
    required this.items,
    required this.hasPublishedNews,
    this.volcanoFilter,
    required this.loadError,
    required this.isLoading,
    required this.onRetry,
    required this.onQueryChanged,
    required this.onCategorySelected,
    required this.onRegionSelected,
    required this.onRangeSelected,
    required this.onClearFilters,
    required this.onItemSelected,
    super.key,
  });

  final List<String> categories;
  final Iterable<String?> regions;
  final String selectedCategory;
  final String selectedRegion;
  final DateTimeRange? range;
  final TextEditingController searchController;
  final List<NewsItem> items;
  final bool hasPublishedNews;
  final Widget? volcanoFilter;
  final Object? loadError;
  final bool isLoading;
  final VoidCallback? onRetry;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onCategorySelected;
  final ValueChanged<String> onRegionSelected;
  final ValueChanged<DateTimeRange> onRangeSelected;
  final VoidCallback onClearFilters;
  final ValueChanged<NewsItem> onItemSelected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const PageStorageKey('news-list-scroll'),
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
      children: [
        const _NewsSectionBanner(),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
          child: _NewsSearchField(
            controller: searchController,
            onChanged: onQueryChanged,
          ),
        ),
        if (volcanoFilter != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: volcanoFilter,
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: const ValueKey('news-category-filter'),
                  initialValue: selectedCategory,
                  isExpanded: true,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  dropdownColor: AppColors.darkPanel,
                  iconEnabledColor: Colors.white70,
                  decoration: _filterDecoration('Kategori'),
                  items: [
                    const DropdownMenuItem(
                      value: _NewsPageState._allCategories,
                      child: Text('Semua kategori'),
                    ),
                    for (final category in categories)
                      DropdownMenuItem(value: category, child: Text(category)),
                  ],
                  onChanged: (value) {
                    if (value != null) onCategorySelected(value);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: NewsRegionField(
                  key: const ValueKey('news-region-filter'),
                  value: selectedRegion,
                  locations: regions,
                  onChanged: onRegionSelected,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
          child: NewsDateRangeField(
            key: const ValueKey('news-date-range'),
            value: range,
            onChanged: onRangeSelected,
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            key: const ValueKey('news-clear-filters'),
            onPressed: onClearFilters,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.bannerEyebrow,
            ),
            icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
            label: const Text('Hapus semua filter'),
          ),
        ),
        const SizedBox(height: 30),
        if (items.isEmpty)
          _EmptyNewsResults(
            hasPublishedNews: hasPublishedNews,
            loadError: loadError,
            isLoading: isLoading,
            onRetry: onRetry,
          )
        else
          for (final item in items) ...[
            _NewsArticleCard(item: item, onTap: () => onItemSelected(item)),
            const SizedBox(height: 36),
          ],
      ],
    );
  }
}

class _NewsSectionBanner extends StatelessWidget {
  const _NewsSectionBanner();

  @override
  Widget build(BuildContext context) => AppPageBanner(
    icon: Icons.newspaper_rounded,
    eyebrow: 'INFORMASI RANAH',
    title: 'Berita dan Event',
    subtitle: 'Informasi terkini seputar bencana',
    minHeight: AppSizes.pageBannerMinHeight,
    padding: EdgeInsets.fromLTRB(
      AppSpacing.xl,
      AppSpacing.md,
      AppSpacing.md,
      AppSpacing.md,
    ),
    iconSize: 38,
    iconGap: AppSpacing.lg,
    gradient: AppGradients.sectionBanner,
    eyebrowStyle: TextStyle(
      color: AppColors.bannerEyebrow,
      fontSize: 13,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.1,
    ),
    titleStyle: AppTypography.pageTitle.copyWith(
      color: AppColors.onDark,
      fontSize: 20,
      height: 1.1,
      fontWeight: FontWeight.w800,
    ),
  );
}

class _NewsSearchField extends StatelessWidget {
  const _NewsSearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.minimumTapTarget,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Cari berita...',
          hintStyle: const TextStyle(color: Color(0xFF8A8A8A), fontSize: 14),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF888888),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            borderSide: const BorderSide(color: Color(0xFF8BC8FF), width: 2),
          ),
        ),
      ),
    );
  }
}

class _NewsArticleCard extends StatelessWidget {
  const _NewsArticleCard({required this.item, required this.onTap});

  final NewsItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: AppCardSurface(
        variant: AppCardVariant.news,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: item.imageUrl == null ? 5.6 : 2.3,
              child: NewsArtwork(item: item, featured: true),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.category.toUpperCase(),
                    style: TextStyle(
                      color: item.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontSize: 18, height: 1.25),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.summary,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.ink,
                      fontSize: 13,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 5),
                  if (item.timeLabel != null)
                    Text(
                      item.timeLabel!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyNewsResults extends StatelessWidget {
  const _EmptyNewsResults({
    required this.hasPublishedNews,
    this.loadError,
    this.isLoading = false,
    this.onRetry,
  });

  final bool hasPublishedNews;
  final Object? loadError;
  final bool isLoading;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Column(
          children: [
            Text(
              isLoading
                  ? 'Memuat berita dari server...'
                  : loadError != null
                  ? 'Berita belum dapat dimuat dari server. Periksa koneksi lalu coba lagi.'
                  : hasPublishedNews
                  ? 'Berita tidak ditemukan. Coba kata kunci atau kategori lain.'
                  : 'Belum ada berita yang dipublikasikan.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 14),
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
      ),
    );
  }
}

class _NewsDetailContent extends StatelessWidget {
  const _NewsDetailContent({
    required this.item,
    required this.onBack,
    super.key,
  });

  final NewsItem item;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _NewsSectionBanner(),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          color: AppColors.darkPanel,
          child: Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Kembali'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: AppColors.darkPanel,
                minimumSize: const Size(48, AppSizes.minimumTapTarget),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                side: const BorderSide(color: AppColors.darkPanelBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.control),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Container(
            color: const Color(0xFF132F45),
            child: ListView(
              key: const PageStorageKey('news-detail-scroll'),
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
              children: [
                if (item.imageUrl != null)
                  AspectRatio(
                    aspectRatio: 1.8,
                    child: NewsArtwork(item: item, featured: true),
                  ),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(10, 12, 10, 0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F6F8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.category.toUpperCase(),
                        style: TextStyle(
                          color: item.accent,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontSize: 22, height: 1.24),
                      ),
                      const SizedBox(height: 5),
                      if (!(item.source?.toUpperCase().contains('BNPB') ??
                              false) &&
                          item.publishedAt.isNotEmpty)
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 14,
                              color: AppColors.muted,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                item.publishedAt,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 8),
                      if (item.timeLabel != null)
                        Text(
                          item.timeLabel!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      if (item.expiresAt != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          'Berakhir: ${_formatSourceDate(item.expiresAt!)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      if (item.region != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          'Wilayah: ${item.region}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      if (item.retrievedAt != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          'Data diambil: ${_formatSourceDate(item.retrievedAt!)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      const SizedBox(height: 8),
                      if (item.author != null)
                        Text(
                          'Penulis: ${item.author}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      if (item.imageUrl != null && item.imageCaption != null)
                        Text(
                          item.imageCaption!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      Text(
                        'Sumber: ${_displaySource(item)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        readableNewsBody(item.title, item.body),
                        style: Theme.of(context).textTheme.bodyLarge
                            ?.copyWith(fontSize: 16, height: 1.55),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

String _formatSourceDate(DateTime value) {
  final local = value.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/${local.year} '
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

String _displaySource(NewsItem item) =>
    item.source?.toUpperCase().contains('BNPB') ?? false
    ? 'BNPB'
    : item.source ?? 'belum dicantumkan';
