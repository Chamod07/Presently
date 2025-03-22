import 'package:flutter/material.dart';

class CustomPageTransitionBuilder extends PageTransitionsBuilder {
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Create a custom fade+slide transition
    const begin = Offset(0.0, 0.05);
    const end = Offset.zero;
    const curve = Curves.easeOutQuint;

    final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
    final offsetAnimation = animation.drive(tween);

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: offsetAnimation,
        child: child,
      ),
    );
  }
}
