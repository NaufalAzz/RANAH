import 'package:flutter/material.dart';

import '../data/home_stories.dart';
import '../theme/ranah_theme.dart';
import '../widgets/home_story_image.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    required this.onStoryTap,
    this.stories = homeStories,
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
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _highlightIndex = 0;

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.stories.isEmpty) {
      _highlightIndex = 0;
    } else if (_highlightIndex >= widget.stories.length) {
      _highlightIndex = widget.stories.length - 1;
    }
  }

  void _moveHighlight(int amount) {
    if (widget.stories.length < 2) return;
    setState(() {
      _highlightIndex =
          (_highlightIndex + amount + widget.stories.length) %
          widget.stories.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 560;
        final horizontalInset = mobile
            ? 18.0
            : (constraints.maxWidth < 760 ? 26.0 : 40.0);
        final contentWidth = constraints.maxWidth > RanahLayout.maxContentWidth
            ? RanahLayout.maxContentWidth
            : constraints.maxWidth;
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: contentWidth,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalInset,
                mobile ? RanahSpacing.lg : RanahSpacing.xl,
                horizontalInset,
                RanahSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroCard(
                    story: widget.stories.isEmpty
                        ? null
                        : widget.stories[_highlightIndex],
                    isLoading: widget.isLoading,
                    error: widget.error,
                    onRetry: widget.onRetry,
                    onPrevious: () => _moveHighlight(-1),
                    onNext: () => _moveHighlight(1),
                    onTap: widget.stories.isEmpty
                        ? null
                        : () => widget.onStoryTap(
                            widget.stories[_highlightIndex],
                          ),
                  ),
                  const SizedBox(height: RanahSpacing.xl),
                  const Text(
                    'Berita Terbaru',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: RanahSpacing.sm),
                  if (widget.isLoading && widget.stories.isEmpty)
                    const _NewsFeedMessage(
                      message: 'Memuat berita dari server...',
                    )
                  else if (widget.error != null)
                    _NewsFeedMessage(
                      message: widget.stories.isEmpty
                          ? 'Berita belum dapat dimuat: ${widget.error}'
                          : 'Pembaruan berita gagal. Menampilkan data terakhir yang berhasil dimuat.',
                      onRetry: widget.onRetry,
                    )
                  else if (widget.stories.isEmpty)
                    const _NewsFeedMessage(
                      message: 'Belum ada berita tersedia dari server.',
                    ),
                  if (widget.isLoading && widget.stories.isNotEmpty)
                    const LinearProgressIndicator(),
                  LayoutBuilder(
                    builder: (context, gridConstraints) {
                      final columns = gridConstraints.maxWidth < 560
                          ? 1
                          : gridConstraints.maxWidth >= 1240
                          ? 3
                          : 2;
                      final gap = columns == 1
                          ? RanahSpacing.md
                          : RanahSpacing.xl;
                      final cardWidth = columns == 1
                          ? gridConstraints.maxWidth
                          : (gridConstraints.maxWidth - gap * (columns - 1)) /
                                columns;
                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          for (final story in widget.stories)
                            SizedBox(
                              width: cardWidth,
                              child: _NewsCard(
                                story: story,
                                compact: columns > 1,
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
          ),
        );
      },
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.story,
    required this.isLoading,
    required this.error,
    required this.onRetry,
    required this.onPrevious,
    required this.onNext,
    required this.onTap,
  });

  final HomeStory? story;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final height = width < 560 ? 205.0 : (width < 900 ? 185.0 : 300.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(9),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: story == null
                  ? const ColoredBox(
                      key: ValueKey('empty-news-hero'),
                      color: Color(0xFF26384A),
                    )
                  : HomeStoryImage(
                      key: ValueKey(
                        story!.imageUrl ??
                            '${story!.heroImage ?? story!.image}-${story!.id}',
                      ),
                      story: story!,
                      fit: BoxFit.cover,
                      assetPath: story!.heroImage ?? story!.image,
                      width: double.infinity,
                      height: height,
                    ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x113B5D83),
                    Color(0x55394E70),
                    Color(0xD800102E),
                  ],
                  stops: [0, .62, 1],
                ),
              ),
            ),
            Positioned(
              left: 22,
              top: 22,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: RanahColors.eruption,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Text(
                      'Berita Utama',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (story != null && !story!.isApiRecord)
                    const Text(
                      'CONTOH',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .7,
                      ),
                    ),
                ],
              ),
            ),
            if (story != null)
              Positioned(
                left: 22,
                bottom: 10,
                right: 64,
                child: InkWell(
                  onTap: onTap,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        story!.category,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        key: ValueKey('home-highlight-${story!.id}'),
                        story!.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          height: 1.05,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (story == null)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLoading) const CircularProgressIndicator(),
                    if (!isLoading)
                      Text(
                        error == null
                            ? 'Belum ada berita utama.'
                            : 'Berita belum dapat dimuat.',
                        style: const TextStyle(color: Colors.white),
                      ),
                    if (error != null && onRetry != null)
                      TextButton(
                        onPressed: onRetry,
                        child: const Text('Coba lagi'),
                      ),
                  ],
                ),
              ),
            Positioned(
              left: 22,
              top: 0,
              bottom: 0,
              child: _HeroArrow(icon: Icons.chevron_left, onTap: onPrevious),
            ),
            Positioned(
              right: 22,
              top: 0,
              bottom: 0,
              child: _HeroArrow(icon: Icons.chevron_right, onTap: onNext),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroArrow extends StatelessWidget {
  const _HeroArrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Align(
    child: InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0x669BA8BA),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 26, color: RanahColors.primary),
          ),
        ),
      ),
    ),
  );
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({
    required this.story,
    required this.compact,
    required this.onTap,
  });

  final HomeStory story;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageSize = compact ? 66.0 : 78.0;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: compact ? 94 : 108),
          child: Padding(
            padding: EdgeInsets.all(compact ? 10 : 12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: HomeStoryImage(
                    story: story,
                    fit: BoxFit.cover,
                    width: imageSize,
                    height: imageSize,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        story.isApiRecord
                            ? story.category
                            : 'CONTOH \u00B7 ${story.category}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: RanahColors.ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        story.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: RanahColors.ink,
                          fontSize: 16,
                          height: 1.12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        story.date,
                        style: const TextStyle(
                          color: RanahColors.ink,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NewsFeedMessage extends StatelessWidget {
  const _NewsFeedMessage({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
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
