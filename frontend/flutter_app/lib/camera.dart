import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  _RecordingScreenState createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isRecording = false;
  WebSocketChannel? _channel;
  List<dynamic> _landmarks = [];
  Timer? _frameTimer;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _connectWebSocket();
  }

  void _connectWebSocket() {
    _channel = IOWebSocketChannel.connect('ws://192.168.11.144:8000/ws');
    // For actual device, replace 10.0.2.2 with your PC's local IP
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    _cameraController = CameraController(
      _cameras![1],
      ResolutionPreset.high,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    await _cameraController!.initialize();

    // Start frame processing
    _startFrameProcessing();

    setState(() {});
  }

  void _startFrameProcessing() {
    _frameTimer = Timer.periodic(Duration(milliseconds: 500), (_) async {
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        try {
          final image = await _cameraController!.takePicture();
          Uint8List imageBytes = await image.readAsBytes();
          String base64Image = base64Encode(imageBytes);

          // Send image to WebSocket
          _channel?.sink.add('data:image/jpeg;base64,$base64Image');
        } catch (e) {
          print('Error processing frame: $e');
        }
      }
    });
  }

  void _toggleCamera() async {
    if (_cameras == null || _cameraController == null) return;
    int newIndex = (_cameras!.indexOf(_cameraController!.description) + 1) %
        _cameras!.length;
    _cameraController = CameraController(
      _cameras![newIndex],
      ResolutionPreset.high,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    await _cameraController!.initialize();
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
    _frameTimer?.cancel();
    _cameraController?.dispose();
    _channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        // ... (existing AppBar code remains the same)
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: _cameraController != null &&
                _cameraController!.value.isInitialized
                ? Stack(
              children: [
                AspectRatio(
                  aspectRatio: _cameraController!.value.aspectRatio,
                  child: CameraPreview(_cameraController!),
                ),
                // Display landmarks (optional visualization)
                CustomPaint(
                  painter: LandmarkPainter(_landmarks),
                ),
              ],
            )
                : const Center(
              child: CircularProgressIndicator(),
            ),
          ),
          // Stream landmarks from WebSocket
          StreamBuilder(
            stream: _channel?.stream,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                try {
                  _landmarks = json.decode(snapshot.data);
                } catch (e) {
                  print('Error parsing landmarks: $e');
                }
              }
              return Text(
                'Landmarks: ${_landmarks.length}',
                style: TextStyle(color: Colors.white),
              );
            },
          ),
          // ... (rest of the existing UI remains the same)
        ],
      ),
    );
  }
}

// Optional custom painter to visualize landmarks
class LandmarkPainter extends CustomPainter {
  final List<dynamic> landmarks;

  LandmarkPainter(this.landmarks);

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
          paint
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}