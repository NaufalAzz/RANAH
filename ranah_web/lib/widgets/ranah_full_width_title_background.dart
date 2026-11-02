import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/ranah_theme.dart';

/// Extends a page title's background to the viewport while keeping the title
/// content constrained to the width it had in its page layout.
class RanahFullWidthTitleBackground extends StatelessWidget {
  const RanahFullWidthTitleBackground({
    required this.color,
    required this.child,
    this.maxContentWidth,
    this.bottomBorder,
    super.key,
  });

  final Color color;
  final Widget child;
  final double? maxContentWidth;
  final BorderSide? bottomBorder;

  @override
  Widget build(BuildContext context) {
    final viewportWidth = MediaQuery.sizeOf(context).width;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        border: bottomBorder == null ? null : Border(bottom: bottomBorder!),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxContentWidth ?? viewportWidth,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// A vertically scrolling page where the title background spans the viewport
/// and the title contents and page body remain centered at a shared max width.
class RanahPageScrollLayout extends StatelessWidget {
  const RanahPageScrollLayout({
    required this.maxContentWidth,
    required this.title,
    required this.content,
    this.horizontalInset = 0,
    this.titleTopPadding = 0,
    this.bottomPadding = RanahSpacing.xxl,
    super.key,
  });

  final double maxContentWidth;
  final double horizontalInset;
  final double titleTopPadding;
  final double bottomPadding;
  final Widget title;
  final Widget content;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final viewportWidth = constraints.maxWidth.isFinite
          ? constraints.maxWidth
          : MediaQuery.sizeOf(context).width;
      final pageWidth = math.min(maxContentWidth, viewportWidth);
      final contentWidth = math.max(0.0, pageWidth - horizontalInset * 2);

      return SingleChildScrollView(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (titleTopPadding > 0) SizedBox(height: titleTopPadding),
            title,
            Center(
              child: SizedBox(width: contentWidth, child: content),
            ),
          ],
        ),
      );
    },
  );
}

/// Lets a child span the viewport while it sits inside an inset page column.
class RanahFullBleed extends StatelessWidget {
  const RanahFullBleed({required this.height, required this.child, super.key});

  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final viewportWidth = MediaQuery.sizeOf(context).width;
      return SizedBox(
        width: constraints.maxWidth,
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: (constraints.maxWidth - viewportWidth) / 2,
              top: 0,
              width: viewportWidth,
              height: height,
              child: child,
            ),
          ],
        ),
      );
    },
  );
}
