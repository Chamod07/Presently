import 'package:flutter/material.dart';
import 'package:flutter_app/scenario_selection.dart';
import 'home_page.dart';
import 'camera.dart';
import 'summary_page.dart';
import 'welcome.dart';
import 'sign_in.dart';
import 'sign_up.dart';
import 'settings.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
        scaffoldBackgroundColor: Colors.white, // set background color to white
      ),
      home: WelcomePage(),
      routes: {
        '/sign_in': (context) => SignInPage(),
        '/sign_up': (context) => SignUpPage(),
        '/home': (context) => HomePage(),
        '/summary': (context) => SummaryPage(),
        '/camera': (context) => RecordingScreen(),
        '/scenario_sel': (context) => ScenarioSelection(),
        '/settings': (context) => SettingsPage(),
      },
    );
  }
}
