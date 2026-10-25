import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class BrandHeader extends StatelessWidget {
  const BrandHeader({
    super.key,
    this.onOpenNotifications,
    this.logo,
    this.notificationCount,
    this.isOnline = false,
  });

  final VoidCallback? onOpenNotifications;
  final Widget? logo;

  /// Null keeps the current small indicator; a value enables a count badge.
  final int? notificationCount;
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSizes.brandHeaderVerticalPadding,
        AppSpacing.xs,
        AppSizes.brandHeaderVerticalPadding,
      ),
      decoration: const BoxDecoration(gradient: AppGradients.brandHeader),
      child: Row(
        children: [
          Semantics(
            image: true,
            label: logo == null ? 'Ikon sementara RANAH' : 'Logo RANAH',
            child: Container(
              width: AppSizes.brandMark,
              height: AppSizes.brandMark,
              decoration: BoxDecoration(
                color: AppColors.brandTile,
                borderRadius: BorderRadius.circular(AppRadii.card),
              ),
              alignment: Alignment.center,
              child:
                  logo ??
                  const Icon(
                    Icons.home_work_rounded,
                    color: AppColors.onDark,
                    size: AppSizes.brandIcon,
                  ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: AppSizes.brandMark),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: AppColors.brandLabelPanel,
                borderRadius: BorderRadius.circular(AppRadii.control),
              ),
              alignment: Alignment.centerLeft,
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('RANAH', style: AppTypography.brandTitle),
                  SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Aplikasi Informasi Bencana dan Evakuasi',
                    style: AppTypography.bannerSubtitle,
                  ),
                ],
              ),
            ),
          ),
          Tooltip(
            message: isOnline ? 'Online' : 'Offline',
            child: Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: Icon(
                isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                size: 19,
                color: isOnline ? const Color(0xFF67D391) : AppColors.danger,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Notifikasi',
            onPressed:
                onOpenNotifications ??
                () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notifikasi belum tersedia.')),
                ),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  size: AppSizes.iconMedium,
                ),
                if (notificationCount == null || notificationCount! > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: _NotificationBadge(count: notificationCount),
                  ),
              ],
            ),
            color: AppColors.onDark,
            constraints: const BoxConstraints.tightFor(
              width: AppSizes.minimumTapTarget,
              height: AppSizes.minimumTapTarget,
            ),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

class _NotificationBadge extends StatelessWidget {
  const _NotificationBadge({required this.count});

  final int? count;

  @override
  Widget build(BuildContext context) {
    final value = count;
    if (value == null) {
      return const SizedBox(
        width: 8,
        height: 8,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.danger,
            shape: BoxShape.circle,
          ),
        ),
      );
    }

    final label = value > 99 ? '99+' : '$value';
    return Container(
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.danger,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      alignment: Alignment.center,
      child: Text(label, style: AppTypography.badge),
    );
  }
}
