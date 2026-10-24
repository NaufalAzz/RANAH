import 'package:flutter/material.dart';

import '../data/home_stories.dart';
import '../theme/ranah_theme.dart';

const _newsCategories = <String>['Semua', 'Erupsi', 'Ngungsi', 'Bantuan'];

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredStories = newsStories.where((story) {
      final categoryKey = switch (_category) {
        'Semua' => null,
        'Ngungsi' => 'PENGUNGSIAN',
        _ => _category.toUpperCase(),
      };
      final matchesCategory =
          categoryKey == null || story.category == categoryKey;
      final searchableText =
          '${story.title} ${story.summary} ${story.category} ${story.date}'
              .toLowerCase();
      return matchesCategory && searchableText.contains(_query.toLowerCase());
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 600;
        final horizontal = mobile ? 16.0 : 36.0;
        final maxWidth = constraints.maxWidth > 1200
            ? 1200.0
            : constraints.maxWidth;
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: maxWidth,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const NewsPageBanner(),
                  Padding(
                    padding: EdgeInsets.fromLTRB(horizontal, 10, horizontal, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 36,
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) =>
                                setState(() => _query = value.trim()),
                            style: const TextStyle(
                              color: RanahColors.ink,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search',
                              hintStyle: const TextStyle(
                                color: Color(0xFF9AA0A8),
                              ),
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
                        const Text(
                          'FILTER',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _CategoryFilterBar(
                          selected: _category,
                          onSelected: (category) =>
                              setState(() => _category = category),
                        ),
                        const SizedBox(height: 22),
                        if (filteredStories.isEmpty)
                          const _EmptyNewsState()
                        else
                          LayoutBuilder(
                            builder: (context, gridConstraints) {
                              final columns = gridConstraints.maxWidth < 560
                                  ? 1
                                  : 2;
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class NewsPageBanner extends StatelessWidget {
  const NewsPageBanner({super.key});

  @override
  Widget build(BuildContext context) => Container(
    height: 66,
    padding: const EdgeInsets.symmetric(horizontal: 18),
    color: RanahColors.banner,
    child: const Row(
      children: [
        Icon(Icons.library_books_rounded, size: 27, color: Colors.white),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DISASTER EVACUATION',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFF91A8D0),
                  fontSize: 9,
                  letterSpacing: .5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'News & Event',
                maxLines: 1,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              Text(
                'Informasi seputar kebencanaan · konten demonstrasi',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Color(0xFFC1C8D7), fontSize: 9),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _CategoryFilterBar extends StatelessWidget {
  const _CategoryFilterBar({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final spacing = constraints.maxWidth >= 356 ? 12.0 : 8.0;
      final chipWidth =
          ((constraints.maxWidth - spacing * (_newsCategories.length - 1)) /
                  _newsCategories.length)
              .clamp(0.0, 80.0);
      return Row(
        children: [
          for (var index = 0; index < _newsCategories.length; index++) ...[
            if (index > 0) SizedBox(width: spacing),
            SizedBox(
              width: chipWidth,
              height: 24,
              child: _CategoryChip(
                label: _newsCategories[index],
                selected: selected == _newsCategories[index],
                onTap: () => onSelected(_newsCategories[index]),
              ),
            ),
          ],
        ],
      );
    },
  );
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? RanahColors.primary : const Color(0xFFE1E7EF),
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Center(
        child: Text(
          label,
          maxLines: 1,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF95A0B0),
            fontSize: 12,
          ),
        ),
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
                    color: Color(story.color),
                    fontSize: 12,
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
                    fontSize: 13,
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
                    fontSize: 12,
                    height: 1.08,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  story.date,
                  style: const TextStyle(
                    color: Color(0xFF647083),
                    fontSize: 10,
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
