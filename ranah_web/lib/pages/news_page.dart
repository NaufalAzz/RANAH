import 'package:flutter/material.dart';

import '../data/home_stories.dart';
import '../theme/ranah_theme.dart';
import '../widgets/ranah_full_width_title_background.dart';

const _newsCategories = <String>[
  'Semua',
  'ERUPSI',
  'PENGUNGSIAN',
  'BANTUAN',
];

DateTime _storyDate(HomeStory story) {
  final parts = story.date.split(' ');
  const months = {
    'Januari': 1,
    'Februari': 2,
    'Maret': 3,
    'April': 4,
    'Mei': 5,
    'Juni': 6,
    'Juli': 7,
    'Agustus': 8,
    'September': 9,
    'Oktober': 10,
    'November': 11,
    'Desember': 12,
  };
  return DateTime(int.parse(parts[2]), months[parts[1]]!, int.parse(parts[0]));
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
    onChanged: (value) => onChanged(value == null || value.isEmpty
        ? null
        : DateTime.parse(value)),
  );
}

class NewsPage extends StatefulWidget {
  const NewsPage({required this.onStoryTap, super.key});

  final ValueChanged<HomeStory> onStoryTap;

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  final _searchController = TextEditingController();
  String _query = '';
  String _category = 'Semua';
  DateTime? _dateStart;
  DateTime? _dateEnd;

  List<DateTime> get _dates => newsStories.map(_storyDate).toSet().toList()
    ..sort();

  void _clearFilters() {
    setState(() {
      _query = '';
      _searchController.clear();
      _category = 'Semua';
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
    final filteredStories = newsStories.where((story) {
      final matchesCategory =
          _category == 'Semua' || story.category == _category;
      final date = _storyDate(story);
      final matchesDate =
          (_dateStart == null || !date.isBefore(_dateStart!)) &&
          (_dateEnd == null || !date.isAfter(_dateEnd!));
      final searchableText =
          '${story.title} ${story.summary} ${story.category} ${story.date}'
              .toLowerCase();
      return matchesCategory &&
          matchesDate &&
          searchableText.contains(_query.toLowerCase());
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 600;
        final horizontal = mobile ? 16.0 : 36.0;
        final maxWidth = constraints.maxWidth > 1200
            ? 1200.0
            : constraints.maxWidth;
        return RanahPageScrollLayout(
          maxContentWidth: maxWidth,
          title: NewsPageBanner(maxContentWidth: maxWidth),
          content: Padding(
            padding: EdgeInsets.fromLTRB(horizontal, 10, horizontal, 0),
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
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, filterConstraints) {
                    final narrow = filterConstraints.maxWidth < 520;
                    const gap = 10.0;
                    final categoryWidth = narrow
                        ? filterConstraints.maxWidth
                        : (filterConstraints.maxWidth - gap * 2) / 3;
                    final dateWidth = narrow
                        ? (filterConstraints.maxWidth - gap) / 2
                        : categoryWidth;
                    return Wrap(
                      spacing: gap,
                      runSpacing: 10,
                      children: [
                        SizedBox(
                          width: categoryWidth,
                          height: 56,
                          child: DropdownButtonFormField<String>(
                            key: const ValueKey('web-news-category-filter'),
                            initialValue: _category,
                            isExpanded: true,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            dropdownColor: RanahColors.headerStart,
                            iconEnabledColor: Colors.white70,
                            decoration: _newsFilterDecoration('Kategori'),
                            items: [
                              for (final category in _newsCategories)
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
                          width: dateWidth,
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
                          width: dateWidth,
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
                const SizedBox(height: 22),
                if (filteredStories.isEmpty)
                  const _EmptyNewsState()
                else
                  LayoutBuilder(
                    builder: (context, gridConstraints) {
                      final columns = gridConstraints.maxWidth < 560 ? 1 : 2;
                      final gap = columns == 1 ? 14.0 : 20.0;
                      final cardWidth = columns == 1
                          ? gridConstraints.maxWidth
                          : (gridConstraints.maxWidth - gap) / 2;
                      return Wrap(
                        spacing: gap,
                        runSpacing: 26,
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
            child: Image.asset(story.image, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CONTOH · ${story.category}',
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
  const _EmptyNewsState();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Text(
      'Tidak ada berita demonstrasi yang sesuai.',
      textAlign: TextAlign.center,
      style: TextStyle(color: RanahColors.ink),
    ),
  );
}
