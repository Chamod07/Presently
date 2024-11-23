import 'package:flutter/material.dart';
import 'home_page.dart';
import 'camera.dart';
import 'summary_page.dart';

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
      home: HomePage(),
      routes: {
        '/summary': (context) => SummaryPage(),
        '/camera': (context) => RecordingScreen()
      },
    );
  }
}
