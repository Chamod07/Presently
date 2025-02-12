import 'package:flutter/material.dart';
//import 'package:flutter_app/about_page.dart';
import 'package:flutter_app/scenario_selection.dart';
import 'package:flutter_app/task_group_page.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/Onboarding/account_setup_greeting.dart';
import 'package:flutter_app/Onboarding/account_setup_title.dart';
import 'package:flutter_app/Onboarding/account_setup_1.dart';
import 'package:flutter_app/Onboarding/account_setup_2.dart';
import 'info_card.dart';
import 'home_page.dart';
import 'camera.dart';
import 'summary_page.dart';
import 'welcome.dart';
import 'sign_in.dart';
import 'sign_up.dart';
import 'session_provider.dart';
import 'task_failed.dart';
import 'task_passed.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() {
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
        '/info_card': (context) => InfoCard(),
        '/account_setup_greeting': (context) => AccountSetupGreeting(),
        '/account_setup_title': (context) => AccountSetupTitle(),
        '/account_setup_1': (context) => AccountSetup1(),
        '/account_setup_2': (context) => AccountSetup2(),
       '/task_passed': (context) => TaskPassed(),
        '/task_failed': (context) => TaskFailed(),
      },
    );
  }
}
