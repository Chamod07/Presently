// painters/pose_painter.dart
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PosePainter extends CustomPainter {
  final List<Pose> poses;
  final Size absoluteImageSize;
  final InputImageRotation rotation;

  PosePainter(this.poses, this.absoluteImageSize, this.rotation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = Colors.green;

    for (final pose in poses) {
      pose.landmarks.forEach((_, landmark) {
        canvas.drawCircle(
          Offset(
            landmark.x * size.width / absoluteImageSize.width,
            landmark.y * size.height / absoluteImageSize.height,
          ),
          1,
          paint,
        );
      });

      // Draw connecting lines for pose landmarks
      void drawLine(PoseLandmarkType type1, PoseLandmarkType type2) {
        final PoseLandmark? point1 = pose.landmarks[type1];
        final PoseLandmark? point2 = pose.landmarks[type2];

        if (point1 != null && point2 != null) {
          canvas.drawLine(
            Offset(
              point1.x * size.width / absoluteImageSize.width,
              point1.y * size.height / absoluteImageSize.height,
            ),
            Offset(
              point2.x * size.width / absoluteImageSize.width,
              point2.y * size.height / absoluteImageSize.height,
            ),
            paint,
          );
        }
      }

      // Draw body lines
      drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
      drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow);
      drawLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow);
      // Add more lines as needed
    }
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return oldDelegate.absoluteImageSize != absoluteImageSize ||
        oldDelegate.poses != poses;
  }
}