import 'package:flutter/material.dart';

import '../data/home_stories.dart';
import '../theme/ranah_theme.dart';
import '../widgets/ranah_full_width_title_background.dart';
import '../widgets/home_story_image.dart';

DateTime? _storyEventDate(HomeStory story) {
  final eventAt = story.eventAt?.toLocal();
  if (eventAt == null) return null;
  return DateTime(eventAt.year, eventAt.month, eventAt.day);
}

String _dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/${date.year}';

InputDecoration _newsFilterDecoration(String label) => InputDecoration(
  labelText: label,
  labelStyle: const TextStyle(color: Color(0xFFD0C9E7)),
  filled: true,
  fillColor: const Color(0x8C123D5B),
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  enabledBorder: const OutlineInputBorder(
    borderSide: BorderSide(color: Color(0x6689A4BA)),
  ),
  focusedBorder: const OutlineInputBorder(
    borderSide: BorderSide(color: Color(0xFF82C7FF), width: 1.5),
  ),
);

class _NewsDateFilter extends StatelessWidget {
  const _NewsDateFilter({
    required this.label,
    required this.selectedDate,
    required this.dates,
    required this.onChanged,
    super.key,
  });

  final String label;
  final DateTime? selectedDate;
  final List<DateTime> dates;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    initialValue: selectedDate == null ? '' : _dateKey(selectedDate!),
    isExpanded: true,
    style: const TextStyle(color: Colors.white, fontSize: 14),
    dropdownColor: RanahColors.headerStart,
    iconEnabledColor: Colors.white70,
    decoration: _newsFilterDecoration(label),
    items: [
      const DropdownMenuItem(value: '', child: Text('Semua tanggal')),
      for (final date in dates)
        DropdownMenuItem(value: _dateKey(date), child: Text(_formatDate(date))),
    ],
    onChanged: (value) => onChanged(
      value == null || value.isEmpty ? null : DateTime.parse(value),
    ),
  );
}

class NewsPage extends StatefulWidget {
  const NewsPage({
    required this.onStoryTap,
    this.stories = newsStories,
    this.isLoading = false,
    this.error,
    this.onRetry,
    super.key,
  });

  final ValueChanged<HomeStory> onStoryTap;
  final List<HomeStory> stories;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  static const _allRegions = '__all_regions__';
  final _searchController = TextEditingController();
  String _query = '';
  String _category = 'Semua';
  String _region = _allRegions;
  DateTime? _dateStart;
  DateTime? _dateEnd;

  List<String> get _categories =>
      ['Semua', ...widget.stories.map((story) => story.category).toSet()]
        ..sort((a, b) {
          if (a == 'Semua') return -1;
          if (b == 'Semua') return 1;
          return a.toLowerCase().compareTo(b.toLowerCase());
        });

  List<String> get _regions =>
      widget.stories
          .map((story) => story.region?.trim() ?? '')
          .where((region) => region.isNotEmpty)
          .toSet()
          .toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

  List<DateTime> get _dates =>
      widget.stories.map(_storyEventDate).whereType<DateTime>().toSet().toList()
        ..sort();

  @override
  void didUpdateWidget(covariant NewsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_categories.contains(_category)) _category = 'Semua';
    if (!_regions.contains(_region)) _region = _allRegions;
    if (_dateStart != null && !_dates.contains(_dateStart)) _dateStart = null;
    if (_dateEnd != null && !_dates.contains(_dateEnd)) _dateEnd = null;
  }

  void _clearFilters() {
    setState(() {
      _query = '';
      _searchController.clear();
      _category = 'Semua';
      _region = _allRegions;
      _dateStart = null;
      _dateEnd = null;
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
    final regions = _regions;
    final activeCategory = categories.contains(_category) ? _category : 'Semua';
    final activeRegion = regions.contains(_region) ? _region : _allRegions;
    final filteredStories = widget.stories.where((story) {
      final matchesCategory =
          activeCategory == 'Semua' || story.category == activeCategory;
      final matchesRegion =
          activeRegion == _allRegions || story.region?.trim() == activeRegion;
      final date = _storyEventDate(story);
      final matchesDate = date == null
          ? _dateStart == null && _dateEnd == null
          : (_dateStart == null || !date.isBefore(_dateStart!)) &&
                (_dateEnd == null || !date.isAfter(_dateEnd!));
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
                      hintStyle: const TextStyle(color: Color(0xFF9AA0A8)),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF9AA0A8),
                        size: 19,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: RanahSpacing.md),
                LayoutBuilder(
                  builder: (context, filterConstraints) {
                    final fourColumns = filterConstraints.maxWidth >= 900;
                    const gap = RanahSpacing.md;
                    final filterWidth = fourColumns
                        ? (filterConstraints.maxWidth - gap * 3) / 4
                        : (filterConstraints.maxWidth - gap) / 2;
                    return Wrap(
                      spacing: gap,
                      runSpacing: RanahSpacing.md,
                      children: [
                        SizedBox(
                          width: filterWidth,
                          height: 56,
                          child: DropdownButtonFormField<String>(
                            key: const ValueKey('web-news-category-filter'),
                            initialValue: activeCategory,
                            isExpanded: true,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            dropdownColor: RanahColors.headerStart,
                            iconEnabledColor: Colors.white70,
                            decoration: _newsFilterDecoration('Kategori'),
                            items: [
                              for (final category in categories)
                                DropdownMenuItem(
                                  value: category,
                                  child: Text(
                                    category == 'Semua'
                                        ? 'Semua kategori'
                                        : category,
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
                          height: 56,
                          child: DropdownButtonFormField<String>(
                            key: const ValueKey('web-news-region-filter'),
                            initialValue: activeRegion,
                            isExpanded: true,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            dropdownColor: RanahColors.headerStart,
                            iconEnabledColor: Colors.white70,
                            decoration: _newsFilterDecoration('Wilayah'),
                            items: [
                              const DropdownMenuItem(
                                value: _allRegions,
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
                              if (value != null) {
                                setState(() => _region = value);
                              }
                            },
                          ),
                        ),
                        SizedBox(
                          width: filterWidth,
                          height: 56,
                          child: _NewsDateFilter(
                            key: const ValueKey('web-news-date-start'),
                            label: 'Dari tanggal',
                            selectedDate: _dateStart,
                            dates: _dates,
                            onChanged: (value) => setState(() {
                              _dateStart = value;
                              if (_dateStart != null &&
                                  _dateEnd != null &&
                                  _dateEnd!.isBefore(_dateStart!)) {
                                _dateEnd = _dateStart;
                              }
                            }),
                          ),
                        ),
                        SizedBox(
                          width: filterWidth,
                          height: 56,
                          child: _NewsDateFilter(
                            key: const ValueKey('web-news-date-end'),
                            label: 'Sampai tanggal',
                            selectedDate: _dateEnd,
                            dates: _dates,
                            onChanged: (value) => setState(() {
                              _dateEnd = value;
                              if (_dateStart != null &&
                                  _dateEnd != null &&
                                  _dateEnd!.isBefore(_dateStart!)) {
                                _dateStart = _dateEnd;
                              }
                            }),
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
      constraints: const BoxConstraints(minHeight: 76),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      color: RanahColors.banner,
      child: const Row(
        children: [
          Icon(Icons.newspaper_rounded, size: 27, color: Colors.white),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'INFORMASI RANAH',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF91A8D0),
                    fontSize: 12,
                    letterSpacing: .5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Berita dan Event',
                  maxLines: 1,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                Text(
                  'Informasi terkini seputar bencana',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Color(0xFFC1C8D7), fontSize: 12),
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
    borderRadius: BorderRadius.circular(8),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  story.isApiRecord
                      ? story.category
                      : 'CONTOH \u00B7 ${story.category}',
                  style: TextStyle(
                    color: RanahColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
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
                const SizedBox(height: 5),
                Text(
                  story.date,
                  style: const TextStyle(
                    color: Color(0xFF647083),
                    fontSize: 12,
                  ),
                ),
              ],
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
      borderRadius: BorderRadius.circular(8),
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
      borderRadius: BorderRadius.circular(8),
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
