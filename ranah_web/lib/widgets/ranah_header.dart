import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/ranah_theme.dart';

enum RanahDestination { home, map, news, menu }

class RanahBackButton extends StatelessWidget {
  const RanahBackButton({
    required this.onPressed,
    this.label = 'Kembali',
    super.key,
  });

  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    child: TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.arrow_back, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: TextButton.styleFrom(
        foregroundColor: RanahColors.ink,
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: RanahSpacing.md),
        minimumSize: const Size(48, 48),
        tapTargetSize: MaterialTapTargetSize.padded,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    ),
  );
}

class RanahHeader extends StatelessWidget {
  const RanahHeader({
    required this.selected,
    required this.onSelect,
    required this.onNotifications,
    super.key,
  });

  final RanahDestination selected;
  final ValueChanged<RanahDestination> onSelect;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 600;
        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [RanahColors.headerStart, RanahColors.headerEnd],
            ),
          ),
          child: compact
              ? _buildCompact(context, constraints.maxWidth)
              : _buildWide(context, constraints.maxWidth),
        );
      },
    );
  }

  Widget _buildWide(BuildContext context, double width) {
    final navWidth = width < 760 ? 64.0 : 72.0;
    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: RanahSpacing.lg),
        child: Row(
          children: [
            _Brand(),
            const SizedBox(width: RanahSpacing.md),
            SizedBox(
              width: width < 760 ? 180 : 220,
              height: 56,
              child: const _BrandLabel(),
            ),
            const Spacer(),
            for (final destination in RanahDestination.values)
              SizedBox(
                width: navWidth,
                child: _NavigationButton(
                  destination: destination,
                  selected: selected == destination,
                  onPressed: () => onSelect(destination),
                ),
              ),
            SizedBox(
              width: 48,
              child: _NotificationButton(onPressed: onNotifications),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompact(BuildContext context, double width) {
    const notificationWidth = 48.0;
    final contentWidth = math.max(width - 14, 135.0);
    final labelWidth = (contentWidth - 27 - 4 - notificationWidth)
        .clamp(56.0, 240.0)
        .toDouble();
    return SizedBox(
      height: 72,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: RanahSpacing.sm),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: contentWidth,
            child: Row(
              children: [
                const RanahBrandMark(size: 29),
                const SizedBox(width: RanahSpacing.sm),
                SizedBox(
                  width: labelWidth,
                  height: 48,
                  child: const _BrandLabel(compact: true),
                ),
                const Spacer(),
                SizedBox(
                  width: notificationWidth,
                  child: _NotificationButton(
                    onPressed: onNotifications,
                    compact: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RanahBottomNavigation extends StatelessWidget {
  const RanahBottomNavigation({
    required this.selected,
    required this.onSelect,
    super.key,
  });

  final RanahDestination selected;
  final ValueChanged<RanahDestination> onSelect;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [RanahColors.headerEnd, RanahColors.headerStart],
        ),
        border: Border(top: BorderSide(color: Color(0x336E6594))),
      ),
      child: SizedBox(
        height: 68,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth = math.max(constraints.maxWidth, 192.0);
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: contentWidth,
                child: Row(
                  children: [
                    for (final destination in RanahDestination.values)
                      Expanded(
                        child: _NavigationButton(
                          destination: destination,
                          selected: selected == destination,
                          compact: true,
                          onPressed: () => onSelect(destination),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}

class RanahBrandMark extends StatelessWidget {
  const RanahBrandMark({this.size = 40, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(7),
      child: Image.asset(
        'assets/images/brand_mark.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        semanticLabel: 'Logo RANAH',
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) => const RanahBrandMark(size: 38);
}

class _BrandLabel extends StatelessWidget {
  const _BrandLabel({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF061D3B),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'RANAH',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 14 : 16,
              height: 1.1,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'Aplikasi Informasi Bencana dan Evakuasi',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 9 : 10,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationButton extends StatelessWidget {
  const _NavigationButton({
    required this.destination,
    required this.selected,
    required this.onPressed,
    this.compact = false,
  });

  final RanahDestination destination;
  final bool selected;
  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (label, icon) = switch (destination) {
      RanahDestination.home => ('Awal', Icons.home_rounded),
      RanahDestination.map => ('Peta', Icons.map_rounded),
      RanahDestination.news => ('Berita', Icons.article_rounded),
      RanahDestination.menu => ('Menu', Icons.menu_rounded),
    };
    return Semantics(
      key: ValueKey('ranah-nav-${destination.name}'),
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(7),
        child: SizedBox(
          height: compact ? 68 : 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: compact ? 18 : 20,
                    color: selected ? Colors.white : RanahColors.headerMuted,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: selected ? Colors.white : RanahColors.headerMuted,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
              if (selected)
                Positioned(
                  top: compact ? 0 : null,
                  bottom: compact ? null : 0,
                  left: 7,
                  right: 7,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(2)),
                    ),
                    child: SizedBox(height: 3),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.onPressed, this.compact = false});

  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: 'Notifikasi',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 48, height: 48),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.notifications_none_rounded, size: compact ? 21 : 24),
          Positioned(
            right: -3,
            top: -3,
            child: Container(
              width: 12,
              height: 12,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: RanahColors.eruption,
                shape: BoxShape.circle,
              ),
              child: const Text(
                '3',
                style: TextStyle(color: Colors.white, fontSize: 12, height: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
