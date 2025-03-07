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
import '/services/supabase_service.dart';

late List<CameraDescription> cameras;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();

  // Initialize the Supabase service before running the app
  final supabaseService = SupabaseService();

  try {
    await supabaseService.initialize(
      supabaseUrl: 'https://hxgnhmpjovjjsouffhqc.supabase.co',
      supabaseKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh4Z25obXBqb3ZqanNvdWZmaHFjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDA4MzA1MTIsImV4cCI6MjA1NjQwNjUxMn0.wH9-Y1b58RHloQj3bFSJj4gAkx3lVn4wKB9vJ5w6SZk',
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        autoRefreshToken: true,
      ));
    );
    print('Supabase initialized successfully');
  } catch (e) {
    print('Error initializing Supabase: $e');
    // Handle initialization error appropriately
  }
  
  runApp(ChangeNotifierProvider(
    create: (context) => SessionProvider(),
    child: const MyApp(),
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
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/sign_in': (context) => const SignInPage(),
        '/sign_up': (context) => const SignUpPage(),
        '/home': (context) => HomePage(),
        '/summary': (context) => const SummaryPage(),
        '/camera': (context) => CameraPage(),
        '/scenario_sel': (context) => const ScenarioSelection(),
        '/task_group_page': (context) => const TaskGroupPage(),
        '/settings': (context) => const SettingsPage(),
        '/about': (context) => const AboutPage(),
        '/account_setup_greeting': (context) => const AccountSetupGreeting(),
        '/account_setup_title': (context) => const AccountSetupTitle(),
        '/account_setup_1': (context) => const AccountSetup1(),
        '/account_setup_2': (context) => const AccountSetup2(),
        '/task_pass': (context) => const TaskPassed(),
        '/task_failed': (context) => const TaskFailed(),
        '/welcome': (context) => const WelcomePage(),
        '/error': (context) =>
            const ErrorPage(message: 'Navigation error occurred'),
      },
      // Handle routes that aren't explicitly defined
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => ErrorPage(
            message: 'Cannot navigate to ${settings.name}',
          ),
        );
      },
      // Fallback for navigation failures
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const ErrorPage(
            message: 'Navigation failed',
          ),
        );
      },
    );
  }
}
