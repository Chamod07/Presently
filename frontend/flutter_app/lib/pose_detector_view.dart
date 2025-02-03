import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'camera_view.dart';

class PoseDetectorView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _PoseDetectorViewState();
}

class _PoseDetectorViewState extends State<PoseDetectorView> {
  final PoseDetector _poseDetector =
  PoseDetector(options: PoseDetectorOptions());
  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  String? _text;
  var _cameraLensDirection = CameraLensDirection.back;
  List<String> _previousFeedback = [];
  DateTime _lastUpdate = DateTime.now();

  @override
  void dispose() async {
    _canProcess = false;
    _poseDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CameraView(
      customPaint: _customPaint,
      onImage: _processImage,
      initialCameraLensDirection: _cameraLensDirection,
      onCameraLensDirectionChanged: (direction) {
        setState(() => _cameraLensDirection = direction);
      },
      text: _text, //
    );
  }

  Future<void> _processImage(InputImage inputImage) async {
    if (!_canProcess || _isBusy) return;
    _isBusy = true;

    final poses = await _poseDetector.processImage(inputImage);
    List<String> feedbacks = [];

    if (poses.isNotEmpty) {
      final pose = poses.first;
      feedbacks = _getPresentationFeedback(pose);
    }

    setState(() {
      _text = feedbacks.join('\n');
      _customPaint = null;
    });

    _isBusy = false;
  }

  List<String> _getPresentationFeedback(Pose pose) {
    List<String> feedbacks = [];
    final now = DateTime.now();

    // Upper Body Analysis
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final nose = pose.landmarks[PoseLandmarkType.nose];

    // Posture Analysis
    final shoulderYDiff = leftShoulder!.y - rightShoulder!.y;
    final hipYDiff = leftHip!.y - rightHip!.y;
    final verticalAlignment = (leftShoulder.y + rightShoulder.y) / 2 -
        (leftHip.y + rightHip.y) / 2;

    if (verticalAlignment.abs() < 0.1) {
      feedbacks.add('Slouching');
    } else if (verticalAlignment > 0.2) {
      feedbacks.add('Standing upright');
    }

    // Head/Eye Contact Analysis
    if (nose != null) {
      final headPosition = nose.x;
      if (headPosition < 0.3 || headPosition > 0.7) {
        feedbacks.add('No eye contact');
      } else if ((now.difference(_lastUpdate).inSeconds > 2) &&
          (_previousFeedback.contains('No eye contact'))) {
        feedbacks.add('Good eye contact');
      }
    }

    // Hand Gesture Analysis
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];

    double gestureScore = 0;
    if (leftWrist != null && leftElbow != null) {
      gestureScore += (leftElbow.y - leftWrist.y).abs();
    }
    if (rightWrist != null && rightElbow != null) {
      gestureScore += (rightElbow.y - rightWrist.y).abs();
    }

    if (gestureScore > 0.4) {
      feedbacks.add('Too much hand gestures');
    } else if (gestureScore > 0.2) {
      feedbacks.add('Good hand gestures');
    } else {
      feedbacks.add('No hand gestures');
    }

    // Movement Analysis
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];
    final baseStability = (leftAnkle!.x - rightAnkle!.x).abs();

    if (baseStability > 0.3) {
      feedbacks.add('Continuous movement');
    } else if (baseStability < 0.1) {
      feedbacks.add('Standing still');
    }

    // Facial Expression (Simplified)
    if (nose != null && nose.y < 0.4) {
      feedbacks.add('Good facial expressions');
    } else {
      feedbacks.add('Neutral facial expressions');
    }

    // Update tracking variables
    _lastUpdate = now;
    _previousFeedback = feedbacks;

    // Ensure only 3-4 most critical feedbacks are shown
    return feedbacks.take(4).toList();
  }
}