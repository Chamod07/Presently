import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  _RecordingScreenState createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isRecording = false;
  bool _showPopup = true; // Controls the popup visibility.

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    _cameraController = CameraController(
      _cameras![0],
      ResolutionPreset.high,
    );
    await _cameraController!.initialize();
    setState(() {});
  }

  void _toggleCamera() async {
    if (_cameras == null || _cameraController == null) return;
    int newIndex = (_cameras!.indexOf(_cameraController!.description) + 1) %
        _cameras!.length;
    _cameraController = CameraController(
      _cameras![newIndex],
      ResolutionPreset.high,
    );
    await _cameraController!.initialize();
    setState(() {});
  }

  void _startRecording() async {
    if (_cameraController == null || _isRecording) return;
    await _cameraController!.startVideoRecording();
    setState(() {
      _isRecording = true;
      _showPopup = true; // Show popup when recording starts (example behavior).
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
          'Recording Screen',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera Preview
          Positioned.fill(
            child: _cameraController != null &&
                _cameraController!.value.isInitialized
                ? CameraPreview(_cameraController!)
                : const Center(child: CircularProgressIndicator()),
          ),

          // Popup Message
          if (_showPopup)
            Positioned(
              bottom: 200.0, // Adjust position vertically
              left: 16.0, // Adjust position horizontally
              right: 16.0,
              child: Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF1DD), // Light yellow background
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.orangeAccent),
                        SizedBox(width: 8.0),
                        Text(
                          'Skill issues!!!',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 14.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showPopup = false; // Hide popup when closed
                        });
                      },
                      child: const Icon(
                        Icons.close,
                        color: Colors.black54,
                        size: 20.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Controls Section
          Positioned(
            bottom: 32.0,
            left: 0,
            right: 0,
            child: Column(
              children: [
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
                            style: TextStyle(
                                color: Colors.white, fontSize: 14.0),
                          ),
                          Text(
                            'Recording',
                            style: TextStyle(
                                color: _isRecording
                                    ? Colors.red
                                    : Colors.white,
                                fontSize: 14.0),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.flip_camera_ios,
                          color: Colors.white, size: 32.0),
                      onPressed: _toggleCamera,
                    ),
                    IconButton(
                      icon: Icon(
                        _isRecording ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 48.0,
                      ),
                      onPressed:
                      _isRecording ? _stopRecording : _startRecording,
                    ),
                    IconButton(
                      icon: const Icon(Icons.stop,
                          color: Colors.red, size: 32.0),
                      onPressed: _stopRecording,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
