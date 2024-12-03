import 'package:flutter/material.dart';
//import 'home_page.dart';
//import 'camera.dart';
//import 'summary_page.dart';
import 'sign_in.dart';
import 'sign_up.dart';
import 'welcome.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Presently App',
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      home: WelcomePage(),
      routes: {
        '/sign_in': (context) => SignInPage(),
        '/sign_up': (context) => SignUpPage()
      },
    );
  }
}
