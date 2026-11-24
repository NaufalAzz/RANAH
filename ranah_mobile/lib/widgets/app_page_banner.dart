import 'package:flutter/material.dart';

import 'package:ranah_accessibility/ranah_accessibility.dart';

import '../theme/app_theme.dart';

/// Shared page-heading surface. Text may wrap so larger system font scales are
/// not clipped by a fixed-height banner.
class AppPageBanner extends StatelessWidget {
  const AppPageBanner({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.minHeight = AppSizes.pageBannerMinHeight,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.xl,
      vertical: AppSpacing.md,
    ),
    this.iconSize = AppSizes.bannerIcon,
    this.iconGap = AppSpacing.md,
    this.eyebrowStyle = AppTypography.bannerEyebrow,
    this.titleStyle = AppTypography.bannerTitle,
    this.subtitleStyle = AppTypography.bannerSubtitle,
    this.gradient = AppGradients.pageBanner,
    this.borderRadius = BorderRadius.zero,
    this.border,
    super.key,
  });

  final IconData icon;
  final String eyebrow;
  final String title;
  final String subtitle;
  final double minHeight;
  final EdgeInsetsGeometry padding;
  final double iconSize;
  final double iconGap;
  final TextStyle eyebrowStyle;
  final TextStyle titleStyle;
  final TextStyle subtitleStyle;
  final Gradient gradient;
  final BorderRadiusGeometry borderRadius;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: borderRadius,
        border: border,
      ),
      child: CustomPaint(
        painter: const RanahContours(),
        child: Padding(
          padding: padding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0x183FAEBC),
                  border: Border.all(color: const Color(0x465EC3C4)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    icon,
                    color: const Color(0xFFD4F2F2),
                    size: iconSize * .84,
                  ),
                ),
              ),
              SizedBox(width: iconGap),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(eyebrow, style: eyebrowStyle),
                    Text(title, style: titleStyle),
                    Text(subtitle, style: subtitleStyle),
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
