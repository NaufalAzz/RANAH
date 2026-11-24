import 'package:flutter/material.dart';
import 'package:ranah_accessibility/ranah_accessibility.dart';

import '../data/home_stories.dart';
import '../theme/ranah_theme.dart';
import '../widgets/ranah_full_width_title_background.dart';
import '../widgets/home_story_image.dart';

const _newsFilterMenuColor = RanahColors.cardBlue;
const _newsFilterOptionStyle = TextStyle(
  color: Color(0xFFF4F7FB),
  fontSize: 14,
  fontWeight: FontWeight.w500,
);

InputDecoration _newsFilterDecoration(String label) => InputDecoration(
  labelText: label,
  labelStyle: const TextStyle(
    color: Color(0xFFF0F4FA),
    fontSize: 13,
    fontWeight: FontWeight.w700,
  ),
  floatingLabelStyle: const TextStyle(
    color: Color(0xFF8FE3F0),
    fontSize: 13,
    fontWeight: FontWeight.w700,
  ),
  filled: true,
  fillColor: const Color(0xFF123D5B),
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(RanahRadii.sm),
    borderSide: const BorderSide(color: Color(0xFF89A4BA)),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(RanahRadii.sm),
    borderSide: const BorderSide(color: Color(0xFF89A4BA), width: 1.2),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(RanahRadii.sm),
    borderSide: const BorderSide(color: Color(0xFF8FE3F0), width: 2),
  ),
);

class NewsPage extends StatefulWidget {
  const NewsPage({
    required this.onStoryTap,
    this.stories = newsStories,
    this.volcanoFilter,
    this.isLoading = false,
    this.error,
    this.onRetry,
    super.key,
  });

  final ValueChanged<HomeStory> onStoryTap;
  final Widget? volcanoFilter;
  final List<HomeStory> stories;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  final _searchController = TextEditingController();
  String _query = '';
  String _category = 'Semua';
  String _region = '';
  DateTimeRange? _range;

  List<String> get _categories => [
    'Semua',
    ...newsCategories(
      widget.stories.map((s) => s.category).where((s) => s != 'Semua'),
      _category == 'Semua' ? '' : _category,
    ),
  ];

  void _clearFilters() {
    setState(() {
      _query = '';
      _searchController.clear();
      _category = 'Semua';
      _region = '';
      _range = null;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = _categories;
    final activeCategory = categories.contains(_category) ? _category : 'Semua';
    final filteredStories = widget.stories.where((story) {
      final matchesCategory =
          activeCategory == 'Semua' || story.category == activeCategory;
      final matchesRegion = newsRegionMatches(story.region, _region);
      final matchesDate = newsDateMatches(
        story.eventAt,
        _range,
        bulletinDays: story.bulletinDays,
      );
      final searchableText =
          '${story.title} ${story.summary} ${story.category} ${story.date} ${story.content} ${story.source ?? ''} ${story.region ?? ''}'
              .toLowerCase();
      return matchesCategory &&
          matchesRegion &&
          matchesDate &&
          searchableText.contains(_query.toLowerCase());
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 600;
        final horizontal = mobile ? 16.0 : 36.0;
        final maxWidth = constraints.maxWidth > RanahLayout.maxContentWidth
            ? RanahLayout.maxContentWidth
            : constraints.maxWidth;
        return RanahPageScrollLayout(
          maxContentWidth: maxWidth,
          title: NewsPageBanner(maxContentWidth: maxWidth),
          content: Padding(
            padding: EdgeInsets.fromLTRB(
              horizontal,
              RanahSpacing.md,
              horizontal,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 48,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value.trim()),
                    style: const TextStyle(
                      color: RanahColors.ink,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Cari berita',
                      hintStyle: const TextStyle(color: RanahColors.muted),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: RanahColors.muted,
                        size: 19,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(RanahRadii.pill),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: RanahSpacing.md),
                LayoutBuilder(
                  builder: (context, filterConstraints) {
                    const gap = RanahSpacing.md;
                    final fields = widget.volcanoFilter == null ? 3 : 4;
                    final columns = filterConstraints.maxWidth >= 930
                        ? fields
                        : filterConstraints.maxWidth >= 570
                        ? 2
                        : 1;
                    final filterWidth =
                        (filterConstraints.maxWidth - gap * (columns - 1)) /
                        columns;
                    return Wrap(
                      spacing: gap,
                      runSpacing: RanahSpacing.md,
                      children: [
                        if (widget.volcanoFilter != null)
                          SizedBox(
                            width: filterWidth,
                            height: 56,
                            child: widget.volcanoFilter,
                          ),
                        SizedBox(
                          width: filterWidth,
                          height: 56,
                          child: DropdownButtonFormField<String>(
                            key: const ValueKey('web-news-category-filter'),
                            initialValue: activeCategory,
                            isExpanded: true,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            dropdownColor: _newsFilterMenuColor,
                            iconEnabledColor: const Color(0xFF8FE3F0),
                            decoration: _newsFilterDecoration('Kategori'),
                            items: [
                              for (final category in categories)
                                DropdownMenuItem(
                                  value: category,
                                  child: Text(
                                    category == 'Semua'
                                        ? 'Semua kategori'
                                        : category,
                                    style: _newsFilterOptionStyle,
                                  ),
                                ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _category = value);
                              }
                            },
                          ),
                        ),
                        SizedBox(
                          width: filterWidth,
                          child: NewsRegionField(
                            key: const ValueKey('web-news-region-filter'),
                            value: _region,
                            locations: widget.stories.map((s) => s.region),
                            onChanged: (value) =>
                                setState(() => _region = value),
                          ),
                        ),
                        SizedBox(
                          width: filterWidth,
                          child: NewsDateRangeField(
                            key: const ValueKey('web-news-date-range'),
                            value: _range,
                            onChanged: (value) =>
                                setState(() => _range = value),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    key: const ValueKey('web-news-clear-filters'),
                    onPressed: _clearFilters,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF91A8D0),
                    ),
                    icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                    label: const Text('Hapus semua filter'),
                  ),
                ),
                const SizedBox(height: RanahSpacing.xl),
                if (widget.isLoading && widget.stories.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(RanahSpacing.xl),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (widget.error != null && widget.stories.isEmpty)
                  _NewsFeedMessage(
                    message: 'Berita belum dapat dimuat: ${widget.error}',
                    onRetry: widget.onRetry,
                  )
                else if (widget.isLoading && widget.stories.isNotEmpty)
                  const LinearProgressIndicator()
                else if (widget.error != null)
                  _NewsFeedMessage(
                    message: 'Pembaruan gagal. Menampilkan data terakhir yang berhasil dimuat.',
                    onRetry: widget.onRetry,
                  )
                else if (widget.stories.isEmpty)
                  const _EmptyNewsState(apiEmpty: true)
                else if (filteredStories.isEmpty)
                  const _EmptyNewsState()
                else
                  LayoutBuilder(
                    builder: (context, gridConstraints) {
                      final columns = gridConstraints.maxWidth < 560
                          ? 1
                          : gridConstraints.maxWidth >= 1240
                          ? 3
                          : 2;
                      final gap = columns == 1 ? 14.0 : 20.0;
                      final cardWidth = columns == 1
                          ? gridConstraints.maxWidth
                          : (gridConstraints.maxWidth - gap * (columns - 1)) /
                                columns;
                      return Wrap(
                        spacing: gap,
                        runSpacing: RanahSpacing.xl,
                        children: [
                          for (final story in filteredStories)
                            SizedBox(
                              width: cardWidth,
                              child: _NewsStoryCard(
                                story: story,
                                onTap: () => widget.onStoryTap(story),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class NewsPageBanner extends StatelessWidget {
  const NewsPageBanner({this.maxContentWidth, super.key});

  final double? maxContentWidth;

  @override
  Widget build(BuildContext context) => RanahFullWidthTitleBackground(
    color: RanahColors.banner,
    maxContentWidth: maxContentWidth,
    child: Container(
      constraints: const BoxConstraints(
        minHeight: RanahPageHeaderStyle.minHeight,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: RanahPageHeaderStyle.horizontalPadding,
        vertical: RanahPageHeaderStyle.verticalPadding,
      ),
      color: RanahColors.banner,
      child: const Row(
        children: [
          Icon(
            Icons.newspaper_rounded,
            size: RanahPageHeaderStyle.iconSize,
            color: Colors.white,
          ),
          SizedBox(width: RanahPageHeaderStyle.iconGap),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'INFORMASI RANAH',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: RanahPageHeaderStyle.kicker,
                ),
                Text(
                  'Berita dan Event',
                  maxLines: 1,
                  style: RanahPageHeaderStyle.title,
                ),
                Text(
                  'Informasi terkini seputar bencana',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: RanahPageHeaderStyle.subtitle,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _NewsStoryCard extends StatelessWidget {
  const _NewsStoryCard({required this.story, required this.onTap});

  final HomeStory story;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(RanahRadii.sm),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 2.95,
            child: HomeStoryImage(story: story, fit: BoxFit.cover),
          ),
          SizedBox(
            height: 158,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    story.isApiRecord
                        ? story.category.toUpperCase()
                        : 'CONTOH \u00B7 ${story.category.toUpperCase()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(story.color),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    story.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: RanahColors.ink,
                      fontSize: 16,
                      height: 1.05,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    story.summary,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: RanahColors.ink,
                      fontSize: 16,
                      height: 1.08,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    story.date,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: RanahColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _EmptyNewsState extends StatelessWidget {
  const _EmptyNewsState({this.apiEmpty = false});

  final bool apiEmpty;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(RanahRadii.sm),
    ),
    child: Text(
      apiEmpty
          ? 'Belum ada berita tersedia dari server.'
          : 'Tidak ada berita yang sesuai dengan filter.',
      textAlign: TextAlign.center,
      style: TextStyle(color: RanahColors.ink),
    ),
  );
}

class _NewsFeedMessage extends StatelessWidget {
  const _NewsFeedMessage({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: RanahColors.cardBlue,
      borderRadius: BorderRadius.circular(RanahRadii.sm),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message, style: const TextStyle(color: Colors.white)),
        if (onRetry != null)
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba lagi'),
          ),
      ],
    ),
  );
}
