import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum AppCardVariant {
  news,
  notification,
  contact,
  mitigationStep,
  information,
  menu,
}

/// Shared surface treatment for the app's distinct card roles.
/// The child layout stays with each feature so card contents remain specific.
class AppCardSurface extends StatelessWidget {
  const AppCardSurface({
    required this.variant,
    required this.child,
    this.onTap,
    this.padding = EdgeInsets.zero,
    this.accent,
    this.minimumHeight,
    super.key,
  });

  final AppCardVariant variant;
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? accent;
  final double? minimumHeight;

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(variant, accent);
    final radius = BorderRadius.circular(style.radius);
    final content = Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: minimumHeight ?? 0),
      decoration: BoxDecoration(
        borderRadius: radius,
        border: style.borderColor == null
            ? null
            : Border.all(color: style.borderColor!),
      ),
      padding: padding,
      child: child,
    );

    return Material(
      color: style.background,
      borderRadius: radius,
      elevation: style.elevation,
      shadowColor: AppColors.cardShadow,
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, borderRadius: radius, child: content),
    );
  }

  _AppCardStyle _styleFor(AppCardVariant variant, Color? accent) =>
      switch (variant) {
        AppCardVariant.news => const _AppCardStyle(
          background: AppColors.white,
          radius: AppRadii.card,
          elevation: 2,
          borderColor: AppColors.border,
        ),
        AppCardVariant.notification => const _AppCardStyle(
          background: AppColors.white,
          radius: AppRadii.card,
          elevation: 3,
        ),
        AppCardVariant.contact => _AppCardStyle(
          background: AppColors.emergencySurface.withValues(alpha: 0.88),
          radius: AppRadii.compact,
          borderColor: AppColors.emergencyBorder,
        ),
        AppCardVariant.mitigationStep => _AppCardStyle(
          background: (accent ?? AppColors.primary).withValues(alpha: 0.3),
          radius: AppRadii.control,
          borderColor: (accent ?? AppColors.primary).withValues(alpha: 0.38),
        ),
        AppCardVariant.information => const _AppCardStyle(
          background: AppColors.darkPanel,
          radius: AppRadii.card,
          borderColor: AppColors.darkPanelBorder,
        ),
        AppCardVariant.menu => const _AppCardStyle(
          background: AppColors.white,
          radius: AppRadii.card,
          elevation: 2,
          borderColor: AppColors.border,
        ),
      };
}

class _AppCardStyle {
  const _AppCardStyle({
    required this.background,
    required this.radius,
    this.elevation = 0,
    this.borderColor,
  });

  final Color background;
  final double radius;
  final double elevation;
  final Color? borderColor;
}
