import 'dart:io';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/services/recording/constraints_manager.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import './camera_function.dart';
import 'recording_timer.dart';

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
  // UI state variables
  bool _isRecording = false;
  bool _showNotification = false;
  String _notificationMessage = 'Test one';
  bool _showPositionGuide = true;

  // Camera functionality handler
  late CameraFunctions _cameraFunctions;

  late ConstraintsManager _constraintsManager;
  StreamSubscription? _constraintsSubscription;
  @override
  void initState() {
    super.initState();

    // Initialize the camera functions
    _cameraFunctions = CameraFunctions(
      onImage: widget.onImage,
      setState: setState,
      onCameraFeedReady: widget.onCameraFeedReady,
      onDetectorViewModeChanged: widget.onDetectorViewModeChanged,
      onCameraLensDirectionChanged: widget.onCameraLensDirectionChanged,
      initialCameraLensDirection: widget.initialCameraLensDirection,
    );
    //initialize constrains manager
    _constraintsManager = ConstraintsManager();

    _constraintsSubscription = _constraintsManager.constraintStream.listen(_handleConstraintViolation);

    _initialize();
  }

  Future<void> _handleConstraintViolation(ConstraintViolation violation) async{
    String message = '';
    switch (violation) {
      case ConstraintViolation.insufficientStorage:
        message = 'Insufficient storage space';
        break;
      case ConstraintViolation.lowBattery:
        message = 'Low battery';
        break;
      case ConstraintViolation.maxDurationExceeded:
        message = 'Maximum recording duration exceeded';
        break;
      default:
        break;
    }

    showNotification(message);

    if(violation == ConstraintViolation.maxDurationExceeded && _isRecording){
      try{
        setState(() {
          _isRecording = false;
          _cameraFunctions.isRecording = false;
          _cameraFunctions.stopTimer();
        });

        final videoFile = await _cameraFunctions.controller?.stopVideoRecording();

        if(videoFile != null){
          await _cameraFunctions.processRecording(videoFile);

          bool uploadSuccess = await _cameraFunctions.videoUpload();

          if(uploadSuccess){
            _dismissNotification();
            _cameraFunctions.videoMetaData['uploadSuccess'] = true;
          }
          else{
            showNotification("Error saving video");
          }
          await _stopLiveFeed();
          Navigator.pushReplacementNamed(
            context,
            '/summary',
            arguments: {
              'selectedIndex': 1,
              'videoPath': _cameraFunctions.videoFilePath,
              'metadata': _cameraFunctions.videoMetaData,
            }
          );
        }
      }
      catch(e){
        print("Error handling max duration: $e");
        showNotification("Error processing video");
        _stopLiveFeed().then((_) {
          Navigator.pushReplacementNamed(context, '/summary');
        });
      }
    }

  }

  void _initialize() async {
    await _cameraFunctions.initialize();
  }

  @override
  void dispose() {
    _constraintsSubscription?.cancel();
    _constraintsManager.dispose();
    _stopLiveFeed();
    super.dispose();
  }

  void showNotification(String message) {
    setState(() {
      _notificationMessage = message;
      _showNotification = true;
    });

    // Auto-dismiss after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _dismissNotification();
      }
    });
  }

  void _dismissNotification() {
    setState(() {
      _showNotification = false;
    });
  }

  Future<void> _stopLiveFeed() async {
    await _cameraFunctions.stopLiveFeed();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _liveFeedBody());
  }

  Widget _liveFeedBody() {
    if (CameraFunctions.cameras.isEmpty) return Container();
    if (_cameraFunctions.controller == null) return Container();
    if (_cameraFunctions.controller?.value.isInitialized == false) return Container();

    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Center(
            child: _cameraFunctions.changingCameraLens
                ? Center(
              child: const Text('Changing camera lens'),
            )
                :GestureDetector(
              onTap:(){
                if(!_isRecording){
                  setState(() {
                    _showPositionGuide = !_showPositionGuide;
                  });
                }
              },
              child: CameraPreview(
                _cameraFunctions.controller!,
                child: widget.customPaint,
              ),
            ),
          ),
          _positionGuideOverlay(),
          _recordingTimerWidget(),
          _notificationWidget(),
          _switchLiveCameraToggle(),
          _shutterButton(), // Add the summary button to the stack
        ],
      ),
    );
  }

  Widget _recordingTimerWidget() => Positioned(
    top: 40,
    left: 0,
    right: 0,
    child: AnimatedOpacity(
      opacity: _isRecording ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Center(
        child: RecordingTimer(durationSeconds: _cameraFunctions.seconds, isRecording: _isRecording,
        ),
      ),
    ),
  );

  Widget _switchLiveCameraToggle() => Positioned(
    bottom: 69,
    right: 50,
    child: SizedBox(
      height: 60.0,
      width: 60.0,
      child: FloatingActionButton(
        heroTag: Object(),
        onPressed: () => _cameraFunctions.switchLiveCamera(),
        backgroundColor: Colors.black54,
        child: Icon(
          Platform.isIOS
              ? Icons.flip_camera_ios_outlined
              : Icons.flip_camera_android_outlined,
          size: 30,
          color: Colors.white,
        ),
      ),
    ),
  );

  Widget _notificationWidget() => Positioned(
    bottom: 150, // Position above the shutter button
    left: 20,
    right: 20,
    child: AnimatedOpacity(
      opacity: _showNotification ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        transform: Matrix4.translationValues(
            0.0,
            _showNotification ? 0.0 : 20.0,
            0.0
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.redAccent, width: 1.5),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.redAccent,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _notificationMessage,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: _dismissNotification,
            ),
          ],
        ),
      ),
    ),
  );

  Widget _positionGuideOverlay() => Positioned.fill(
    child: IgnorePointer(
      child: AnimatedOpacity(
        opacity: (_showPositionGuide && !_isRecording) ? 0.7 : 0.0, // Only show when not recording
        duration: const Duration(milliseconds: 300),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Face position guide
            Center(
              child: Container(
                width: 220,
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(150),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 80), // Space for face position
                    Text(
                      'Position your face here',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 8.0,
                            color: Colors.black,
                            offset: Offset(0, 0),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Quality indicator in top-left
            Positioned(
              top: 50,
              left: 20,
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _cameraFunctions.hasGoodLighting ? Icons.light_mode : Icons.light_mode_outlined,
                      color: _cameraFunctions.hasGoodLighting ? Colors.green : Colors.orange,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Lighting',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

            // Position indicator in top-right
            Positioned(
              top: 50,
              right: 20,
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _cameraFunctions.isFaceWellPositioned ? Icons.face : Icons.face_outlined,
                      color: _cameraFunctions.isFaceWellPositioned ? Colors.green : Colors.orange,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Position',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

            // Tap to dismiss text at the bottom
            Positioned(
              bottom: 160,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Tap anywhere to hide guide',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    shadows: [
                      Shadow(
                        blurRadius: 8.0,
                        color: Colors.black,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  //the ready to record indicator
  Widget _readyToRecordIndicator() => Positioned(
    bottom: 135, // Position it above the shutter button
    left: 0,
    right: 0,
    child: Center(
      child: AnimatedOpacity(
        opacity: (!_isRecording && _cameraFunctions.isRecordingQualitySufficient) ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(
                Icons.check_circle,
                color: Colors.greenAccent,
                size: 16,
              ),
              SizedBox(width: 8),
              Text(
                'Ready to record',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _shutterButton() => Positioned(
    bottom: 62, // Position it above the bottom controls
    left: 0,
    right: 0,
    child: Center(
      child: SizedBox(
        height: 80.0,
        width: 200.0,
        child: GestureDetector(
          onTap: () async {
            if (_isRecording) {
              // Stop recording
              setState(() {
                _isRecording = false;
                _cameraFunctions.isRecording = false;
                _cameraFunctions.stopTimer();
              });
              _constraintsManager.stopMonitoring();
              try {
                // Show processing notification
                showNotification("Processing video...");

                // Stop video recording and get the file
                final videoFile = await _cameraFunctions.controller?.stopVideoRecording();

                final String? videoPath = _cameraFunctions.videoFilePath;
                final videoMetaData = Map<String, dynamic>.from(_cameraFunctions.videoMetaData);

                if (videoFile != null) {
                  // Process the video (save and generate metadata)
                  await _cameraFunctions.processRecording(videoFile);

                  bool uploadSuccess = await _cameraFunctions.videoUpload();

                  if(uploadSuccess){
                    _dismissNotification();
                    videoMetaData['uploadSuccess'] = true;
                  }
                  else{
                    showNotification("Error saving video");
                  }

                  // Stop the camera feed and navigate to summary page

                  await _stopLiveFeed();
                  Navigator.pushReplacementNamed(
                      context,
                      '/summary',
                      arguments: {
                        'selectedIndex': 1,
                        'videoPath': videoPath,
                        'metadata': videoMetaData,
                      }
                  );

                  await _cameraFunctions.deleteVideoLocal();
                }
              } catch (e) {
                print("Error stopping recording: $e");
                showNotification("Error stopping video");

                // Fall back to original behavior if recording fails
                _stopLiveFeed().then((_) {
                  Navigator.pushReplacementNamed(context, '/summary');
                });
              }
            } else {
              // Check conditions before starting recording
              bool conditionsGood = await _cameraFunctions.checkRecordingConditions();

              if (conditionsGood) {
                try {
                  // Start actual video recording
                  await _cameraFunctions.controller!.startVideoRecording();

                  setState(() {
                    _isRecording = true;
                    _cameraFunctions.isRecording = true;
                    _cameraFunctions.startTimer();
                  });
                  showNotification("Recording started");
                } catch (e) {
                  print("Error starting recording: $e");
                  showNotification("Failed to start recording");
                }
              }
            }
          },
          child: Container(
            width: 100.0,
            height: 100.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 5),
            ),
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedOpacity(
                    opacity: _isRecording ? 0.0 : 1.0,
                    duration: Duration(milliseconds: 300),
                    child: Container(
                      width: 74.0,
                      height: 74.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  AnimatedOpacity(
                      opacity: _isRecording ? 1.0 : 0.0,
                      duration: Duration(milliseconds: 300),
                    child: Container(
                      width: 40.0,
                      height: 40.0,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              )

              ),
            ),
          ),
        ),
      ),
  );
}