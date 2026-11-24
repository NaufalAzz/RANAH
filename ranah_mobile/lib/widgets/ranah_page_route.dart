import 'package:flutter/material.dart';

import 'page_motion.dart';

class RanahPageRoute<T> extends PageRouteBuilder<T> {
  RanahPageRoute({
    required BuildContext context,
    required WidgetBuilder builder,
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) =>
             builder(context),
         transitionDuration: _transitionDuration(context),
         reverseTransitionDuration: _transitionDuration(context),
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           final curvedAnimation = animation.drive(
             CurveTween(curve: Curves.easeOutCubic),
           );
           return MediaQuery.disableAnimationsOf(context)
               ? child
               : slidePage(child, curvedAnimation);
         },
       );

  static Duration _transitionDuration(BuildContext context) =>
      MediaQuery.of(context).disableAnimations
      ? Duration.zero
      : pageTransitionDuration;
}
