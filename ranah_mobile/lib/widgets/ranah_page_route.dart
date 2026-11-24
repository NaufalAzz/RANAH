import 'package:flutter/material.dart';

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
           return FadeTransition(
             opacity: curvedAnimation,
             child: SlideTransition(
               position: Tween<Offset>(
                 begin: const Offset(0.025, 0),
                 end: Offset.zero,
               ).animate(curvedAnimation),
               child: child,
             ),
           );
         },
       );

  static Duration _transitionDuration(BuildContext context) =>
      MediaQuery.of(context).disableAnimations
      ? Duration.zero
      : const Duration(milliseconds: 240);
}
