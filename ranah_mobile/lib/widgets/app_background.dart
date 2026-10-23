import 'package:flutter/material.dart';

abstract final class AppBackground {
  static const decoration = BoxDecoration(
    image: DecorationImage(
      image: AssetImage('assets/images/App.png'),
      fit: BoxFit.cover,
    ),
  );
}
