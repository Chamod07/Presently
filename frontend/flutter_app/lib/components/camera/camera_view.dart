import 'dart:io';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/services/recording/constraints_manager.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import './camera_function.dart';
import 'recording_timer.dart';
import 'processing_overlay.dart'; // Add import for ProcessingOverlay
import 'package:flutter_app/services/upload/upload_service.dart'; // Add import for UploadService
import 'package:wakelock_plus/wakelock_plus.dart';
import '../scenario_selection/session_provider.dart';
import 'package:provider/provider.dart';

class CameraView extends StatefulWidget {
  CameraView(
      {Key? key,
        this.customPaint,
        required this.onImage,
        this.onCameraFeedReady,
        this.onDetectorViewModeChanged,
        this.onCameraLensDirectionChanged,
        this.initialCameraLensDirection = CameraLensDirection.front,
        this.showPoseOverlay = false})
      : super(key: key);

  final CustomPaint? customPaint;
  final Function(InputImage inputImage) onImage;
  final VoidCallback? onCameraFeedReady;
  final VoidCallback? onDetectorViewModeChanged;
  final Function(CameraLensDirection direction)? onCameraLensDirectionChanged;
  final CameraLensDirection initialCameraLensDirection;
  final bool showPoseOverlay;

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
    WakelockPlus.enable();

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

    _constraintsSubscription =
        _constraintsManager.constraintStream.listen(_handleConstraintViolation);

    _initialize();
  }

  Future<void> _handleConstraintViolation(ConstraintViolation violation) async {
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

    if (violation == ConstraintViolation.maxDurationExceeded && _isRecording) {
      try {
        setState(() {
          _isRecording = false;
          _cameraFunctions.isRecording = false;
          _cameraFunctions.stopTimer();
        });

        final videoFile =
        await _cameraFunctions.controller?.stopVideoRecording();

        if (videoFile != null) {
          // Process the recording
          await _cameraFunctions.processRecording(videoFile);

          // Stop the camera feed
          await _stopLiveFeed();

          // Show processing overlay instead of directly navigating
          Navigator.of(context).push(
            PageRouteBuilder(
              opaque: true,
              transitionDuration: const Duration(milliseconds: 500),
              pageBuilder: (context, animation, secondaryAnimation) {
                return ProcessingOverlay(
                  checkProcessingStatus: () async {
                    // Upload the video if not already uploaded
                    if (!_cameraFunctions.videoMetaData
                        .containsKey('uploadSuccess')) {
                      bool uploadSuccess = await _cameraFunctions.videoUpload();
                      _cameraFunctions.videoMetaData['uploadSuccess'] =
                          uploadSuccess;
                      return false; // Continue showing overlay
                    } else {
                      // Video already uploaded, check processing status
                      final reportId =
                      _cameraFunctions.videoMetaData['reportId'];
                      if (reportId != null) {
                        return await UploadService()
                            .checkProcessingStatus(reportId);
                      }
                      return false;
                    }
                  },
                  onProcessingComplete: () {
                    // Navigate to summary page when processing is complete
                    Navigator.pushReplacementNamed(context, '/summary',
                        arguments: {
                          'selectedIndex': 1,
                          'videoPath': _cameraFunctions.videoFilePath,
                          'metadata': _cameraFunctions.videoMetaData,
                        });

                    // Clean up local video
                    _cameraFunctions.deleteVideoLocal();
                  },
                );
              },
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
            ),
          );
        }
      } catch (e) {
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
    // Ensure we handle disposal safely
    if (mounted) {
      setState(() {
        // Update state before stopping camera feed
        _cameraFunctions.changingCameraLens = true;
      });
    }
    _stopLiveFeed();
    super.dispose();
    WakelockPlus.disable();
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
    try {
      // Set state before stopping to prevent UI updates during disposal
      if (mounted) {
        setState(() {
          _cameraFunctions.changingCameraLens = true;
        });
      }
      await _cameraFunctions.stopLiveFeed();
    } catch (e) {
      print('Error stopping camera feed in view: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _liveFeedBody());
  }

  Widget _liveFeedBody() {
    if (CameraFunctions.cameras.isEmpty) return Container();
    if (_cameraFunctions.controller == null) return Container();
    if (_cameraFunctions.changingCameraLens) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    if (_cameraFunctions.controller?.value.isInitialized == false) {
      return Container();
    }

    // Simplified check to prevent buildPreview calls on disposed controller
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Center(
            child: CameraPreview(
              _cameraFunctions.controller!,
              child: widget.showPoseOverlay ? widget.customPaint : null,
            ),
          ),
          _recordingTimerWidget(),
          _notificationWidget(),
          _switchLiveCameraToggle(),
          _shutterButton(),
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
        child: RecordingTimer(
          durationSeconds: _cameraFunctions.seconds,
          isRecording: _isRecording,
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
            0.0, _showNotification ? 0.0 : 20.0, 0.0),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: Color(0xB3000000),
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

                final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
                // Show processing notification
                showNotification("Processing video...");

                // Stop video recording and get the file
                final videoFile =
                await _cameraFunctions.controller?.stopVideoRecording();

                if (videoFile != null) {
                  // Process the recording
                  await _cameraFunctions.processRecording(videoFile);

                  // Stop the camera feed
                  await _stopLiveFeed();

                  // Show processing overlay BEFORE uploading the video
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      opaque: true,
                      transitionDuration: const Duration(milliseconds: 500),
                      pageBuilder:
                          (context, animation, secondaryAnimation) {
                        return ProcessingOverlay(
                          checkProcessingStatus: () async {
                            // Upload the video if not already uploaded
                            if (!_cameraFunctions.videoMetaData
                                .containsKey('uploadSuccess')) {
                              // First upload attempt - upload the video
                              bool uploadSuccess =
                              await _cameraFunctions.videoUpload();
                              _cameraFunctions
                                  .videoMetaData['uploadSuccess'] =
                                  uploadSuccess;

                              // Return false to keep showing the overlay
                              return false;
                            } else {
                              // Video already uploaded, check processing status
                              final reportId = _cameraFunctions
                                  .videoMetaData['reportId'];
                              if (reportId != null) {
                                return await UploadService()
                                    .checkProcessingStatus(reportId);
                              }
                              return false;
                            }
                          },
                          onProcessingComplete: () {
                            // Navigate to summary page when processing is complete
                            Navigator.pushReplacementNamed(
                                context, '/summary',
                                arguments: {
                                  'selectedIndex': 1,
                                  'videoPath':
                                  _cameraFunctions.videoFilePath,
                                  'metadata':
                                  _cameraFunctions.videoMetaData,
                                  'sessionId': sessionProvider.sessionId,
                                  'sessionName': sessionProvider.selectedName,
                                  'reportId': _cameraFunctions.videoMetaData['reportId'],
                                });

                            // Clean up the local file
                            _cameraFunctions.deleteVideoLocal();
                          },
                        );
                      },
                    ),
                  );
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
              try {
                // Start actual video recording
                await _cameraFunctions.controller!.startVideoRecording();

                setState(() {
                  _isRecording = true;
                  _cameraFunctions.isRecording = true;
                  _cameraFunctions.startTimer();
                });

                _constraintsManager.startMonitoring();
                showNotification("Recording started");
              } catch (e) {
                print("Error starting recording: $e");
                showNotification("Failed to start recording");
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
                )),
          ),
        ),
      ),
    ),
  );
}