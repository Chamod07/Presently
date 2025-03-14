import 'dart:async';
import 'package:flutter/material.dart';
import 'recording_constraints.dart';
import 'storage_check.dart';
import 'battery_monitor.dart';

enum ConstraintViolation {
  none,
  insufficientStorage,
  lowBattery,
  maxDurationExceeded,
}

class ConstraintsManager {
  // Stream controller for constraint violations
  final _constraintController = StreamController<ConstraintViolation>.broadcast();
  Stream<ConstraintViolation> get constraintStream => _constraintController.stream;

  // Recording duration tracking
  int _currentDurationSeconds = 0;
  Timer? _durationTimer;

  // Initialize the manager
  Future<ConstraintViolation> checkInitialConstraints() async {
    // Check storage first
    if (!await StorageCheck.hasEnoughStorageSpace()) {
      return ConstraintViolation.insufficientStorage;
    }

    // Check battery next
    if (!await BatteryMonitor.isBatteryLevelSufficient()) {
      // If charging, we can still proceed
      if (!await BatteryMonitor.isCharging()) {
        return ConstraintViolation.lowBattery;
      }
    }

    return ConstraintViolation.none;
  }

  // Start monitoring constraints
  void startMonitoring() {
    _currentDurationSeconds = 0;
    _durationTimer = Timer.periodic(Duration(seconds: 1), _updateDuration);

    // Monitor battery changes
    BatteryMonitor.getBatteryStateStream().listen(_checkBatteryState);
  }

  // Update recording duration
  void _updateDuration(Timer timer) {
    _currentDurationSeconds++;

    // Check if max duration exceeded
    if (_currentDurationSeconds >= RecordingConstraints.maxRecordingDuration) {
      _constraintController.add(ConstraintViolation.maxDurationExceeded);
    }
  }

  // Check battery state changes
  void _checkBatteryState(dynamic batteryState) async {
    if (!await BatteryMonitor.isBatteryLevelSufficient() &&
        !await BatteryMonitor.isCharging()) {
      _constraintController.add(ConstraintViolation.lowBattery);
    }
  }

  // Get current recording time formatted
  String getFormattedTime() {
    final minutes = (_currentDurationSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_currentDurationSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // Get time remaining
  int getTimeRemaining() {
    return RecordingConstraints.maxRecordingDuration - _currentDurationSeconds;
  }

  // Stop monitoring
  void stopMonitoring() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  // Dispose resources
  void dispose() {
    stopMonitoring();
    _constraintController.close();
  }
}