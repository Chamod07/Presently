import 'dart:math';
import 'dart:collection';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' hide Colors;
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
String _lastPose = ''; // Stores the last logged pose

enum ArmPosture { open, closed, neutral }

class PostureFrame {
  final ArmPosture posture;
  final double confidence;
  final DateTime timestamp;

  PostureFrame(this.posture, this.confidence, this.timestamp);
}

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
  final PoseDetector _poseDetector = PoseDetector(options: PoseDetectorOptions());
  final Queue<PostureFrame> _postureHistory = Queue<PostureFrame>();
  final int _historyLength = 5; // Number of frames to keep for smoothing
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
  // Helper function to check for landmark presence and confidence
    bool _isValidLandmark(PoseLandmark? landmark) {
        return landmark != null && landmark.likelihood >= PoseDetectionConfig.minConfidence;
    }

 (ArmPosture, double) _classifyArmPosture(Pose pose) {
    final landmarks = pose.landmarks;

    // Required landmarks
    final lShldr = landmarks[PoseLandmarkType.leftShoulder];
    final rShldr = landmarks[PoseLandmarkType.rightShoulder];
    final lElbow = landmarks[PoseLandmarkType.leftElbow];
    final rElbow = landmarks[PoseLandmarkType.rightElbow];
    final lWrist = landmarks[PoseLandmarkType.leftWrist];
    final rWrist = landmarks[PoseLandmarkType.rightWrist];
    final lHip = landmarks[PoseLandmarkType.leftHip];
    final rHip = landmarks[PoseLandmarkType.rightHip];

    // Landmark availability and confidence check
    if (!_isValidLandmark(lShldr) || !_isValidLandmark(rShldr) ||
        !_isValidLandmark(lElbow) || !_isValidLandmark(rElbow) ||
        !_isValidLandmark(lWrist) || !_isValidLandmark(rWrist) ||
        !_isValidLandmark(lHip) || !_isValidLandmark(rHip)) {
      return (ArmPosture.neutral, 0.0); // Insufficient confidence
    }

    // Calculate torso metrics
    final torsoCenter = Vector2(
      (lHip!.x + rHip!.x) / 2,
      (lHip!.y + rHip!.y) / 2
    );
    final torsoHeight = (lHip!.y - lShldr!.y).abs();

    // Elbow angles
    final lAngle = _calculateAngle(
      Vector2(lShldr!.x, lShldr!.y),
      Vector2(lElbow!.x, lElbow!.y),
      Vector2(lWrist!.x, lWrist!.y)
    );
    final rAngle = _calculateAngle(
      Vector2(rShldr!.x, rShldr!.y),
      Vector2(rElbow!.x, rElbow!.y),
      Vector2(rWrist!.x, rWrist!.y)
    );

    // Calculate confidence scores
    final spreadScore = _wristSpreadScore(lWrist, rWrist, lShldr, rShldr);
    final angleScore = _elbowAngleScore(lAngle, rAngle);
    final torsoDistScore = _torsoDistanceScore(lElbow, rElbow, torsoCenter, torsoHeight);
    final crossingScore = _armCrossingScore(lWrist, rWrist, torsoCenter) ? 0.0 : 1.0;

    final totalScore = (spreadScore * 0.4) +
                      (angleScore * 0.3) +
                      (torsoDistScore * 0.2) +
                      (crossingScore * 0.1);

    if (totalScore > 0.7) return (ArmPosture.open, totalScore);
    if (totalScore < 0.3) return (ArmPosture.closed, totalScore);
    return (ArmPosture.neutral, totalScore);

  }

  double _calculateAngle(Vector2 a, Vector2 b, Vector2 c) {
    final radians = (b - a).angleTo(c - b);
    final degrees = radians * (180.0 / pi);
    return degrees;
  }

  // Placeholder scoring functions (to be implemented later)
  double _wristSpreadScore(PoseLandmark? lWrist, PoseLandmark? rWrist, PoseLandmark? lShoulder, PoseLandmark? rShoulder) {
    if (!_isValidLandmark(lWrist) || !_isValidLandmark(rWrist) || !_isValidLandmark(lShoulder) || !_isValidLandmark(rShoulder)) {
      return 0.5; // Neutral
    }

    final shoulderWidth = _calculateDistance(lShoulder, rShoulder);
    final wristDistance = _calculateDistance(lWrist, rWrist);
    final normalizedWristDistance = shoulderWidth > 0 ? wristDistance / shoulderWidth : 0.0;

    if (normalizedWristDistance > 1.2) return 1.0; // Open
    if (normalizedWristDistance < 0.8) return 0.0; // Closed
    return 0.5; // Neutral
  }

  double _elbowAngleScore(double lAngle, double rAngle) {
      // For now, just a basic check.  Refine with proper thresholds later.
      if (lAngle > 90 && lAngle < 150 && rAngle > 90 && rAngle < 150) return 1.0; // Open
      if (lAngle < 60 && rAngle < 60) return 0.0; // Closed
      return 0.5; // Neutral
  }

    double _torsoDistanceScore(PoseLandmark? lElbow, PoseLandmark? rElbow, Vector2 torsoCenter, double torsoHeight){
        if(!_isValidLandmark(lElbow) || !_isValidLandmark(rElbow)){
            return 0.5;
        }
        final lElbowDistance = (Vector2(lElbow!.x, lElbow.y) - torsoCenter).length;
        final rElbowDistance = (Vector2(rElbow!.x, rElbow.y) - torsoCenter).length;

        final normalizedLElbowDistance = lElbowDistance/torsoHeight;
        final normalizedRElbowDistance = rElbowDistance/torsoHeight;

        if(normalizedLElbowDistance > 0.3 && normalizedRElbowDistance > 0.3) return 1.0;
        if(normalizedLElbowDistance < 0.2 && normalizedRElbowDistance < 0.2) return 0.0;

        return 0.5;
    }

  bool _armCrossingScore(PoseLandmark? lWrist, PoseLandmark? rWrist, Vector2 torsoCenter) {
    if (!_isValidLandmark(lWrist) || !_isValidLandmark(rWrist)) {
      return false; // Can't determine
    }
      //basic check
      return lWrist!.x > rWrist!.x;
  }

    Future<void> _processImage(InputImage inputImage) async {
      if (!_canProcess) return;
      if (_isBusy) return;
      _isBusy = true;

      try {
        final poses = await _poseDetector.processImage(inputImage);

        if (poses.isNotEmpty) {
          final pose = poses.first;
          final (currentPosture, confidence) = _classifyArmPosture(pose);
          _updatePostureHistory(currentPosture, confidence);

          // Throttled logging.  _smoothedPosture is set by _updatePostureHistory
          if (_smoothedPosture.toString() != _lastPose ||
              DateTime.now().difference(_lastLogTime).inSeconds >=
                  PoseDetectionConfig.logIntervalSeconds) {
            developer.log(
                'Current pose: ${_smoothedPosture.toString().split('.').last} (Confidence: ${_smoothedConfidence.toStringAsFixed(2)})',
                name: 'PoseDetection');
            _lastLogTime = DateTime.now();
            _lastPose = _smoothedPosture.toString();
          }

          if (_showPosePainter) {
            if (inputImage.metadata?.size != null &&
                inputImage.metadata?.rotation != null) {
              final painter = PosePainter(
                poses,
                inputImage.metadata!.size,
              inputImage.metadata!.rotation,
              _smoothedPosture,
              _smoothedConfidence
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

  ArmPosture _smoothedPosture = ArmPosture.neutral;
  double _smoothedConfidence = 0.0;

  void _updatePostureHistory(ArmPosture posture, double confidence) {
    _postureHistory.addFirst(PostureFrame(posture, confidence, DateTime.now()));
    if (_postureHistory.length > _historyLength) {
      _postureHistory.removeLast();
    }

    // Calculate smoothed posture and confidence
    double totalWeight = 0.0;
    double weightedSum = 0.0;
    double confidenceSum = 0.0;
    int i = 0;
    for (final frame in _postureHistory) {
      final weight = pow(0.8, i).toDouble(); // Exponential decay for older frames
      totalWeight += weight;
      weightedSum += frame.posture.index * weight; // Use enum index for weighted average
      confidenceSum += frame.confidence * weight;
      i++;
    }

    final averagePosture = (weightedSum / totalWeight).round();
    _smoothedPosture = ArmPosture.values[averagePosture];
    _smoothedConfidence = confidenceSum / totalWeight;
  }
}
