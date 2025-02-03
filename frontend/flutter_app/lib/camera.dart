import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'pose_detector_view.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const CameraPage());
}

class CameraPage extends StatelessWidget {
  const CameraPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const PoseDetectorScreen(),
    );
  }
}

class PoseDetectorScreen extends StatelessWidget {
  const PoseDetectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PoseDetectorView(),
    );
  }
}