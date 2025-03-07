import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/components/scenario_selection/session_provider.dart';
import 'package:flutter_app/components/settings/about_page.dart';
import 'package:flutter_app/components/scenario_selection/scenario_selection.dart';
import 'package:flutter_app/components/tasks/task_failed.dart';
import 'package:flutter_app/components/tasks/task_group_page.dart';
import 'package:flutter_app/components/dashboard/home_page.dart';
import 'package:flutter_app/components/camera/camera.dart';
import 'package:flutter_app/components/summary/summary_page.dart';
import 'package:flutter_app/components/onboarding/welcome.dart';
import 'package:flutter_app/components/signin_signup/sign_in.dart';
import 'package:flutter_app/components/signin_signup/sign_up.dart';
import 'package:flutter_app/components/tasks/task_passed.dart';
import 'package:flutter_app/components/settings/settings.dart';
import 'package:flutter_app/components/onboarding/account_setup_greeting.dart';
import 'package:flutter_app/components/onboarding/account_setup_title.dart';
import 'package:flutter_app/components/onboarding/account_setup_1.dart';
import 'package:flutter_app/components/onboarding/account_setup_2.dart';
import 'package:flutter_app/screens/splash_screen.dart';
import 'package:flutter_app/screens/error_page.dart';
import 'package:flutter_app/services/supabase_service.dart'; // Fixed import path
import 'package:supabase_flutter/supabase_flutter.dart'; // Added missing import


late List<CameraDescription> cameras;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();

  // Initialize the Supabase service before running the app
  final supabaseService = SupabaseService();

  try {
    await supabaseService.initialize(
      supabaseUrl: 'https://hxgnhmpjovjjsouffhqc.supabase.co',
      supabaseKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh4Z25obXBqb3ZqanNvdWZmaHFjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDA4MzA1MTIsImV4cCI6MjA1NjQwNjUxMn0.wH9-Y1b58RHloQj3bFSJj4gAkx3lVn4wKB9vJ5w6SZk',
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        autoRefreshToken: true,
      ),
    );
    print('Supabase initialized successfully');
  } catch (e) {
    print('Error initializing Supabase: $e');
    // Handle initialization error appropriately
  }

  runApp(ChangeNotifierProvider(
    create: (context) => SessionProvider(),
    child: MyApp(),
  ));
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
        '/task_group_page': (context) => TaskGroupPage(),
        '/settings': (context) => SettingsPage(),
        '/about': (context) => AboutPage(),
        '/account_setup_greeting': (context) => AccountSetupGreeting(),
        '/account_setup_title': (context) => AccountSetupTitle(),
        '/account_setup_1': (context) => AccountSetup1(),
        '/account_setup_2': (context) => AccountSetup2(),
        '/task_pass': (context) => TaskPassed(),
        '/task_failed': (context) => TaskFailed(),
      },
    );
  }
}
