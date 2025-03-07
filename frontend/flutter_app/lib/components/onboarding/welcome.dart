import 'package:flutter/material.dart';
import '../../utils/route_transitions.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
            child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
            child: Center(
                child: Text("Presently",
                    style: TextStyle(
                        fontFamily: 'Cookie',
                        fontSize: 100,
                        color: Color(0xFF7300B8))))),
        Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton.icon(
              onPressed: () {
                final route = Navigator.of(context)
                    .widget
                    .onGenerateRoute!(RouteSettings(name: '/sign_in'));
                Navigator.of(context).push(SlidePageRoute(
                  page: Builder(
                      builder: (context) => route is MaterialPageRoute
                          ? route.builder(context)
                          : Container()),
                  direction: SlideDirection.fromRight,
                ));
              },
              icon: Icon(Icons.arrow_forward),
              label: Text(
                "Let's Get Started!",
                style: TextStyle(
                    fontSize: 17,
                    color: Color(0xFF7400B8),
                    fontFamily: 'Roboto'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Color(0xFF7400B8))),
              ),
            ))
      ],
    )));
  }
}
