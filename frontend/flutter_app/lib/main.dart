import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/about_page.dart';
import 'package:flutter_app/scenario_selection.dart';
import 'package:flutter_app/task_group_page.dart';
import 'home_page.dart';
import 'camera.dart';
import 'summary_page.dart';
import 'welcome.dart';
import 'sign_in.dart';
import 'sign_up.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'settings.dart';
import 'package:flutter_app/Onboarding/account_setup_greeting.dart';
import 'package:flutter_app/Onboarding/account_setup_title.dart';
import 'package:flutter_app/Onboarding/account_setup_1.dart';
import 'package:flutter_app/Onboarding/account_setup_2.dart';

late List<CameraDescription> cameras;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  await Supabase.initialize(
      url: 'https://hxgnhmpjovjjsouffhqc.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh4Z25obXBqb3ZqanNvdWZmaHFjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzg1Njk5MTYsImV4cCI6MjA1NDE0NTkxNn0.oLOOe0DcRv9kdAyGwiM-3LRW0-nyz3X-z7ufOVFtsJw'
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, //this removes the debug banner
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
        '/camera': (context) => CameraPage(),
        '/scenario_sel': (context) => ScenarioSelection(),
        '/task_group_page' : (context) => TaskGroupPage(),
        '/settings': (context) => SettingsPage(),
        '/about': (context) => AboutPage(),
        '/account_setup_greeting': (context) => AccountSetupGreeting(),
        '/account_setup_title': (context) => AccountSetupTitle(),
        '/account_setup_1': (context) => AccountSetup1(),
        '/account_setup_2': (context) => AccountSetup2(),

      },
    );
  }
}
