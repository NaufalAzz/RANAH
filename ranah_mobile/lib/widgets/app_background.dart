import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

abstract final class AppBackground {
  static const imageAsset = 'assets/images/App.png';

  static const decoration = BoxDecoration(
    image: DecorationImage(image: AssetImage(imageAsset), fit: BoxFit.cover),
  );

  static const overlayColor = Color(0x66091C30);
  static const ringColor = Color(0x09FFFFFF);
  static const ringWidth = AppSpacing.xl;
}
