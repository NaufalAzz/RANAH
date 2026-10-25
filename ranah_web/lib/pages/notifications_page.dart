import 'package:flutter/material.dart';

import '../data/sample_notifications.dart';
import '../theme/ranah_theme.dart';
import '../widgets/ranah_full_width_title_background.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({
    required this.onBack,
    required this.onNotificationTap,
    super.key,
  });

  final VoidCallback onBack;
  final ValueChanged<SampleNotification> onNotificationTap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth > 1000 ? 1000.0 : constraints.maxWidth;
      final horizontal = width < 600 ? 20.0 : 36.0;
      return RanahPageScrollLayout(
        maxContentWidth: width,
        title: _NotificationsBanner(onBack: onBack, maxContentWidth: width),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(horizontal, 12, horizontal, 0),
              child: const Text(
                'Semua Notifikasi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(horizontal, 5, horizontal, 9),
              child: const Text(
                'DATA SIMULASI · Bukan peringatan bencana real-time',
                style: TextStyle(
                  color: Color(0xFFFFD788),
                  fontSize: 12,
                  height: 1.25,
                ),
              ),
            ),
            for (var index = 0; index < sampleNotifications.length; index++)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontal,
                  0,
                  horizontal,
                  index == sampleNotifications.length - 1 ? 0 : 13,
                ),
                child: _NotificationCard(
                  notification: sampleNotifications[index],
                  index: index,
                  onTap: sampleNotifications[index].destination == null
                      ? null
                      : () => onNotificationTap(sampleNotifications[index]),
                ),
              ),
          ],
        ),
      );
    },
  );
}

class _NotificationsBanner extends StatelessWidget {
  const _NotificationsBanner({
    required this.onBack,
    required this.maxContentWidth,
  });

  final VoidCallback onBack;
  final double maxContentWidth;

  @override
  Widget build(BuildContext context) => RanahFullWidthTitleBackground(
    color: RanahColors.banner,
    maxContentWidth: maxContentWidth,
    child: Container(
      constraints: const BoxConstraints(minHeight: 76),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: RanahColors.banner,
      child: Row(
        children: [
          const Icon(Icons.notifications_none_rounded, size: 26),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SIAGA BENCANA',
                  maxLines: 1,
                  style: TextStyle(
                    color: Color(0xFF91A8D0),
                    fontSize: 12,
                    letterSpacing: .45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Notifikasi',
                  maxLines: 1,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                Text(
                  'Peringatan dan informasi terkini',
                  maxLines: 1,
                  style: TextStyle(color: Color(0xFFC1C8D7), fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onBack,
            tooltip: 'Kembali',
            constraints: const BoxConstraints.tightFor(width: 48, height: 48),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.arrow_back, size: 17),
          ),
        ],
      ),
    ),
  );
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.index,
    required this.onTap,
  });

  final SampleNotification notification;
  final int index;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final danger = notification.level == 'BAHAYA';
    final accent = danger ? RanahColors.eruption : const Color(0xFF74839A);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          key: ValueKey('notification-card-$index'),
          constraints: const BoxConstraints(minHeight: 68),
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9F8),
                  border: Border.all(color: accent, width: .8),
                ),
                child: Icon(notification.icon, color: accent, size: 24),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 3,
                      children: [
                        Text(
                          notification.level,
                          style: TextStyle(
                            color: RanahColors.ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          notification.time,
                          style: const TextStyle(
                            color: RanahColors.muted,
                            fontSize: 12,
                          ),
                        ),
                        if (notification.kind ==
                            SampleNotificationKind.earthquake) ...[
                          const Text(
                            'GEMPA',
                            style: TextStyle(
                              color: RanahColors.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notification.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF1D2636),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notification.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: RanahColors.muted,
                        fontSize: 16,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notification.source,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: RanahColors.muted,
                        fontSize: 12,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 5),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF8892A0),
                  size: 18,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
