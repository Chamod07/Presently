import 'package:flutter/material.dart';

class RecordingConstraints {
  // Maximum recording time in seconds
  static const int maxRecordingDuration = 300; // 5 minutes

  // Minimum recording time in seconds
  static const int minRecordingDuration = 30; // 30 seconds

  // Warning time in seconds (when to notify user recording is almost at max)
  static const int warningTime = 30; // 30 seconds before max

  // Get time left in seconds
  static int getTimeLeft(int currentDuration) {
    return maxRecordingDuration - currentDuration;
  }

  // Check if recording length is valid
  static bool isValidRecordingLength(int durationInSeconds) {
    return durationInSeconds >= minRecordingDuration &&
        durationInSeconds <= maxRecordingDuration;
  }

  // Check if we should show warning
  static bool shouldShowWarning(int currentDuration) {
    return getTimeLeft(currentDuration) <= warningTime;
  }
}