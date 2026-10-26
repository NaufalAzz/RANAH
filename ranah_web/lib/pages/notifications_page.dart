import 'package:flutter/material.dart';

import '../models/bmkg_notification.dart';
import '../services/notifications_repository.dart';
import '../theme/ranah_theme.dart';
import '../widgets/ranah_full_width_title_background.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({
    required this.onBack,
    this.repository,
    super.key,
  });

  final VoidCallback onBack;
  final BmkgNotificationRepository? repository;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final BmkgNotificationRepository _repository;
  BmkgNotificationFeed? _feed;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? NotificationsRepository();
    _load(page: 1);
  }

  Future<void> _load({required int page}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final feed = await _repository.load(page: page);
      if (mounted) setState(() => _feed = feed);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth > 1000 ? 1000.0 : constraints.maxWidth;
      final horizontal = width < 600 ? 20.0 : 36.0;
      final feed = _feed;
      return RanahPageScrollLayout(
        maxContentWidth: width,
        title: _NotificationsBanner(
          onBack: widget.onBack,
          maxContentWidth: width,
          onRefresh: _loading ? null : () => _load(page: feed?.currentPage ?? 1),
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(horizontal, 12, horizontal, 0),
              child: const Text(
                'Notifikasi BMKG · Sumatera Barat',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (_loading && feed == null)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null && feed == null)
              Padding(
                padding: EdgeInsets.fromLTRB(horizontal, 12, horizontal, 0),
                child: _FeedError(error: _error!, onRetry: () => _load(page: 1)),
              )
            else ...[
              if (_error != null)
                Padding(
                  padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, 0),
                  child: _FeedMessage(
                    text: 'Pembaruan gagal. Menampilkan hasil permintaan terakhir yang berhasil.',
                    color: const Color(0xFFFFE0A6),
                  ),
                ),
              Padding(
                padding: EdgeInsets.fromLTRB(horizontal, 5, horizontal, 10),
                child: _FeedMessage(
                  text: feed?.sourceUpdatedAt == null
                      ? 'Waktu sinkronisasi BMKG belum tersedia dari server.'
                      : 'Sinkronisasi BMKG terakhir ${_formatTime(feed!.sourceUpdatedAt!)}. Pembaruan dilakukan berkala oleh server.',
                  color: const Color(0xFFD7E0EA),
                ),
              ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: LinearProgressIndicator(),
                ),
              if (feed == null || feed.items.isEmpty)
                Padding(
                  padding: EdgeInsets.fromLTRB(horizontal, 12, horizontal, 0),
                  child: const _EmptyFeed(),
                )
              else ...[
                Padding(
                  padding: EdgeInsets.fromLTRB(horizontal, 0, horizontal, 10),
                  child: _FeedMessage(
                    text: '${feed.total} informasi aktif · halaman ${feed.currentPage} dari ${feed.lastPage}',
                    color: const Color(0xFFD7E0EA),
                  ),
                ),
                for (var index = 0; index < feed.items.length; index++)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontal,
                      0,
                      horizontal,
                      index == feed.items.length - 1 ? 0 : 13,
                    ),
                    child: _NotificationCard(
                      notification: feed.items[index],
                      index: index,
                    ),
                  ),
                if (feed.lastPage > 1)
                  Padding(
                    padding: EdgeInsets.fromLTRB(horizontal, 14, horizontal, 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton(
                          onPressed: _loading || feed.currentPage <= 1
                              ? null
                              : () => _load(page: feed.currentPage - 1),
                          child: const Text('Sebelumnya'),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            '${feed.currentPage}/${feed.lastPage}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        OutlinedButton(
                          onPressed: _loading || feed.currentPage >= feed.lastPage
                              ? null
                              : () => _load(page: feed.currentPage + 1),
                          child: const Text('Berikutnya'),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
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
    required this.onRefresh,
  });

  final VoidCallback onBack;
  final double maxContentWidth;
  final VoidCallback? onRefresh;

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
            onPressed: onRefresh,
            tooltip: 'Muat ulang notifikasi',
            constraints: const BoxConstraints.tightFor(width: 44, height: 48),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.refresh, size: 19),
          ),
          IconButton(
            onPressed: onBack,
            tooltip: 'Kembali',
            constraints: const BoxConstraints.tightFor(width: 44, height: 48),
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
  });

  final BmkgNotification notification;
  final int index;

  @override
  Widget build(BuildContext context) {
    final danger = notification.isWarning;
    final accent = danger ? RanahColors.eruption : const Color(0xFF74839A);
    final itemTime = notification.eventAt ?? notification.publishedAt;

    return Material(
      color: Colors.transparent,
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
                child: Icon(
                  danger
                      ? Icons.warning_amber_rounded
                      : notification.category.toLowerCase().contains('gempa')
                          ? Icons.vibration_rounded
                          : Icons.info_outline_rounded,
                  color: accent,
                  size: 24,
                ),
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
                          danger ? 'PERINGATAN AKTIF' : notification.category.toUpperCase(),
                          style: TextStyle(
                            color: RanahColors.ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          itemTime == null
                              ? 'Waktu sumber tidak tersedia'
                              : '${notification.eventAt == null ? 'Terbit' : 'Kejadian'} ${_formatTime(itemTime)}',
                          style: const TextStyle(
                            color: RanahColors.muted,
                            fontSize: 12,
                          ),
                        ),
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
                      notification.summary,
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
                      notification.region ?? 'Wilayah dari sumber tidak tersedia',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: RanahColors.muted,
                        fontSize: 12,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      notification.source ?? 'Sumber tidak tersedia',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: RanahColors.muted,
                        fontSize: 12,
                        height: 1.1,
                      ),
                    ),
                    if (notification.retrievedAt != null)
                      Text(
                        'Data diambil ${_formatTime(notification.retrievedAt!)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: RanahColors.muted,
                          fontSize: 11,
                          height: 1.1,
                        ),
                      ),
          ],
        ),
              ),
            ],
          ),
        ),
    );
  }
}

class _FeedMessage extends StatelessWidget {
  const _FeedMessage({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(color: color, fontSize: 12, height: 1.35),
  );
}

class _FeedError extends StatelessWidget {
  const _FeedError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFF542B3A),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFFF9B9B)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notifikasi BMKG belum dapat dimuat.',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text('$error', style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Coba lagi'),
        ),
      ],
    ),
  );
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Column(
      children: [
        Icon(Icons.notifications_none, size: 34, color: RanahColors.muted),
        SizedBox(height: 8),
        Text(
          'Tidak ada informasi aktif yang relevan untuk Sumatera Barat saat ini.',
          textAlign: TextAlign.center,
          style: TextStyle(color: RanahColors.ink, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

String _formatTime(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/${local.year} $hour:$minute';
}
