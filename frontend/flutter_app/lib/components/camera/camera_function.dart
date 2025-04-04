import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import '../../services/upload/upload_service.dart';
import '../../services/supabase/supabase_service.dart';
import '../../providers/report_provider.dart';

class CameraFunctions {
  // Camera variables
  static List<CameraDescription> cameras = [];
  CameraController? controller;
  int cameraIndex = -1;
  double currentZoomLevel = 1.0;
  double minAvailableZoom = 1.0;
  double maxAvailableZoom = 1.0;
  double minAvailableExposureOffset = 0.0;
  double maxAvailableExposureOffset = 0.0;
  double currentExposureOffset = 0.0;
  bool changingCameraLens = false;

  // Recording states
  bool isRecording = false;
  Timer? timer;
  int seconds = 0;



  // Video data
  File? recordedVideoFile;
  Map<String, dynamic> videoMetaData = {};
  String? videoFilePath;
  XFile? videoFile;

    // Callbacks
  final VoidCallback? onCameraFeedReady;
  final Function(CameraLensDirection direction)? onCameraLensDirectionChanged;
    final CameraLensDirection initialCameraLensDirection;

  // State update callback
    final Function setState;

//instanciating report provider
    final ReportProvider? reportProvider;

  CameraFunctions({
    required this.setState,
    this.onCameraFeedReady,
    this.onCameraLensDirectionChanged,
        this.initialCameraLensDirection = CameraLensDirection.front,
        this.reportProvider
  });

  Future<void> initialize() async {
    if (cameras.isEmpty) {
      cameras = await availableCameras();
    }
    for (var i = 0; i < cameras.length; i++) {
      if (cameras[i].lensDirection == initialCameraLensDirection) {
        cameraIndex = i;
        break;
      }
    }
    if (cameraIndex != -1) {
      await startLiveFeed();
    }
  }

  void startTimer() {
    seconds = 0;
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        seconds++;
      });
    });
  }

  void stopTimer() {
    timer?.cancel();
    timer = null;
  }

  String formatTime() {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds
        .toString()
        .padLeft(2, '0')}';
  }



  Future<void> startLiveFeed() async {
    final camera = cameras[cameraIndex];
    controller = CameraController(
      camera,
      //set to medium 480p resolution can try changing to high 720p
      ResolutionPreset.medium,
      enableAudio: true,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    try {
      await controller?.initialize();

      // Prepare for video recording
      await controller?.prepareForVideoRecording();

      // Get zoom levels
      currentZoomLevel = await controller?.getMinZoomLevel() ?? 1.0;
      minAvailableZoom = currentZoomLevel;
      maxAvailableZoom = await controller?.getMaxZoomLevel() ?? 1.0;

      // Set exposure
      currentExposureOffset = 0.0;
      minAvailableExposureOffset =
          await controller?.getMinExposureOffset() ?? 0.0;
      maxAvailableExposureOffset =
          await controller?.getMaxExposureOffset() ?? 0.0;

      // Try to set optimal focus mode
      try {
        await controller?.setFocusMode(FocusMode.auto);
      } catch (e) {
        print('Focus mode setting not supported: $e');
      }

      // Call callbacks
      if (onCameraFeedReady != null) {
        onCameraFeedReady!();
      }
      if (onCameraLensDirectionChanged != null) {
        onCameraLensDirectionChanged!(camera.lensDirection);
      }

      setState(() {});
    } catch (e) {
      print('Error setting up camera feed: $e');
    }
  }

  Future<void> stopLiveFeed() async {
    try {
      if (controller != null) {
        // First, stop recording if active
        if (isRecording && controller!.value.isRecordingVideo) {
          try {
            await controller!.stopVideoRecording();
          } catch (e) {
            print('Error stopping video recording: $e');
          }
          isRecording = false;
        }

        // Then stop image stream (do this only once)
        if (controller!.value.isStreamingImages) {
          try {
            await controller!.stopImageStream();
          } catch (e) {
            print('Error stopping image stream: $e');
          }
        }

        // Finally, dispose the controller
        try {
          await controller!.dispose();
        } catch (e) {
          print('Error disposing camera controller: $e');
        }

        // Always set controller to null after attempted disposal
        controller = null;
      }
    } catch (e) {
      print('Error stopping live feed: $e');
      controller = null;
    }
  }

  Future<void> switchLiveCamera() async {
    setState(() => changingCameraLens = true);
    cameraIndex = (cameraIndex + 1) % cameras.length;

    await stopLiveFeed();
    await startLiveFeed();
    setState(() => changingCameraLens = false);
  }

    Future<void> processRecording(XFile videoFile) async {
    try {
      recordedVideoFile = File(videoFile.path);

      // Create timestamp and recording ID
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final recordingId = 'rec_$timestamp';

      // Generate metadata
      videoMetaData = {
        'recordingId': recordingId,
        'timestamp': DateTime.now().toIso8601String(),
        'duration': seconds,
        'recordingSettings': {
          'resolution': controller?.value.previewSize?.toString() ?? 'unknown',
          'camera': cameras[cameraIndex].lensDirection.toString(),
          'audioEnabled': true,
        },
      };

      // Get app directory
      final appDir = await getApplicationDocumentsDirectory();
      final videoDir = Directory('${appDir.path}/recordings/$recordingId');

      // Create directory if it doesn't exist
      if (!await videoDir.exists()) {
        await videoDir.create(recursive: true);
      }

      // Save video file to app directory
      final savedVideoPath = '${videoDir.path}/recording.mp4';
      await recordedVideoFile!.copy(savedVideoPath);
      videoFilePath = savedVideoPath;

      // Save metadata alongside the video
      final metadataFile = File('${videoDir.path}/metadata.json');
      await metadataFile.writeAsString(jsonEncode(videoMetaData));

      print('Video saved to: $savedVideoPath');
      print('Metadata saved to: ${metadataFile.path}');
    } catch (e) {
      print('Error processing video: $e');
      throw Exception("Failed to process recording: $e");
    }
  }

  Future<bool> videoUpload() async {
    try {
      if (videoFilePath != null && videoMetaData.isNotEmpty) {
        final videoFile = File(videoFilePath!);

        // Set up listener for upload completion
        StreamSubscription? statusSubscription;
        final completer = Completer<bool>();

        final userId =  SupabaseService().currentUserId;
        if(userId == null) {
          print('User ID not found');
          return false;
        }
        //fetching report ID from supabase
        final response = await SupabaseService().client.from('UserReport').select('reportId').eq('userId', userId).order('createdAt', ascending: false).limit(1).maybeSingle();


        String? reportId;
        if (response != null) {
          reportId = response['reportId'];
        } else {
          print('No user report found for this user');
          return false;
        }


        if (reportId == null) {
          print('Report ID is null, cannot upload video');
          return false;
        }


        videoMetaData['reportId'] = reportId;

        statusSubscription = UploadService().statusStream.listen((status) {
          // Check for completion status with our recording ID in the message
          if (status['status'] == 'complete' &&
              status['message'] == 'Upload complete!') {
            completer.complete(true);
            statusSubscription?.cancel();
          } else if (status['status'] == 'failed') {
            completer.complete(false);
            statusSubscription?.cancel();
          }
        });

        //calling upload service to upload video
        UploadService().uploadVideo(
          videoFile: videoFile,
          metadata: videoMetaData,
          reportId: reportId,
        );
        print('Video queued for upload: $videoFilePath');

        bool uploadSuccess = await completer.future.timeout(
          Duration(minutes: 3),
          onTimeout: () {
            statusSubscription?.cancel();
            return false;
          },
        );

        return uploadSuccess;
      }
      return false;
    } catch (e) {
      print('Error in videoUpload: $e');
      return false;
    }
  }

  Future<void> deleteVideoLocal() async {
    try {
      if (videoFilePath != null) {
        final videoFile = File(videoFilePath!);
        final directory = videoFile.parent;

        if (await directory.exists()) {
          await directory.delete(recursive: true);
          print('Local recording deleted: ${directory.path}');
        }

        videoFilePath = null;
        recordedVideoFile = null;
      }
    } catch (e) {
      print('Error in deleteVideo: $e');
    }
  }
}
