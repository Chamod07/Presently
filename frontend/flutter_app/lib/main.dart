import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_app/components/settings/about_page.dart';
import 'package:flutter_app/components/scenario_selection/scenario_selection.dart';
import 'package:flutter_app/components/tasks/task_group_page.dart';
import 'components/onboarding/account_setup_title.dart';
import 'components/onboarding/account_setup_1.dart';
import 'components/onboarding/account_setup_2.dart';
import 'components/onboarding/account_setup_greeting.dart';
import 'components/tasks/info_card.dart';
import 'components/dashboard/home_page.dart';
import 'components/camera/camera.dart';
import 'components/summary/summary_page.dart';
import 'components/onboarding/welcome.dart';
import 'components/signin_signup/sign_in.dart';
import 'components/signin_signup/sign_up.dart';
import 'components/settings/settings.dart';
import 'components/scenario_selection/session_provider.dart';
import 'components/tasks/task_failed.dart';
import 'components/tasks/task_passed.dart';
import 'package:firebase_auth/firebase_auth.dart';

late List<CameraDescription> cameras;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  await Supabase.initialize(
      url: 'https://hxgnhmpjovjjsouffhqc.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh4Z25obXBqb3ZqanNvdWZmaHFjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzg1Njk5MTYsImV4cCI6MjA1NDE0NTkxNn0.oLOOe0DcRv9kdAyGwiM-3LRW0-nyz3X-z7ufOVFtsJw'
  );
  runApp(
    ChangeNotifierProvider(
      create: (context) => SessionProvider(),
      child: MyApp(),
    ),
  );
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
        '/info_card': (context) => InfoCard(),
        '/account_setup_greeting': (context) => AccountSetupGreeting(),
        '/account_setup_title': (context) => AccountSetupTitle(),
        '/account_setup_1': (context) => AccountSetup1(),
        '/account_setup_2': (context) => AccountSetup2(),
       '/task_passed': (context) => TaskPassed(),
        '/task_failed': (context) => TaskFailed(),
        '/settings': (context) => SettingsPage(),
        '/about': (context) => AboutPage(),
      },
    );
  }
}
