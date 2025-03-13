import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'mlkit_service.dart'; // Import for ArmPosture

class PosePainter extends CustomPainter {
  final List<Pose> poses;
  final Size absoluteImageSize;
  final InputImageRotation rotation;
  final ArmPosture armPosture; // Add armPosture
  final double confidence;    // Add confidence

  PosePainter(this.poses, this.absoluteImageSize, this.rotation, this.armPosture, this.confidence);


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
      drawLine(PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist);
      drawLine(PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist);
      drawLine(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);
      drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip);
      drawLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip);
    }

    // Display arm posture and confidence
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 20.0,
    );
    final textSpan = TextSpan(
      text: 'Posture: ${armPosture.toString().split('.').last} ($confidence)',
      style: textStyle,
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(
      minWidth: 0,
      maxWidth: size.width,
    );
    final xCenter = (size.width - textPainter.width) / 2;
    final yCenter = (size.height - textPainter.height) / 2;
    final offset = Offset(xCenter, yCenter);
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return oldDelegate.absoluteImageSize != absoluteImageSize ||
        oldDelegate.poses != poses || oldDelegate.armPosture != armPosture || oldDelegate.confidence != confidence;
  }
}
