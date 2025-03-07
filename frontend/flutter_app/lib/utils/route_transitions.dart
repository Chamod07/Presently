import 'package:flutter/material.dart';

/// Defines directions for slide transitions
enum SlideDirection {
  fromRight,
  fromLeft,
  fromBottom,
  fromTop,
}

/// Custom page route that creates slide transitions
class SlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final SlideDirection direction;
  final Duration duration;

  SlidePageRoute({
    required this.page,
    this.direction = SlideDirection.fromRight,
    this.duration = const Duration(milliseconds: 300),
    RouteSettings? settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            var begin = _getBeginOffset(direction);
            var end = Offset.zero;
            var curve = Curves.easeInOut;

            var tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);

            return SlideTransition(position: offsetAnimation, child: child);
          },
          transitionDuration: duration,
          settings: settings,
        );

  static Offset _getBeginOffset(SlideDirection direction) {
    switch (direction) {
      case SlideDirection.fromRight:
        return const Offset(1.0, 0.0);
      case SlideDirection.fromLeft:
        return const Offset(-1.0, 0.0);
      case SlideDirection.fromBottom:
        return const Offset(0.0, 1.0);
      case SlideDirection.fromTop:
        return const Offset(0.0, -1.0);
    }
  }
}

/// Helper function to navigate to a named route with slide animation
void navigateToNamedWithSlide(
  BuildContext context,
  String routeName, {
  SlideDirection direction = SlideDirection.fromRight,
  Duration duration = const Duration(milliseconds: 300),
  bool replace = false,
  Object? arguments,
}) {
  final RouteSettings settings =
      RouteSettings(name: routeName, arguments: arguments);
  final Route<dynamic>? generatedRoute =
      Navigator.of(context).widget.onGenerateRoute!(settings);
  final Widget pageWidget = generatedRoute is MaterialPageRoute
      ? generatedRoute.builder(context)
      : Container(); // Fallback widget if route isn't MaterialPageRoute

  final Route route = SlidePageRoute(
    page: pageWidget,
    direction: direction,
    duration: duration,
    settings: settings,
  );

  if (replace) {
    Navigator.of(context).pushReplacement(route);
  } else {
    Navigator.of(context).push(route);
  }
}
