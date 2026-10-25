import 'package:flutter/material.dart';

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

    return Container(
      height: featured ? 188 : 86,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: radius),
      child: imageUrl == null
          ? const _NeutralPlaceholder()
          : Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) =>
                      progress == null ? child : const _NeutralPlaceholder(),
                  errorBuilder: (context, error, stackTrace) =>
                      const _NeutralPlaceholder(),
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

class _NeutralPlaceholder extends StatelessWidget {
  const _NeutralPlaceholder();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF26384A), Color(0xFF172536)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Center(
      child: Icon(
        Icons.photo_outlined,
        size: 34,
        color: Color(0xFFB8C3CF),
      ),
    ),
  );
}
