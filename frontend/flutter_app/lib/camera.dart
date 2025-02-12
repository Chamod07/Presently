import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'camera_view.dart';
import 'pose_painter.dart';
import 'dart:developer' as developer;

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

  Future<void> _processImage(InputImage inputImage) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;

    try {
      final poses = await _poseDetector.processImage(inputImage);
      developer.log('Number of poses detected: ${poses.length}', name: 'PoseDetection');

      if (poses.isNotEmpty) {
        final pose = poses.first;
        developer.log('Pose landmarks:', name: 'PoseDetection');
        pose.landmarks.forEach((key, point) {
          developer.log('${key.name}: (${point.x}, ${point.y})', name: 'PoseDetection');
        });

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