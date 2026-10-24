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
              height: 38,
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
    final navWidth = width < 360 ? 36.0 : 43.0;
    final labelWidth = (width - 14 - 27 - 4 - navWidth * 4 - 28).clamp(
      56.0,
      100.0,
    );
    return SizedBox(
      height: 48,
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
            const SizedBox(width: 4),
            SizedBox(
              width: labelWidth,
              height: 31,
              child: const _BrandLabel(compact: true),
            ),
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
              width: 30,
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
            'Disaster Evacuation',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 8 : 12,
              height: 1.1,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'Aplikasi Siaga Bencana Erupsi',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 5.5 : 10,
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
      RanahDestination.home => ('Home', Icons.home_rounded),
      RanahDestination.map => ('Map', Icons.map_rounded),
      RanahDestination.news => ('News', Icons.article_rounded),
      RanahDestination.menu => ('Menu', Icons.menu_rounded),
    };
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(7),
        child: SizedBox(
          height: 52,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: compact ? 12 : 16,
                color: selected ? Colors.white : const Color(0xFF62627C),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: compact ? 8 : 12,
                  color: selected ? Colors.white : const Color(0xFF77768B),
                  fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
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
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints.tightFor(
        width: compact ? 28 : 40,
        height: 40,
      ),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.notifications_none_rounded, size: compact ? 16 : 21),
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
                style: TextStyle(color: Colors.white, fontSize: 7, height: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
