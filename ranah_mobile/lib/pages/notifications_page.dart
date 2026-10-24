import 'package:flutter/material.dart';

import '../data/sample_notifications.dart';
import '../models/notification_item.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/app_card_surface.dart';
import '../widgets/app_page_banner.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key, required this.onNotificationTap});

  final ValueChanged<NotificationItem> onNotificationTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppBackground.decoration,
      child: Stack(
        children: [
          const Positioned(top: 112, right: -76, child: _BackgroundRings()),
          ListView(
            padding: const EdgeInsets.only(top: 18, bottom: 28),
            children: [
              const _NotificationBanner(),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 25, 18, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Semua Notifikasi',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 13),
                    if (sampleNotifications.isEmpty)
                      const _EmptyNotifications()
                    else
                      for (
                        var index = 0;
                        index < sampleNotifications.length;
                        index++
                      ) ...[
                        _NotificationCard(
                          item: sampleNotifications[index],
                          onTap: () =>
                              onNotificationTap(sampleNotifications[index]),
                        ),
                        if (index < sampleNotifications.length - 1)
                          const SizedBox(height: 12),
                      ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotificationBanner extends StatelessWidget {
  const _NotificationBanner();

  @override
  Widget build(BuildContext context) => const AppPageBanner(
    icon: Icons.notifications_none_rounded,
    eyebrow: 'INFORMASI RANAH',
    title: 'Notifikasi',
    subtitle: 'Peringatan dan informasi terkini',
    minHeight: 88,
    padding: EdgeInsets.symmetric(horizontal: 34, vertical: 14),
    iconSize: 38,
    iconGap: 19,
    eyebrowStyle: TextStyle(
      color: AppColors.bannerEyebrow,
      fontSize: 14,
      height: 1.15,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.8,
    ),
    subtitleStyle: TextStyle(
      color: Color(0xFFC8C0D5),
      fontSize: 14,
      height: 1.15,
    ),
  );
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Text(
        'Belum ada notifikasi untuk ditampilkan.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFF68717E), fontSize: 14),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item, required this.onTap});

  final NotificationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCardSurface(
      variant: AppCardVariant.notification,
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppSizes.minimumTapTarget,
            height: AppSizes.minimumTapTarget,
            decoration: BoxDecoration(
              color: item.accent.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(AppRadii.card),
            ),
            child: Icon(item.icon, color: item.accent, size: 25),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.kindLabel.toUpperCase(),
                        style: TextStyle(
                          color: item.accent,
                          fontSize: 13,
                          letterSpacing: 0.35,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      item.timeLabel,
                      style: const TextStyle(
                        color: Color(0xFF858A94),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  item.title,
                  style: const TextStyle(
                    color: Color(0xFF202733),
                    fontSize: 18,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  item.summary,
                  style: const TextStyle(
                    color: Color(0xFF68717E),
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: const Text(
                    'SIMULASI DATA',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      letterSpacing: 0.55,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundRings extends StatelessWidget {
  const _BackgroundRings();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      height: 190,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.035),
            width: 20,
          ),
        ),
      ),
    );
  }
}
