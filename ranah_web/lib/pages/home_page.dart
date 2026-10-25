import 'package:flutter/material.dart';

import '../data/home_stories.dart';
import '../theme/ranah_theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({required this.onStoryTap, super.key});

  final ValueChanged<HomeStory> onStoryTap;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _highlightIndex = 0;

  void _moveHighlight(int amount) {
    setState(() {
      _highlightIndex =
          (_highlightIndex + amount + homeHighlights.length) %
          homeHighlights.length;
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
        final contentWidth = constraints.maxWidth > 1220
            ? 1220.0
            : constraints.maxWidth;
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: contentWidth,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalInset,
                mobile ? 20 : 26,
                horizontalInset,
                32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroCard(
                    story: homeHighlights[_highlightIndex],
                    onPrevious: () => _moveHighlight(-1),
                    onNext: () => _moveHighlight(1),
                    onTap: () =>
                        widget.onStoryTap(homeHighlights[_highlightIndex]),
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    'Berita Terbaru',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  LayoutBuilder(
                    builder: (context, gridConstraints) {
                      final isNarrow = gridConstraints.maxWidth < 560;
                      final gap = isNarrow ? 12.0 : 22.0;
                      final cardWidth = isNarrow
                          ? gridConstraints.maxWidth
                          : (gridConstraints.maxWidth - gap) / 2;
                      return Wrap(
                        spacing: gap,
                        runSpacing: isNarrow ? 12 : 31,
                        children: [
                          for (final story in homeStories)
                            SizedBox(
                              width: cardWidth,
                              child: _NewsCard(
                                story: story,
                                compact: !isNarrow,
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
    required this.onPrevious,
    required this.onNext,
    required this.onTap,
  });

  final HomeStory story;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onTap;

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
              child: Image.asset(
                story.heroImage ?? story.image,
                key: ValueKey(story.heroImage ?? story.image),
                fit: BoxFit.cover,
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
                      story.category,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      story.title,
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
                  child: Image.asset(
                    story.image,
                    width: imageSize,
                    height: imageSize,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'CONTOH · ${story.category}',
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
