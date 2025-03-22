import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/components/settings/faq.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/components/scenario_selection/session_provider.dart';
import 'package:flutter_app/components/settings/about_page.dart';
import 'package:flutter_app/components/scenario_selection/scenario_selection.dart';
import 'package:flutter_app/components/tasks/task_failed.dart';
import 'package:flutter_app/components/tasks/task_group_page.dart';
import 'package:flutter_app/components/dashboard/home_page.dart';
import 'package:flutter_app/services/mlkit_service.dart';
import 'package:flutter_app/components/summary/summary_page.dart';
import 'package:flutter_app/components/onboarding/welcome.dart';
import 'package:flutter_app/components/signin_signup/sign_in.dart';
import 'package:flutter_app/components/signin_signup/sign_up.dart';
import 'package:flutter_app/components/tasks/task_passed.dart';
import 'package:flutter_app/components/settings/settings.dart';
import 'package:flutter_app/components/onboarding/account_setup_greeting.dart';
import 'package:flutter_app/components/onboarding/combined_account_setup.dart';
import 'package:flutter_app/components/screens/splash_screen.dart';
import 'package:flutter_app/components/settings/contact_support.dart';
import 'package:flutter_app/components/settings/terms_privacy.dart';
import 'package:flutter_app/components/settings/help_page.dart';
import 'package:flutter_app/components/tasks/info_card.dart';
import 'services/supabase/supabase_service.dart';
import 'package:flutter_app/services/deep_link_service.dart';
import 'package:flutter_app/components/signin_signup/reset_password.dart';
import 'package:page_transition/page_transition.dart';
import 'package:flutter_app/utils/custom_page_transition.dart';

late List<CameraDescription> cameras;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Initialize the Supabase service before running the app
  final supabaseService = SupabaseService();

  try {
    await supabaseService.initialize(
      supabaseUrl: 'https://hxgnhmpjovjjsouffhqc.supabase.co',
      supabaseKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh4Z25obXBqb3ZqanNvdWZmaHFjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDA4MzA1MTIsImV4cCI6MjA1NjQwNjUxMn0.wH9-Y1b58RHloQj3bFSJj4gAkx3lVn4wKB9vJ5w6SZk',
    );
    print('Supabase initialized successfully');
  } catch (e) {
    print('Error initializing Supabase: $e');
    // Handle initialization error appropriately
  }

  runApp(MyApp(navigatorKey: navigatorKey));
}

class MyApp extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const MyApp({Key? key, required this.navigatorKey}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final SupabaseService _supabaseService;
  late final DeepLinkService _deepLinkService;

  @override
  void initState() {
    super.initState();
    _supabaseService = SupabaseService();
    _deepLinkService = DeepLinkService(_supabaseService, widget.navigatorKey);
    _deepLinkService.init();
  }

  @override
  void dispose() {
    _deepLinkService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SessionProvider(),
      child: MaterialApp(
        navigatorKey: widget.navigatorKey,
        debugShowCheckedModeBanner: false, //this removes the debug banner
        title: 'Presently App',
        theme: ThemeData(
          primarySwatch: Colors.purple,
          scaffoldBackgroundColor:
              Colors.white, // set background color to white
          // Add page transitions for the entire app
          pageTransitionsTheme: PageTransitionsTheme(
            builders: {
              TargetPlatform.android: CustomPageTransitionBuilder(),
              TargetPlatform.iOS: CustomPageTransitionBuilder(),
            },
          ),
        ),
        initialRoute: '/splash',
        routes: {
          '/splash': (context) => SplashScreen(),
          '/welcome': (context) => WelcomePage(),
          '/sign_in': (context) => SignInPage(),
          '/sign_up': (context) => SignUpPage(),
          '/home': (context) => HomePage(),
          '/summary': (context) => SummaryPage(),
          '/camera': (context) => CameraPage(),
          '/scenario_sel': (context) => ScenarioSelection(),
          '/task_group_page': (context) => TaskGroupPage(),
          '/settings': (context) => SettingsPage(),
          '/account_setup_greeting': (context) => AccountSetupGreeting(),
          '/account_setup': (context) =>
              CombinedAccountSetup(), // Updated to use combined setup
          '/task_pass': (context) => TaskPassed(),
          '/task_failed': (context) => TaskFailed(),
          '/faq': (context) => FAQPage(),
          '/contact_support': (context) => ContactSupportPage(),
          '/terms_privacy': (context) => TermsPrivacyPage(),
          '/help': (context) => HelpPage(),
          '/about': (context) => AboutPage(),
          '/reset_password': (context) => ResetPasswordPage(),
        },
        onGenerateRoute: (settings) {
          // Make sure ALL routes have transitions, not just sign_in and sign_up
          Widget page;
          switch (settings.name) {
            case '/sign_in':
              page = SignInPage();
              break;
            case '/sign_up':
              page = SignUpPage();
              break;
            case '/account_setup':
              page = CombinedAccountSetup();
              break;
            case '/account_setup_greeting':
              page = AccountSetupGreeting();
              break;
            case '/home':
              page = HomePage();
              break;
            case '/info_card':
              // Extract the arguments passed to the route
              final args = settings.arguments as Map<String, dynamic>?;

              // Return the InfoCard with the required parameters
              return MaterialPageRoute(
                builder: (context) => InfoCard(
                  taskTitle: args?['taskTitle'] ?? 'Task Title',
                  reportId: args?['reportId'],
                  taskDescription: args?['taskDescription'],
                  taskSubtitle: args?['taskSubtitle'],
                  points: args?['points'],
                  duration: args?['duration'],
                ),
              );
            // Add cases for other routes as needed
            default:
              // Use the route defined in routes map
              return null;
          }

          return PageTransition(
            type: PageTransitionType.fade,
            duration: Duration(milliseconds: 300),
            child: page,
            settings: settings,
          );
        },
      ),
    );
  }

  Widget _buildRouteWidget(RouteSettings settings) {
    switch (settings.name) {
      case '/sign_in':
        return SignInPage();
      case '/sign_up':
        return SignUpPage();
      // ...add other routes as needed
      default:
        return Container(); // Fallback
    }
  }
}
