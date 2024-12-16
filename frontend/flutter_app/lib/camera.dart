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
            child: _cameraController != null &&
                    _cameraController!.value.isInitialized
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
                          fontSize: 14.0),
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
