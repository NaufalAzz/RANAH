import 'package:flutter/material.dart';

import '../data/sample_news.dart';
import '../models/news_item.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/news_artwork.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({super.key, this.initialNewsId, this.selectionRevision = 0});

  final String? initialNewsId;
  final int selectionRevision;

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  static const _categories = ['Semua', 'Erupsi', 'Pengungsian', 'Bantuan'];

  final _searchController = TextEditingController();
  String _query = '';
  String _category = 'Semua';
  NewsItem? _selectedItem;

  @override
  void initState() {
    super.initState();
    _selectNewsById(widget.initialNewsId);
  }

  @override
  void didUpdateWidget(covariant NewsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectionRevision != widget.selectionRevision) {
      _selectNewsById(widget.initialNewsId);
    }
  }

  void _selectNewsById(String? id) {
    if (id == null) return;
    for (final item in sampleNews) {
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
    return sampleNews.where((item) {
      final matchesCategory =
          _category == 'Semua' || item.category == _category;
      final matchesQuery =
          query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.summary.toLowerCase().contains(query) ||
          item.body.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
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
              duration: const Duration(milliseconds: 180),
              child: _selectedItem == null
                  ? _NewsListContent(
                      key: const ValueKey('news-list'),
                      categories: _categories,
                      selectedCategory: _category,
                      searchController: _searchController,
                      items: _filteredNews,
                      onQueryChanged: (value) => setState(() => _query = value),
                      onCategorySelected: (value) =>
                          setState(() => _category = value),
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
    required this.selectedCategory,
    required this.searchController,
    required this.items,
    required this.onQueryChanged,
    required this.onCategorySelected,
    required this.onItemSelected,
    super.key,
  });

  final List<String> categories;
  final String selectedCategory;
  final TextEditingController searchController;
  final List<NewsItem> items;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onCategorySelected;
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
        const Padding(
          padding: EdgeInsets.fromLTRB(18, 14, 18, 6),
          child: Text(
            'FILTER KATEGORI',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        SizedBox(
          height: 36,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final category = categories[index];
              return _CategoryFilterChip(
                label: category,
                selected: category == selectedCategory,
                onTap: () => onCategorySelected(category),
              );
            },
          ),
        ),
        const SizedBox(height: 30),
        if (items.isEmpty)
          const _EmptyNewsResults()
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
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 18, 18, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF29107C), Color(0xFF18064A)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.newspaper_rounded, color: Colors.white, size: 38),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'INFORMASI RANAH',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF8BC8FF),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Berita dan Event',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Informasi terkini seputar bencana',
                  style: TextStyle(color: Color(0xFFD0C9E7), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NewsSearchField extends StatelessWidget {
  const _NewsSearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
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
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: Color(0xFF8BC8FF), width: 2),
          ),
        ),
      ),
    );
  }
}

class _CategoryFilterChip extends StatelessWidget {
  const _CategoryFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : const Color(0xFFE5EAF0),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 36),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF68768A),
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        child: InkWell(
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
                          ?.copyWith(fontSize: 13, height: 1.2),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.summary,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.ink,
                        fontSize: 10,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.publishedAt,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyNewsResults extends StatelessWidget {
  const _EmptyNewsResults();

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
        child: const Text(
          'Berita tidak ditemukan. Coba kata kunci atau kategori lain.',
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
                minimumSize: const Size(48, 40),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                side: const BorderSide(color: Color(0xFFE1E5EA)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Container(
            color: const Color(0xFFF0F2F5),
            child: ListView(
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
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: AppColors.muted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            item.publishedAt,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        item.body,
                        style: Theme.of(context).textTheme.bodyLarge
                            ?.copyWith(fontSize: 15, height: 1.55),
                      ),
                      const SizedBox(height: 18),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Text(
                        'Sumber berita: belum tersedia pada data contoh.',
                        style: Theme.of(context).textTheme.bodySmall,
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
