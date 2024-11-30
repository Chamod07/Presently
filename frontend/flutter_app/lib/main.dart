// import 'package:flutter/material.dart';
// import 'home_page.dart';
// import 'camera.dart';
// import 'summary_page.dart';
// import 'task_group_page.dart';
//
// void main() {
//   runApp(MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Presently App',
//       theme: ThemeData(
//         primarySwatch: Colors.purple,
//       ),
//       home: HomePage(),
//       routes: {
//         '/summary': (context) => SummaryPage(),
//         '/camera': (context) => RecordingScreen(),
//         '/task_group': (context) => TaskGroupPage()
//       },
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'task_group_page.dart'; // Import your TaskGroupPage file

void main() {
  runApp( MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Group Page Test',
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      home: TaskGroupPage(), // Remove const here
    );
  }
}
