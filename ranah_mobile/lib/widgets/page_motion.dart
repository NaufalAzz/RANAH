import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

const pageTransitionDuration = Duration(milliseconds: 280);

Widget slidePage(
  Widget child,
  Animation<double> progress, {
  Offset from = const Offset(.075, 0),
}) => FadeTransition(
  opacity: progress,
  child: SlideTransition(
    position: Tween(begin: from, end: Offset.zero).animate(progress),
    child: child,
  ),
);

class RanahPageSwitcher extends StatelessWidget {
  const RanahPageSwitcher({
    required this.rootPageKey,
    required this.child,
    super.key,
  });

  final Key rootPageKey;

  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : pageTransitionDuration,
    switchInCurve: Curves.easeOutCubic,
    switchOutCurve: Curves.easeInQuad,
    transitionBuilder: (page, progress) => page.key == rootPageKey
        ? slidePage(page, progress, from: const Offset(-.055, 0))
        : slidePage(page, progress),
    layoutBuilder: (current, previous) => Stack(
      alignment: Alignment.center,
      children: [
        for (final page in [...previous, ?current])
          ExcludeFocus(
            key: page.key,
            excluding: page != current,
            child: ExcludeSemantics(
              excluding: page != current,
              child: IgnorePointer(ignoring: page != current, child: page),
            ),
          ),
      ],
    ),
    child: child,
  );
}

/// Keeps each tab mounted while only the active and fading pages are painted.
class RanahTabStack extends StatelessWidget {
  const RanahTabStack({required this.index, required this.children, super.key});

  final int index;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final paintOrder = List<int>.generate(children.length, (i) => i)
      ..remove(index)
      ..add(index);
    return Material(
      color: AppColors.primaryDark,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            for (final i in paintOrder)
              TweenAnimationBuilder<double>(
                key: ValueKey(i),
                tween: Tween(end: i == index ? 1 : 0),
                duration: reduced ? Duration.zero : pageTransitionDuration,
                curve: Curves.easeInOutCubic,
                child: ExcludeFocus(
                  excluding: i != index,
                  child: ExcludeSemantics(
                    excluding: i != index,
                    child: IgnorePointer(
                      ignoring: i != index,
                      child: TickerMode(
                        enabled: i == index,
                        child: children[i],
                      ),
                    ),
                  ),
                ),
                builder: (context, value, child) {
                  final opacity = reduced ? (i == index ? 1.0 : 0.0) : value;
                  return Offstage(
                    offstage: i != index && opacity == 0,
                    child: Opacity(
                      opacity: opacity,
                      child: Transform.translate(
                        offset: Offset(0, 14 * (1 - opacity)),
                        child: child,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
