import 'package:flutter/material.dart';

import '../theme/ranah_theme.dart';

enum RanahDestination { home, map, news, menu }

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
              ? _buildCompact(context)
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
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            _Brand(),
            const SizedBox(width: 10),
            SizedBox(
              width: width < 760 ? 152 : 200,
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

  Widget _buildCompact(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    const navWidth = 55.0;
    const notificationWidth = 48.0;
    final showBrand = width >= 380;
    final labelWidth =
        (width - 14 - 27 - 4 - navWidth * 4 - notificationWidth - 28).clamp(
          56.0,
          100.0,
        );
    return SizedBox(
      height: 72,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Image.asset(
                'assets/images/brand_mark.png',
                width: 27,
                height: 29,
                fit: BoxFit.cover,
                semanticLabel: 'Logo RANAH',
              ),
            ),
            if (showBrand) ...[
              const SizedBox(width: 4),
              SizedBox(
                width: labelWidth,
                height: 35,
                child: const _BrandLabel(compact: true),
              ),
            ],
            const Spacer(),
            for (final destination in RanahDestination.values)
              SizedBox(
                width: navWidth,
                child: _NavigationButton(
                  destination: destination,
                  selected: selected == destination,
                  compact: true,
                  onPressed: () => onSelect(destination),
                ),
              ),
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
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(7),
      child: Image.asset(
        'assets/images/brand_mark.png',
        width: 38,
        height: 39,
        fit: BoxFit.cover,
        semanticLabel: 'Logo RANAH',
      ),
    );
  }
}

class _BrandLabel extends StatelessWidget {
  const _BrandLabel({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF061D3B),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            compact ? 'RANAH' : 'Evakuasi Bencana RANAH',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.1,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (!compact)
            Text(
              'Aplikasi Siaga Bencana Erupsi',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                height: 1.2,
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
                    style: TextStyle(
                      fontSize: 12,
                      color: selected ? Colors.white : RanahColors.headerMuted,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
              if (selected)
                const Positioned(
                  bottom: 0,
                  left: 7,
                  right: 7,
                  child: DecoratedBox(
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
      tooltip: 'Notifikasi contoh',
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
