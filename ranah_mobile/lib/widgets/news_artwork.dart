import 'package:flutter/material.dart';
import 'package:ranah_accessibility/ranah_accessibility.dart'
    show RanahNewsCover;

import '../models/news_item.dart';
import '../theme/app_theme.dart';

class NewsArtwork extends StatelessWidget {
  const NewsArtwork({required this.item, this.featured = false, super.key});

  final NewsItem item;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.imageUrl;
    final radius = BorderRadius.circular(
      featured ? AppRadii.image : AppRadii.control,
    );

    final cover = RanahNewsCover(category: item.category);
    return Container(
      height: featured ? 188 : 86,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: radius),
      child: imageUrl == null
          ? cover
          : Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) =>
                      progress == null ? child : cover,
                  errorBuilder: (context, error, stackTrace) => cover,
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x180C1624),
                        Color(0x00101A2C),
                        Color(0x50101A2C),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
