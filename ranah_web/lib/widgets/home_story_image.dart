import 'package:flutter/material.dart';

import '../data/home_stories.dart';

class HomeStoryImage extends StatelessWidget {
  const HomeStoryImage({
    required this.story,
    required this.fit,
    this.assetPath,
    this.width,
    this.height,
    super.key,
  });

  final HomeStory story;
  final BoxFit fit;
  final String? assetPath;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final imageUrl = story.imageUrl;
    if (imageUrl != null) {
      return Image.network(
        imageUrl,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, error, _) {
          debugPrint('Gambar berita ${story.id} gagal dimuat: $error');
          return _placeholder();
        },
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : _placeholder(),
      );
    }
    final localAsset = assetPath ?? story.image;
    if (!story.isApiRecord && localAsset.isNotEmpty) {
      return Image.asset(localAsset, fit: fit, width: width, height: height);
    }
    return _placeholder();
  }

  Widget _placeholder() => Container(
    width: width,
    height: height,
    color: const Color(0xFF26384A),
    alignment: Alignment.center,
    child: const Icon(Icons.photo_outlined, color: Color(0xFFB8C3CF), size: 32),
  );
}
