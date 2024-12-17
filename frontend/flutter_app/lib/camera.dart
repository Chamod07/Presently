import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'services/websocket_service.dart';

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  _RecordingScreenState createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isRecording = false;
  List<dynamic> _landmarks = [];

  // WebSocket service for handling communication
  final WebSocketService _webSocketService = WebSocketService();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _setupWebSocket();
  }

  void _setupWebSocket() {
    // Replace with your server's WebSocket URL
    _webSocketService.connect('ws://192.168.11.144:8000/ws');


    // Listen for landmark updates
    _webSocketService.landmarksStream.listen((landmarks) {
      setState(() {
        _landmarks = landmarks;
      });
    });
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    _cameraController = CameraController(
      _cameras![0],  // Use first available camera
      ResolutionPreset.high,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await _cameraController!.initialize();

    // Start processing frames if camera is initialized
    if (_cameraController!.value.isInitialized) {
      _webSocketService.processFrames(_cameraController!);
    }

    setState(() {});
  }

  void _toggleCamera() async {
    if (_cameras == null || _cameraController == null) return;

    int newIndex = (_cameras!.indexOf(_cameraController!.description) + 1) % _cameras!.length;

    _cameraController = CameraController(
      _cameras![newIndex],
      ResolutionPreset.high,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await _cameraController!.initialize();

    // Restart frame processing with new camera
    _webSocketService.processFrames(_cameraController!);

    setState(() {});
  }

  void _startRecording() async {
    if (_cameraController == null || _isRecording) return;

    await _cameraController!.startVideoRecording();
    setState(() {
      _isRecording = true;
    });
  }

  void _stopRecording() async {
    if (_cameraController == null || !_isRecording) return;

    await _cameraController!.stopVideoRecording();
    setState(() {
      _isRecording = false;
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _webSocketService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Class Presentation',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: _cameraController != null && _cameraController!.value.isInitialized
                ? AspectRatio(
              aspectRatio: _cameraController!.value.aspectRatio,
              child: CameraPreview(_cameraController!),
            )
                : const Center(
              child: CircularProgressIndicator(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Slider(
                  value: _isRecording ? 1.0 : 0.0,
                  min: 0.0,
                  max: 1.0,
                  onChanged: (value) {},
                  activeColor: Colors.white,
                  inactiveColor: Colors.grey,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '00:00',
                      style: TextStyle(color: Colors.white, fontSize: 14.0),
                    ),
                    Text(
                      'Recording',
                      style: TextStyle(
                        color: _isRecording ? Colors.red : Colors.white,
                        fontSize: 14.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 32.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 32.0),
                  onPressed: _toggleCamera,
                ),
                IconButton(
                  icon: Icon(
                    _isRecording ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 48.0,
                  ),
                  onPressed: _isRecording ? _stopRecording : _startRecording,
                ),
                IconButton(
                  icon: const Icon(Icons.stop, color: Colors.red, size: 32.0),
                  onPressed: _stopRecording,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// The LandmarkPainter remains the same as in the previous implementation
class LandmarkPainter extends CustomPainter {
  final List<dynamic> landmarks;
  final double aspectRatio;

  LandmarkPainter(this.landmarks, this.aspectRatio);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 5
      ..style = PaintingStyle.fill;

    for (var landmark in landmarks) {
      canvas.drawCircle(
        Offset(landmark['x'] * size.width, landmark['y'] * size.height),
        3,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}