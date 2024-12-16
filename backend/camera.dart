//this needs to be modified with with proper UI for the camera recording


import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:web_socket_channel/io.dart';

void main() => runApp(PoseAnalysisApp());

class PoseAnalysisApp extends StatefulWidget {
  @override
  _PoseAnalysisAppState createState() => _PoseAnalysisAppState();
}

class _PoseAnalysisAppState extends State<PoseAnalysisApp> {
  late CameraController _cameraController;
  late IOWebSocketChannel _webSocketChannel;
  bool _isCameraInitialized = false;

  // Variables to hold evaluation results
  String goodPoses = "";
  String badPoses = "";
  String feedback = "Analyzing pose...";

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeWebSocket();
  }

  void _initializeCamera() async {
    final cameras = await availableCameras();
    final camera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
    ); // Use the front camera

    _cameraController = CameraController(camera, ResolutionPreset.medium);
    await _cameraController.initialize();

    if (!mounted) return;
    setState(() {
      _isCameraInitialized = true;
    });

    // Start streaming frames to the WebSocket
    _startStreaming();
  }

  void _initializeWebSocket() {
    // Connect to the WebSocket server
    _webSocketChannel = IOWebSocketChannel.connect('ws://192.168.11.144:8000/ws');

    // Listen for incoming WebSocket messages (pose evaluations)
    _webSocketChannel.stream.listen((data) {
      final decodedData = json.decode(data);
      final evaluation = decodedData['pose_evaluation'];

      setState(() {
        if (evaluation != null && evaluation.isNotEmpty) {
          goodPoses = evaluation['good_poses']?.join(', ') ?? "None";
          badPoses = evaluation['bad_poses']?.join(', ') ?? "None";
          feedback = evaluation['overall_feedback'] ?? "Analyzing pose...";
        } else {
          feedback = "No pose detected.";
        }
      });
    });
  }

  void _startStreaming() async {
    // Continuously send camera frames to the server
    while (_cameraController.value.isInitialized) {
      final XFile imageFile = await _cameraController.takePicture();
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      _webSocketChannel.sink.add("data:image/jpeg;base64,$base64Image");
      await Future.delayed(Duration(milliseconds: 500)); // Adjust for frame rate
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _webSocketChannel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Pose Analysis Overlay'),
          backgroundColor: Colors.black,
        ),
        backgroundColor: Colors.black,
        body: _isCameraInitialized
            ? Stack(
          children: [
            // Camera Preview
            CameraPreview(_cameraController),

            // Overlay for pose evaluation feedback
            Positioned(
              top: 20,
              left: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Good Poses:",
                    style: TextStyle(color: Colors.green, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    goodPoses,
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Areas to Improve:",
                    style: TextStyle(color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    badPoses,
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Feedback:",
                    style: TextStyle(color: Colors.blueAccent, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    feedback,
                    style: TextStyle(color: Colors.white, fontSize: 18, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ],
        )
            : Center(
          child: CircularProgressIndicator(
            color: Colors.blue,
          ),
        ),
      ),
    );
  }
}
