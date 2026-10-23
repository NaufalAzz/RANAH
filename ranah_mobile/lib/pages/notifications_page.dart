import 'package:flutter/material.dart';

import '../data/sample_notifications.dart';
import '../models/notification_item.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';

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
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF21085F), Color(0xFF100525)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.notifications_none_rounded,
            color: Colors.white,
            size: 38,
          ),
          const SizedBox(width: 19),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'INFORMASI RANAH',
                  style: TextStyle(
                    color: Color(0xFF82C7FF),
                    fontSize: 14,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  'Notifikasi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Peringatan dan informasi terkini',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFFC8C0D5),
                    fontSize: 14,
                    height: 1.15,
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      elevation: 3,
      shadowColor: const Color(0x26000A18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: item.accent.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.accent, size: 25),
              ),
              const SizedBox(width: 12),
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
                              fontSize: 9,
                              letterSpacing: 0.35,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          item.timeLabel,
                          style: const TextStyle(
                            color: Color(0xFF858A94),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: Color(0xFF202733),
                        fontSize: 14,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.summary,
                      style: const TextStyle(
                        color: Color(0xFF68717E),
                        fontSize: 11,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'SIMULASI DATA',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 8,
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
        ),
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
