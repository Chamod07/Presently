import 'dart:io';
import 'dart:async'; // Add Timer import
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

class CameraView extends StatefulWidget {
  CameraView(
      {Key? key,
        required this.customPaint,
        required this.onImage,
        this.onCameraFeedReady,
        this.onDetectorViewModeChanged,
        this.onCameraLensDirectionChanged,
        this.initialCameraLensDirection = CameraLensDirection.front})
      : super(key: key);

  final CustomPaint? customPaint;
  final Function(InputImage inputImage) onImage;
  final VoidCallback? onCameraFeedReady;
  final VoidCallback? onDetectorViewModeChanged;
  final Function(CameraLensDirection direction)? onCameraLensDirectionChanged;
  final CameraLensDirection initialCameraLensDirection;

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  static List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _cameraIndex = -1;
  double _currentZoomLevel = 1.0;
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;
  double _minAvailableExposureOffset = 0.0;
  double _maxAvailableExposureOffset = 0.0;
  double _currentExposureOffset = 0.0;
  bool _changingCameraLens = false;

  // Add zoom slider related variables
  bool _isZoomSliderVisible = false;
  Timer? _zoomSliderTimer;
  double _baseScale = 1.0;

  // Add recording related variables
  bool _isRecording = false;
  bool _isPaused = false;
  int _recordingDuration = 0; // in seconds
  Timer? _recordingTimer;
  final int _maxRecordingDuration = 120; // 2 minutes in seconds
  String? _videoPath;

  @override
  void initState() {
    super.initState();

    _initialize();
  }

  void _initialize() async {
    if (_cameras.isEmpty) {
      _cameras = await availableCameras();
    }
    for (var i = 0; i < _cameras.length; i++) {
      if (_cameras[i].lensDirection == widget.initialCameraLensDirection) {
        _cameraIndex = i;
        break;
      }
    }
    if (_cameraIndex != -1) {
      _startLiveFeed();
    }
  }

  @override
  void dispose() {
    _zoomSliderTimer?.cancel();
    _recordingTimer?.cancel();
    _stopRecording();
    _stopLiveFeed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
          child: _liveFeedBody(),
        )
    );
  }

  Widget _liveFeedBody() {
    if (_cameras.isEmpty) return Container();
    if (_controller == null) return Container();
    if (_controller?.value.isInitialized == false) return Container();
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Center(
            child: _changingCameraLens
                ? Center(
              child: const Text('Changing camera lens'),
            )
                : GestureDetector(
              onScaleStart: _handleScaleStart,
              onScaleUpdate: _handleScaleUpdate,
              onScaleEnd: _handleScaleEnd,
              child: CameraPreview(
                _controller!,
                child: widget.customPaint,
              ),
            ),
          ),
          _backButton(),
          _zoomSliderControl(), // Only keep the dynamic zoom slider
          _bottomControls(),
        ],
      ),
    );
  }

  Widget _backButton() => Positioned(
    top: 40,
    left: 8,
    child: SizedBox(
      height: 50.0,
      width: 50.0,
      child: FloatingActionButton(
        heroTag: Object(),
        onPressed: () => Navigator.of(context).pop(),
        backgroundColor: Colors.black54,
        child: Icon(
          Icons.arrow_back_ios_outlined,
          size: 20,
        ),
      ),
    ),
  );

  // Combined bottom control area with timeline, shutter and camera buttons
  Widget _bottomControls() => Positioned(
    bottom: 0,
    left: 0,
    right: 0,
    child: Container(
      padding: EdgeInsets.only(bottom: 20, top: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Timeline bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 15),
            child: Column(
              children: [
                // Time display
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isRecording ? Icons.circle : Icons.circle_outlined,
                        color: _isRecording ? Colors.red : Colors.white,
                        size: 14,
                      ),
                      SizedBox(width: 5),
                      Text(
                        _formatDuration(_recordingDuration),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                // Timeline progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _recordingDuration / _maxRecordingDuration,
                    backgroundColor: Colors.white30,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _isRecording ? Colors.red : Colors.white,
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),

          // Camera controls row with switch camera, shutter, and pause buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Empty space
                Spacer(flex: 1),

                // Left side - Switch Camera button
                SizedBox(
                  height: 50.0,
                  width: 50.0,
                  child: FloatingActionButton(
                    heroTag: "switchCamera",
                    onPressed: _switchLiveCamera,
                    backgroundColor: Colors.black54,
                    child: Icon(
                      Platform.isIOS
                          ? Icons.flip_camera_ios_outlined
                          : Icons.flip_camera_android_outlined,
                      color: Colors.white,
                      size: 25,
                    ),
                  ),
                ),

                // Space between switch camera and shutter
                SizedBox(width: 30),

                // Center - Shutter button
                GestureDetector(
                  onTap: _handleShutterPress,
                  child: Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 4,
                      ),
                    ),
                    child: Center(
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        height: _isRecording ? 40 : 70,
                        width: _isRecording ? 40 : 70,
                        decoration: BoxDecoration(
                          color: _isRecording ? Colors.red : Colors.white,
                          borderRadius: BorderRadius.circular(_isRecording ? 8 : 35),
                        ),
                      ),
                    ),
                  ),
                ),

                // Space between shutter and pause
                SizedBox(width: 30),

                // Right side - Pause/Resume button
                SizedBox(
                  height: 50.0,
                  width: 50.0,
                  child: FloatingActionButton(
                    heroTag: "pauseResume",
                    onPressed: _isRecording ? _togglePause : null,
                    backgroundColor: _isRecording ? Colors.black54 : Colors.black38,
                    child: Icon(
                      _isPaused ? Icons.play_arrow : Icons.pause,
                      color: _isRecording ? Colors.white : Colors.white60,
                      size: 25,
                    ),
                  ),
                ),

                // Empty space
                Spacer(flex: 1),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  // Improved zoom slider with slide animation
  Widget _zoomSliderControl() => AnimatedPositioned(
    duration: Duration(milliseconds: 300),
    curve: Curves.easeInOut,
    top: 40, // Position at same height as exposure control
    right: _isZoomSliderVisible ? 8 : -70, // Slide in/out from right edge
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: 250,
      ),
      child: Column(children: [
        Container(
          width: 55,
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Text(
                '${_currentZoomLevel.toStringAsFixed(1)}x',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
        Expanded(
          child: RotatedBox(
            quarterTurns: 3,
            child: SizedBox(
              height: 30,
              child: Slider(
                value: _currentZoomLevel,
                min: _minAvailableZoom,
                max: _maxAvailableZoom,
                activeColor: Colors.white,
                inactiveColor: Colors.white30,
                onChanged: (value) async {
                  // First update the slider position for immediate feedback
                  setState(() {
                    _currentZoomLevel = value;
                  });

                  // Then apply the zoom to the camera
                  if (_controller != null) {
                    await _controller!.setZoomLevel(value);
                  }

                  // Reset the auto-hide timer
                  _zoomSliderTimer?.cancel();
                  _zoomSliderTimer = Timer(Duration(seconds: 3), () {
                    if (mounted) {
                      setState(() {
                        _isZoomSliderVisible = false;
                      });
                    }
                  });
                },
              ),
            ),
          ),
        )
      ]),
    ),
  );

  Future _startLiveFeed() async {
    final camera = _cameras[_cameraIndex];
    _controller = CameraController(
      camera,
      // Set to ResolutionPreset.high. Do NOT set it to ResolutionPreset.max because for some phones does NOT work.
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );
    _controller?.initialize().then((_) {
      if (!mounted) {
        return;
      }
      _controller?.getMinZoomLevel().then((value) {
        _currentZoomLevel = value;
        _minAvailableZoom = value;
      });
      _controller?.getMaxZoomLevel().then((value) {
        _maxAvailableZoom = value;
      });
      _currentExposureOffset = 0.0;
      _controller?.getMinExposureOffset().then((value) {
        _minAvailableExposureOffset = value;
      });
      _controller?.getMaxExposureOffset().then((value) {
        _maxAvailableExposureOffset = value;
      });
      _controller?.startImageStream(_processCameraImage).then((value) {
        if (widget.onCameraFeedReady != null) {
          widget.onCameraFeedReady!();
        }
        if (widget.onCameraLensDirectionChanged != null) {
          widget.onCameraLensDirectionChanged!(camera.lensDirection);
        }
      });
      setState(() {});
    });
  }

  Future _stopLiveFeed() async {
    await _controller?.stopImageStream();
    await _controller?.dispose();
    _controller = null;
  }

  Future _switchLiveCamera() async {
    setState(() => _changingCameraLens = true);
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;

    await _stopLiveFeed();
    await _startLiveFeed();
    setState(() => _changingCameraLens = false);
  }

  void _processCameraImage(CameraImage image) {
    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) return;
    widget.onImage(inputImage);
  }

  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_controller == null) return null;

    // get image rotation
    // it is used in android to convert the InputImage from Dart to Java: https://github.com/flutter-ml/google_ml_kit_flutter/blob/master/packages/google_mlkit_commons/android/src/main/java/com/google_mlkit_commons/InputImageConverter.java
    // `rotation` is not used in iOS to convert the InputImage from Dart to Obj-C: https://github.com/flutter-ml/google_ml_kit_flutter/blob/master/packages/google_mlkit_commons/ios/Classes/MLKVisionImage%2BFlutterPlugin.m
    // in both platforms `rotation` and `camera.lensDirection` can be used to compensate `x` and `y` coordinates on a canvas: https://github.com/flutter-ml/google_ml_kit_flutter/blob/master/packages/example/lib/vision_detector_views/painters/coordinates_translator.dart
    final camera = _cameras[_cameraIndex];
    final sensorOrientation = camera.sensorOrientation;
    // print(
    //     'lensDirection: ${camera.lensDirection}, sensorOrientation: $sensorOrientation, ${_controller?.value.deviceOrientation} ${_controller?.value.lockedCaptureOrientation} ${_controller?.value.isCaptureOrientationLocked}');
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation =
      _orientations[_controller!.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        // front-facing
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        // back-facing
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
      // print('rotationCompensation: $rotationCompensation');
    }
    if (rotation == null) return null;
    // print('final rotation: $rotation');

    // get image format
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    // validate format depending on platform
    // only supported formats:
    // * nv21 for Android
    // * bgra8888 for iOS
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) return null;

    // since format is constraint to nv21 or bgra8888, both only have one plane
    if (image.planes.length != 1) return null;
    final plane = image.planes.first;

    // compose InputImage using bytes
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation, // used only in Android
        format: format, // used only in iOS
        bytesPerRow: plane.bytesPerRow, // used only in iOS
      ),
    );
  }

  // Handle pinch to zoom gestures
  void _handleScaleStart(ScaleStartDetails details) {
    _baseScale = _currentZoomLevel;
    // Show zoom slider when user starts scaling
    setState(() {
      _isZoomSliderVisible = true;
    });

    // Cancel any existing timer
    _zoomSliderTimer?.cancel();
  }

  Future<void> _handleScaleUpdate(ScaleUpdateDetails details) async {
    // Don't allow zoom operations during lens switching
    if (_controller == null || _changingCameraLens) {
      return;
    }

    // Calculate new zoom level
    double scale = (_baseScale * details.scale).clamp(_minAvailableZoom, _maxAvailableZoom);

    // Only update if changed enough (avoid jitter)
    if ((scale - _currentZoomLevel).abs() > 0.01) {
      // First update the UI
      setState(() {
        _currentZoomLevel = scale;
      });

      // Then apply zoom to camera
      await _controller!.setZoomLevel(scale);

      // Reset timer as user is still interacting
      _zoomSliderTimer?.cancel();
    }
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    // Start timer to hide zoom slider after 3 seconds
    _zoomSliderTimer?.cancel();
    _zoomSliderTimer = Timer(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isZoomSliderVisible = false;
        });
      }
    });
  }

  // Format duration to MM:SS
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Handle shutter button press
  void _handleShutterPress() {
    if (_isRecording) {
      _stopRecording().then((_) {
        // Navigate to summary page after stopping
        Navigator.pushReplacementNamed(context, '/summary');
      });
    } else {
      _startRecording();
    }
  }

  // Toggle pause/resume recording
  void _togglePause() async {
    if (!_isRecording) return;

    try {
      if (_isPaused) {
        await _controller?.resumeVideoRecording();
        _recordingTimer?.cancel();
        _recordingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
          setState(() {
            _recordingDuration++;
          });

          if (_recordingDuration >= _maxRecordingDuration) {
            _stopRecording().then((_) {
              Navigator.pushReplacementNamed(context, '/summary');
            });
          }
        });
      } else {
        await _controller?.pauseVideoRecording();
        _recordingTimer?.cancel();
      }

      setState(() {
        _isPaused = !_isPaused;
      });
    } catch (e) {
      print('Error toggling recording pause: $e');
    }
  }

  // Start video recording
  Future<void> _startRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    if (_controller!.value.isRecordingVideo) {
      return;
    }

    try {
      await _controller!.startVideoRecording();

      setState(() {
        _isRecording = true;
        _isPaused = false;
        _recordingDuration = 0;
      });

      _recordingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          _recordingDuration++;
        });

        if (_recordingDuration >= _maxRecordingDuration) {
          _stopRecording().then((_) {
            Navigator.pushReplacementNamed(context, '/summary');
          });
        }
      });
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  // Stop video recording
  Future<void> _stopRecording() async {
    _recordingTimer?.cancel();

    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    if (!_controller!.value.isRecordingVideo) {
      return;
    }

    try {
      final XFile videoFile = await _controller!.stopVideoRecording();
      setState(() {
        _isRecording = false;
        _isPaused = false;
        _videoPath = videoFile.path;
      });

      return;
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }
}
