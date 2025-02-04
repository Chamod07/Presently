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
import 'settings.dart';
import 'task_group_page.dart';

late List<CameraDescription> cameras;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
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
        '/camera': (context) => CameraPage(),
        '/scenario_sel': (context) => ScenarioSelection(),
        '/task_group_page' : (context) => TaskGroupPage(),
        '/settings': (context) => SettingsPage(),
        '/about': (context) => AboutPage(),
      },
    );
  }
}
