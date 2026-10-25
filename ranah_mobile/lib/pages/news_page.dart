import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/sample_news.dart';
import '../models/news_item.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/app_card_surface.dart';
import '../widgets/app_page_banner.dart';
import '../widgets/news_artwork.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({
    super.key,
    this.initialNewsId,
    this.selectionRevision = 0,
    this.items = sampleNews,
  });

  final String? initialNewsId;
  final int selectionRevision;
  final List<NewsItem> items;

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  static const _allCategories = '__all_categories__';
  static const _allRegions = '__all_regions__';

  final _searchController = TextEditingController();
  String _query = '';
  String _category = _allCategories;
  String _region = _allRegions;
  DateTime? _dateStart;
  DateTime? _dateEnd;
  NewsItem? _selectedItem;

  List<String> get _categories =>
      widget.items
          .map((item) => item.category.trim())
          .where((category) => category.isNotEmpty)
          .toSet()
          .toList()
        ..sort(
          (first, second) =>
              first.toLowerCase().compareTo(second.toLowerCase()),
        );

  List<String> get _regions =>
      widget.items
          .map((item) => item.region?.trim() ?? '')
          .where((region) => region.isNotEmpty)
          .toSet()
          .toList()
        ..sort(
          (first, second) =>
              first.toLowerCase().compareTo(second.toLowerCase()),
        );

  List<DateTime> get _eventDates =>
      widget.items
          .map((item) => item.eventAt?.toLocal())
          .whereType<DateTime>()
          .map((date) => DateTime(date.year, date.month, date.day))
          .toSet()
          .toList()
        ..sort();

  @override
  void initState() {
    super.initState();
    _selectNewsById(widget.initialNewsId);
  }

  @override
  void didUpdateWidget(covariant NewsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectionRevision != widget.selectionRevision ||
        oldWidget.items != widget.items) {
      _selectNewsById(widget.initialNewsId);
      if (!_categories.contains(_category)) _category = _allCategories;
      if (!_regions.contains(_region)) _region = _allRegions;
      if (!_eventDates.contains(_dateStart)) _dateStart = null;
      if (!_eventDates.contains(_dateEnd)) _dateEnd = null;
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
      final matchesRegion = _region == _allRegions || item.region == _region;
      final eventDate = item.eventAt?.toLocal();
      final matchesDate =
          (_dateStart == null ||
              (eventDate != null && !eventDate.isBefore(_dateStart!))) &&
          (_dateEnd == null ||
              (eventDate != null && !eventDate.isAfter(_dateEnd!)));
      final matchesQuery =
          query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.summary.toLowerCase().contains(query) ||
          item.body.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query);
      return matchesCategory && matchesRegion && matchesDate && matchesQuery;
    }).toList();
  }

  void _selectStartDate(String value) {
    setState(() {
      _dateStart = value.isEmpty ? null : DateTime.parse(value);
      if (_dateStart != null &&
          _dateEnd != null &&
          _dateEnd!.isBefore(_dateStart!)) {
        _dateEnd = _dateStart;
      }
    });
  }

  void _selectEndDate(String value) {
    setState(() {
      _dateEnd = value.isEmpty ? null : DateTime.parse(value);
      if (_dateStart != null &&
          _dateEnd != null &&
          _dateEnd!.isBefore(_dateStart!)) {
        _dateStart = _dateEnd;
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _query = '';
      _searchController.clear();
      _category = _allCategories;
      _region = _allRegions;
      _dateStart = null;
      _dateEnd = null;
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
            child: AnimatedSwitcher(
              duration: MediaQuery.of(context).disableAnimations
                  ? Duration.zero
                  : const Duration(milliseconds: 240),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.025, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: _selectedItem == null
                  ? _NewsListContent(
                      key: const ValueKey('news-list'),
                      categories: _categories,
                      regions: _regions,
                      selectedCategory: _category,
                      selectedRegion: _region,
                      dateOptions: _eventDates,
                      selectedStartDate: _dateStart,
                      selectedEndDate: _dateEnd,
                      searchController: _searchController,
                      items: _filteredNews,
                      hasPublishedNews: widget.items.isNotEmpty,
                      onQueryChanged: (value) => setState(() => _query = value),
                      onCategorySelected: (value) =>
                          setState(() => _category = value),
                      onRegionSelected: (value) =>
                          setState(() => _region = value),
                      onStartDateSelected: _selectStartDate,
                      onEndDateSelected: _selectEndDate,
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

String _formatDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/'
    '${value.month.toString().padLeft(2, '0')}/${value.year}';

String _dateKey(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';

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

class _DateFilterDropdown extends StatelessWidget {
  const _DateFilterDropdown({
    required this.label,
    required this.selectedDate,
    required this.dates,
    required this.onChanged,
    super.key,
  });

  final String label;
  final DateTime? selectedDate;
  final List<DateTime> dates;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final value = selectedDate == null ? '' : _dateKey(selectedDate!);
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      dropdownColor: AppColors.darkPanel,
      iconEnabledColor: Colors.white70,
      decoration: _filterDecoration(label),
      items: [
        DropdownMenuItem(
          value: '',
          child: Text(
            dates.isEmpty ? 'Tanggal belum tersedia' : 'Semua tanggal',
          ),
        ),
        for (final date in dates)
          DropdownMenuItem(
            value: _dateKey(date),
            child: Text(_formatDate(date)),
          ),
      ],
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _NewsListContent extends StatelessWidget {
  const _NewsListContent({
    required this.categories,
    required this.regions,
    required this.selectedCategory,
    required this.selectedRegion,
    required this.dateOptions,
    required this.selectedStartDate,
    required this.selectedEndDate,
    required this.searchController,
    required this.items,
    required this.hasPublishedNews,
    required this.onQueryChanged,
    required this.onCategorySelected,
    required this.onRegionSelected,
    required this.onStartDateSelected,
    required this.onEndDateSelected,
    required this.onClearFilters,
    required this.onItemSelected,
    super.key,
  });

  final List<String> categories;
  final List<String> regions;
  final String selectedCategory;
  final String selectedRegion;
  final List<DateTime> dateOptions;
  final DateTime? selectedStartDate;
  final DateTime? selectedEndDate;
  final TextEditingController searchController;
  final List<NewsItem> items;
  final bool hasPublishedNews;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onCategorySelected;
  final ValueChanged<String> onRegionSelected;
  final ValueChanged<String> onStartDateSelected;
  final ValueChanged<String> onEndDateSelected;
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
                child: DropdownButtonFormField<String>(
                  key: const ValueKey('news-region-filter'),
                  initialValue: selectedRegion,
                  isExpanded: true,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  dropdownColor: AppColors.darkPanel,
                  iconEnabledColor: Colors.white70,
                  decoration: _filterDecoration('Wilayah'),
                  items: [
                    const DropdownMenuItem(
                      value: _NewsPageState._allRegions,
                      child: Text('Semua wilayah'),
                    ),
                    for (final region in regions)
                      DropdownMenuItem(
                        value: region,
                        child: Text(
                          region,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) onRegionSelected(value);
                  },
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
          child: Row(
            children: [
              Expanded(
                child: _DateFilterDropdown(
                  key: const ValueKey('news-date-start'),
                  label: 'Dari tanggal',
                  selectedDate: selectedStartDate,
                  dates: dateOptions,
                  onChanged: onStartDateSelected,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DateFilterDropdown(
                  key: const ValueKey('news-date-end'),
                  label: 'Sampai tanggal',
                  selectedDate: selectedEndDate,
                  dates: dateOptions,
                  onChanged: onEndDateSelected,
                ),
              ),
            ],
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
          _EmptyNewsResults(hasPublishedNews: hasPublishedNews)
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
              aspectRatio: 2.3,
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
  const _EmptyNewsResults({required this.hasPublishedNews});

  final bool hasPublishedNews;

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
        child: Text(
          hasPublishedNews
              ? 'Berita tidak ditemukan. Coba kata kunci atau kategori lain.'
              : 'Belum ada berita yang dipublikasikan.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, fontSize: 14),
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
          color: const Color(0xFFF0F2F5),
          child: Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Kembali'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.ink,
                backgroundColor: Colors.white,
                minimumSize: const Size(48, AppSizes.minimumTapTarget),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.control),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Container(
            color: const Color(0xFFF0F2F5),
            child: ListView(
              key: const PageStorageKey('news-detail-scroll'),
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
              children: [
                AspectRatio(
                  aspectRatio: 1.8,
                  child: NewsArtwork(item: item, featured: true),
                ),
                Container(
                  width: double.infinity,
                  color: Colors.white,
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
                            ?.copyWith(fontSize: 20, height: 1.18),
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
                      if (item.sourceUrl != null)
                        TextButton.icon(
                          onPressed: () =>
                              _openSource(context, item.sourceUrl!),
                          icon: const Icon(Icons.open_in_new, size: 16),
                          label: Text('Sumber resmi: ${_displaySource(item)}'),
                        )
                      else
                        Text(
                          item.source == null
                              ? 'Sumber berita: belum dicantumkan.'
                              : 'Sumber berita: ${_displaySource(item)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      const SizedBox(height: 12),
                      Text(
                        item.body,
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

Future<void> _openSource(BuildContext context, String value) async {
  final uri = Uri.tryParse(value);
  if (uri == null || uri.scheme != 'https' || !uri.hasAuthority) return;
  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tautan sumber tidak dapat dibuka.')),
    );
  }
}
