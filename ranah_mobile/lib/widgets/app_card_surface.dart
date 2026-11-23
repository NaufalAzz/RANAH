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

/// Shared surface treatment for the app's distinct card roles with fluid tactile feedback.
/// The child layout stays with each feature so card contents remain specific.
class AppCardSurface extends StatefulWidget {
  const AppCardSurface({
    required this.variant,
    required this.child,
    this.onTap,
    this.padding = EdgeInsets.zero,
    this.accent,
    this.minimumHeight,
    this.showBorder = true,
    super.key,
  });

  final AppCardVariant variant;
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? accent;
  final double? minimumHeight;
  final bool showBorder;

  @override
  State<AppCardSurface> createState() => _AppCardSurfaceState();
}

class _AppCardSurfaceState extends State<AppCardSurface> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails _) {
    if (widget.onTap != null) setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails _) {
    if (widget.onTap != null) setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    if (widget.onTap != null) setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(widget.variant, widget.accent);
    final radius = BorderRadius.circular(style.radius);
    final animationsDisabled = MediaQuery.of(context).disableAnimations;

    final content = Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: widget.minimumHeight ?? 0),
      decoration: BoxDecoration(
        borderRadius: radius,
        border: !widget.showBorder || style.borderColor == null
            ? null
            : Border.all(color: style.borderColor!, width: 1.2),
      ),
      padding: widget.padding,
      child: widget.child,
    );

    final card = Material(
      color: style.background,
      borderRadius: radius,
      elevation: _isPressed ? (style.elevation * 0.5) : style.elevation,
      shadowColor: const Color(0x1F06152B),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        borderRadius: radius,
        splashColor: (widget.accent ?? AppColors.primary).withValues(alpha: 0.08),
        highlightColor:
            (widget.accent ?? AppColors.primary).withValues(alpha: 0.04),
        child: content,
      ),
    );

    if (widget.onTap == null || animationsDisabled) {
      return card;
    }

    return AnimatedScale(
      scale: _isPressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      child: card,
    );
  }

  _AppCardStyle _styleFor(AppCardVariant variant, Color? accent) =>
      switch (variant) {
        AppCardVariant.news => const _AppCardStyle(
          background: AppColors.white,
          radius: AppRadii.card,
          elevation: 2.5,
          borderColor: Color(0xFFE5EBF2),
        ),
        AppCardVariant.notification => const _AppCardStyle(
          background: Color(0xFFF3F8FC),
          radius: AppRadii.card,
          elevation: 3,
          borderColor: Color(0xFFB5D4E6),
        ),
        AppCardVariant.contact => _AppCardStyle(
          background: AppColors.emergencySurface.withValues(alpha: 0.92),
          radius: AppRadii.compact,
          elevation: 2,
          borderColor: AppColors.emergencyBorder,
        ),
        AppCardVariant.mitigationStep => _AppCardStyle(
          background: (accent ?? AppColors.primary).withValues(alpha: 0.28),
          radius: AppRadii.compact,
          borderColor: (accent ?? AppColors.primary).withValues(alpha: 0.38),
        ),
        AppCardVariant.information => const _AppCardStyle(
          background: Color(0xFF133F5E),
          radius: AppRadii.card,
          elevation: 2,
          borderColor: Color(0xFF225F83),
        ),
        AppCardVariant.menu => const _AppCardStyle(
          background: AppColors.white,
          radius: AppRadii.card,
          elevation: 2.5,
          borderColor: Color(0xFFE5EBF2),
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
