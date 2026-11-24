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

  /// Number of current earthquake items; zero hides the badge.
  final int? notificationCount;
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSizes.brandHeaderVerticalPadding + 2,
        AppSpacing.sm,
        AppSizes.brandHeaderVerticalPadding + 2,
      ),
      decoration: const BoxDecoration(
        gradient: AppGradients.brandHeader,
        border: Border(
          bottom: BorderSide(color: Color(0x26FFFFFF), width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x3D020614),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Semantics(
            image: true,
            label: 'Logo RANAH',
            child: Container(
              width: AppSizes.brandMark,
              height: AppSizes.brandMark,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.16),
                  width: 1.5,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child:
                  logo ??
                  Image.asset(
                    'assets/images/brand_mark.png',
                    fit: BoxFit.cover,
                  ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: AppSizes.brandMark),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm + 2,
                vertical: AppSpacing.xxs + 1,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF09213D).withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              alignment: Alignment.centerLeft,
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RANAH',
                    style: TextStyle(
                      color: AppColors.onDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Aplikasi Informasi Bencana dan Evakuasi',
                    style: TextStyle(
                      color: Color(0xFFBACADB),
                      fontSize: 12,
                      height: 1.25,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Tooltip(
            message: isOnline ? 'Online' : 'Offline',
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ConnectionIndicator(isOnline: isOnline),
                  const SizedBox(width: 5),
                  Icon(
                    isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                    size: 16,
                    color: isOnline
                        ? const Color(0xFF67D391)
                        : AppColors.danger,
                  ),
                ],
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
                if (notificationCount != null && notificationCount! > 0)
                  Positioned(
                    right: -4,
                    top: -4,
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

class _ConnectionIndicator extends StatelessWidget {
  const _ConnectionIndicator({required this.isOnline});
  final bool isOnline;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 180),
    width: 9,
    height: 9,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: isOnline ? const Color(0xFF74D8AE) : AppColors.danger,
    ),
  );
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
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFFE53935),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66E53935),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(label, style: AppTypography.badge.copyWith(fontSize: 10.5)),
    );
  }
}
