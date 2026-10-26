import 'package:flutter/material.dart';

import '../data/home_stories.dart';
import '../theme/ranah_theme.dart';
import '../widgets/home_story_image.dart';
import '../widgets/ranah_full_width_title_background.dart';
import '../widgets/ranah_header.dart';
import 'news_page.dart';

class NewsDetailPage extends StatelessWidget {
  const NewsDetailPage({required this.story, required this.onBack, super.key});

  final HomeStory story;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final mobile = constraints.maxWidth < 600;
      final maxWidth = constraints.maxWidth > RanahLayout.maxContentWidth
          ? RanahLayout.maxContentWidth
          : constraints.maxWidth;
      final horizontal = mobile ? 14.0 : 32.0;
      final imageHeight = mobile
          ? (constraints.maxWidth * .32).clamp(120.0, 180.0)
          : 300.0;
      return RanahPageScrollLayout(
        maxContentWidth: maxWidth,
        bottomPadding: 0,
        title: NewsPageBanner(maxContentWidth: maxWidth),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: const Color(0xFFDCE4EF),
              padding: const EdgeInsets.symmetric(
                horizontal: RanahSpacing.lg,
                vertical: RanahSpacing.sm,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: RanahBackButton(onPressed: onBack),
              ),
            ),
            SizedBox(
              height: imageHeight,
              child: HomeStoryImage(
                story: story,
                fit: BoxFit.cover,
                width: double.infinity,
                height: imageHeight,
              ),
            ),
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1080),
                width: double.infinity,
                color: const Color(0xFFE3EAF3),
                padding: EdgeInsets.fromLTRB(
                  horizontal,
                  mobile ? RanahSpacing.lg : RanahSpacing.xl,
                  horizontal,
                  RanahSpacing.xxl,
                ),
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
                    const SizedBox(height: RanahSpacing.xs),
                    Text(
                      story.title,
                      style: TextStyle(
                        color: RanahColors.ink,
                        fontSize: mobile ? 16 : 21,
                        height: 1.15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: RanahSpacing.xs),
                    Text(
                      story.date,
                      style: TextStyle(
                        color: const Color(0xFF657287),
                        fontSize: 12,
                      ),
                    ),
                    if (story.region != null) ...[
                      const SizedBox(height: RanahSpacing.sm),
                      Text(
                        'Wilayah: ${story.region}',
                        style: const TextStyle(
                          color: Color(0xFF657287),
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (story.eventAt != null) ...[
                      const SizedBox(height: RanahSpacing.sm),
                      Text(
                        'Waktu kejadian: ${_formatStoryDateTime(story.eventAt!)}',
                        style: const TextStyle(
                          color: Color(0xFF657287),
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: RanahSpacing.xl),
                    Text(
                      story.content,
                      style: TextStyle(
                        color: RanahColors.ink,
                        fontSize: 16,
                        height: mobile ? 1.35 : 1.55,
                      ),
                    ),
                    if (story.source case final source?) ...[
                      const SizedBox(height: RanahSpacing.xl),
                      Text(
                        'Sumber: $source',
                        style: TextStyle(
                          color: RanahColors.ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (story.sourceUrl != null) ...[
                      const SizedBox(height: RanahSpacing.sm),
                      SelectableText(
                        'URL sumber: ${story.sourceUrl}',
                        style: const TextStyle(
                          color: Color(0xFF657287),
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (!story.isApiRecord) ...[
                      const SizedBox(height: RanahSpacing.lg),
                      const Text(
                        'Konten demonstrasi \u2014 bukan berita terkini yang telah diverifikasi.',
                        style: TextStyle(
                          color: Color(0xFF657287),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

String _formatStoryDateTime(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/${local.year} $hour:$minute';
}
