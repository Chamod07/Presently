import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';

enum NetworkQuality {
  none,       // No connection
  poor,       // <500 Kbps
  moderate,   // 500 Kbps - 2 Mbps
  good,       // 2 Mbps - 5 Mbps
  excellent,  // >5 Mbps
}

class NetworkBandwidthMonitor {
  static final NetworkBandwidthMonitor _instance = NetworkBandwidthMonitor._internal();
  factory NetworkBandwidthMonitor() => _instance;
  NetworkBandwidthMonitor._internal();

  // Stream controller for network quality updates
  final _networkQualityController = StreamController<NetworkQuality>.broadcast();
  Stream<NetworkQuality> get networkQualityStream => _networkQualityController.stream;

  // Current network status
  NetworkQuality _currentNetworkQuality = NetworkQuality.none;
  NetworkQuality get currentNetworkQuality => _currentNetworkQuality;

  // Connection type
  ConnectivityResult? _connectionType;
  ConnectivityResult? get connectionType => _connectionType;

  // Last measured bandwidth in Kbps
  double _lastMeasuredBandwidth = 0;
  double get lastMeasuredBandwidth => _lastMeasuredBandwidth;

  // Test file URL for bandwidth measurement (small 1MB test file)
  final _testUrl = 'https://speed.hetzner.de/1MB.bin';

  // Initialize the monitor
  Future<void> initialize() async {
    // Set up connectivity change listener
    Connectivity().onConnectivityChanged.listen(_updateConnectivity);

    // Check initial connectivity
    await _checkConnectivity();
  }

  // Check current connectivity
  Future<void> _checkConnectivity() async {
    try {
      _connectionType = await Connectivity().checkConnectivity();

      if (_connectionType == ConnectivityResult.none) {
        _currentNetworkQuality = NetworkQuality.none;
        _networkQualityController.add(_currentNetworkQuality);
        return;
      }

      // If connected, measure bandwidth
      await measureBandwidth();
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      _currentNetworkQuality = NetworkQuality.none;
      _networkQualityController.add(_currentNetworkQuality);
    }
  }

  // Update connectivity status on change
  void _updateConnectivity(ConnectivityResult result) async {
    _connectionType = result;
    if (result == ConnectivityResult.none) {
      _currentNetworkQuality = NetworkQuality.none;
      _networkQualityController.add(_currentNetworkQuality);
    } else {
      await measureBandwidth();
    }
  }

  // Measure current bandwidth
  Future<double> measureBandwidth() async {
    if (_connectionType == ConnectivityResult.none) {
      _lastMeasuredBandwidth = 0;
      _updateNetworkQuality();
      return 0;
    }

    try {
      final stopwatch = Stopwatch()..start();
      final response = await http.get(Uri.parse(_testUrl))
          .timeout(const Duration(seconds: 10));
      stopwatch.stop();

      if (response.statusCode == 200) {
        // Calculate bandwidth in Kbps
        final fileSizeInBits = response.bodyBytes.length * 8;
        final durationInSeconds = stopwatch.elapsedMilliseconds / 1000;
        _lastMeasuredBandwidth = (fileSizeInBits / 1000) / durationInSeconds;

        _updateNetworkQuality();
        return _lastMeasuredBandwidth;
      } else {
        debugPrint('Failed to download test file: ${response.statusCode}');
        _lastMeasuredBandwidth = 0;
        _updateNetworkQuality();
        return 0;
      }
    } catch (e) {
      debugPrint('Error measuring bandwidth: $e');
      _lastMeasuredBandwidth = 0;
      _updateNetworkQuality();
      return 0;
    }
  }

  // Light bandwidth check (ping)
  Future<bool> isNetworkReachable() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Update network quality based on measured bandwidth
  void _updateNetworkQuality() {
    if (_lastMeasuredBandwidth <= 0) {
      _currentNetworkQuality = NetworkQuality.none;
    } else if (_lastMeasuredBandwidth < 500) {
      _currentNetworkQuality = NetworkQuality.poor;
    } else if (_lastMeasuredBandwidth < 2000) {
      _currentNetworkQuality = NetworkQuality.moderate;
    } else if (_lastMeasuredBandwidth < 5000) {
      _currentNetworkQuality = NetworkQuality.good;
    } else {
      _currentNetworkQuality = NetworkQuality.excellent;
    }

    _networkQualityController.add(_currentNetworkQuality);
  }

  // Get user-friendly network quality description
  String getNetworkQualityDescription() {
    switch (_currentNetworkQuality) {
      case NetworkQuality.none:
        return 'No connection';
      case NetworkQuality.poor:
        return 'Poor connection';
      case NetworkQuality.moderate:
        return 'Moderate connection';
      case NetworkQuality.good:
        return 'Good connection';
      case NetworkQuality.excellent:
        return 'Excellent connection';
    }
  }

  // Dispose resources
  void dispose() {
    _networkQualityController.close();
  }
}