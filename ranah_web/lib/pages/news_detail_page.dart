import 'package:flutter/material.dart';

import '../data/home_stories.dart';
import '../theme/ranah_theme.dart';
import 'news_page.dart';

class NewsDetailPage extends StatelessWidget {
  const NewsDetailPage({required this.story, required this.onBack, super.key});

  final HomeStory story;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final mobile = constraints.maxWidth < 600;
      final maxWidth = constraints.maxWidth > 1200
          ? 1200.0
          : constraints.maxWidth;
      final horizontal = mobile ? 14.0 : 32.0;
      final imageHeight = mobile
          ? (constraints.maxWidth * .32).clamp(120.0, 180.0)
          : 300.0;
      return Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: maxWidth,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const NewsPageBanner(),
                Container(
                  height: 28,
                  color: const Color(0xFFDCE4EF),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: TextButton.icon(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back, size: 12),
                    label: const Text('Kembali'),
                    style: TextButton.styleFrom(
                      foregroundColor: RanahColors.ink,
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 22),
                      textStyle: const TextStyle(fontSize: 9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: imageHeight,
                  child: Image.asset(story.image, fit: BoxFit.cover),
                ),
                Container(
                  color: const Color(0xFFE3EAF3),
                  padding: EdgeInsets.fromLTRB(
                    horizontal,
                    mobile ? 12 : 22,
                    horizontal,
                    28,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CONTOH · ${story.category}',
                        style: TextStyle(
                          color: Color(story.color),
                          fontSize: mobile ? 10 : 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        story.title,
                        style: TextStyle(
                          color: RanahColors.ink,
                          fontSize: mobile ? 12 : 21,
                          height: 1.15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        story.date,
                        style: TextStyle(
                          color: const Color(0xFF657287),
                          fontSize: mobile ? 8 : 12,
                        ),
                      ),
                      const SizedBox(height: 17),
                      Text(
                        story.content,
                        style: TextStyle(
                          color: RanahColors.ink,
                          fontSize: mobile ? 9 : 15,
                          height: mobile ? 1.35 : 1.55,
                        ),
                      ),
                      if (story.source case final source?) ...[
                        const SizedBox(height: 18),
                        Text(
                          'Sumber: $source',
                          style: TextStyle(
                            color: RanahColors.ink,
                            fontSize: mobile ? 9 : 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Text(
                        'Konten demonstrasi — bukan berita terkini yang telah diverifikasi.',
                        style: TextStyle(
                          color: const Color(0xFF657287),
                          fontSize: mobile ? 8 : 11,
                          fontStyle: FontStyle.italic,
                        ),
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
