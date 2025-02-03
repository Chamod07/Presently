import 'package:flutter/material.dart';
//import 'package:flutter_app/about_page.dart';
import 'package:flutter_app/scenario_selection.dart';
import 'package:flutter_app/task_group_page.dart';
import 'home_page.dart';
import 'camera.dart';
import 'summary_page.dart';
import 'welcome.dart';
import 'sign_in.dart';
import 'sign_up.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  await Supabase.initialize(
    url: 'https://hxgnhmpjovjjsouffhqc.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh4Z25obXBqb3ZqanNvdWZmaHFjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzg1Njk5MTYsImV4cCI6MjA1NDE0NTkxNn0.oLOOe0DcRv9kdAyGwiM-3LRW0-nyz3X-z7ufOVFtsJw',
  );
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
        '/task_group_page' : (context) => TaskGroupPage(),
      },
    );
  }
}
