import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'camera_view.dart';
import 'pose_painter.dart';
import 'dart:developer' as developer;

class PoseDetectionConfig {
  static const minConfidence = 0.7;
  static const armAngleThreshold = 160; // No longer used, but kept for reference
  static const shoulderLevelThreshold = 0.1;
  static const logIntervalSeconds = 1;
  static const openArmsThreshold = 0.7; // Normalized wrist distance threshold
}

DateTime _lastLogTime = DateTime.now();
String _lastPose = '';

// No longer needed:
// double _calculateAngle(PoseLandmark? a, PoseLandmark? b, PoseLandmark? c) { ... }

bool _shouldersLevel(PoseLandmark? leftShoulder, PoseLandmark? rightShoulder) {
  if (leftShoulder == null || rightShoulder == null) return false;
  return (leftShoulder.y - rightShoulder.y).abs() <
      PoseDetectionConfig.shoulderLevelThreshold;
}

class CameraPage extends StatefulWidget {
  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final PoseDetector _poseDetector =
      PoseDetector(options: PoseDetectorOptions());
  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  bool _showPosePainter = true;

    void _togglePosePainter(){
      setState(() {
        _showPosePainter = !_showPosePainter;
      });
    }

  @override
  void dispose() {
    _canProcess = false;
    _poseDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CameraView(
      customPaint: _customPaint,
      onImage: _processImage,
      initialCameraLensDirection: CameraLensDirection.back,
    );
  }

    double _calculateDistance(PoseLandmark? a, PoseLandmark? b) {
      if (a == null || b == null) return double.infinity;
      return (a.x - b.x).abs();
    }

  bool _areArmsOpen(Pose pose) {
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];

    if (leftWrist == null ||
        rightWrist == null ||
        leftShoulder == null ||
        rightShoulder == null) {
      return false;
    }

    // Check landmark confidence
    final lowWristConfidence = leftWrist.likelihood < PoseDetectionConfig.minConfidence ||
        rightWrist.likelihood < PoseDetectionConfig.minConfidence;
    final highShoulderConfidence = leftShoulder.likelihood >= PoseDetectionConfig.minConfidence &&
        rightShoulder.likelihood >= PoseDetectionConfig.minConfidence;

    // Normalize wrist distance by shoulder width
    final shoulderWidth = _calculateDistance(leftShoulder, rightShoulder);
    final wristDistance = _calculateDistance(leftWrist, rightWrist);
    final normalizedWristDistance =
        shoulderWidth > 0 ? wristDistance / shoulderWidth : double.infinity;

    // Check if wrists are generally below the shoulders
    final wristsBelowShoulders =
        leftWrist.y > leftShoulder.y && rightWrist.y > rightShoulder.y;

    // If wrist confidence is low, but shoulder confidence is high,
    // and other conditions are met, infer open arms.
    if (lowWristConfidence && highShoulderConfidence) {
        return wristsBelowShoulders &&
               _shouldersLevel(leftShoulder, rightShoulder) &&
               normalizedWristDistance > PoseDetectionConfig.openArmsThreshold;
    }


    return normalizedWristDistance > PoseDetectionConfig.openArmsThreshold &&
        wristsBelowShoulders &&
        _shouldersLevel(leftShoulder, rightShoulder);
  }

  Future<void> _processImage(InputImage inputImage) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;

    try {
      final poses = await _poseDetector.processImage(inputImage);

      if (poses.isNotEmpty) {
        final pose = poses.first;

        final currentPose = _areArmsOpen(pose) ? 'Arms open' : 'Neutral';

        // Throttled logging
        if (currentPose != _lastPose ||
            DateTime.now().difference(_lastLogTime).inSeconds >=
                PoseDetectionConfig.logIntervalSeconds) {
          developer.log('Current pose: $currentPose', name: 'PoseDetection');
          _lastLogTime = DateTime.now();
          _lastPose = currentPose;
        }

        if (_showPosePainter) {
          if (inputImage.metadata?.size != null &&
              inputImage.metadata?.rotation != null) {
            final painter = PosePainter(
              poses,
              inputImage.metadata!.size,
              inputImage.metadata!.rotation,
            );
            _customPaint = CustomPaint(painter: painter);
          } else {
            developer.log('No metadata for pose painting', name: 'PoseDetection');
            _customPaint = null;
          }
        } else {
          _customPaint = null;
        }
      } else {
        developer.log('No poses detected', name: 'PoseDetection');
        _customPaint = null;
      }
    } catch (e) {
      developer.log('Error in pose detection: $e', name: 'PoseDetection');
    }

    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }
}
