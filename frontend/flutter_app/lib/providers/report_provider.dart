import 'package:flutter/material.dart';
import 'package:flutter_app/models/report.dart';
import 'package:flutter_app/services/http_service.dart';
import 'package:flutter_app/config/config.dart';
import 'dart:convert';

class ReportProvider with ChangeNotifier {
  final String reportId = '123e4567-e89b-12d3-a456-426614174000';

  // New report structure
  PresentationReport _report = PresentationReport.empty();

  // Add session name property
  String _sessionName = "Session Analysis"; // Default name

  bool _loading = false;
  String _errorMessage = '';

  // Getters
  PresentationReport get report => _report;
  bool get loading => _loading;
  String get errorMessage => _errorMessage;
  String get sessionName => _sessionName;

  final HttpService _httpService = HttpService();

  // Update to fetch session name from the report data
  Future<void> fetchReportData() async {
    _loading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // Make API call to get full report
      final response =
          await _httpService.get('${Config.apiUrl}/report?report_id=$reportId');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Parse the complete report data
        _report = PresentationReport.fromJson(data);

        // Get the session name from the report data if available
        if (data.containsKey('session_name')) {
          _sessionName = data['session_name'] ?? "Session Analysis";
        } else if (data.containsKey('metadata') &&
            data['metadata'] is Map &&
            data['metadata'].containsKey('session_name')) {
          // Try to get it from metadata if present
          _sessionName = data['metadata']['session_name'] ?? "Session Analysis";
        }
        // Otherwise keep the default or previously set session name

        debugPrint('Successfully fetched complete report data');
      } else {
        _errorMessage = 'Failed to fetch report: ${response.statusCode}';
        debugPrint(
            'Error fetching report: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      _errorMessage = 'An unexpected error occurred: $e';
      debugPrint('Error in fetchReportData: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Method to set session name (useful when passing from navigation)
  void setSessionName(String name) {
    if (name.isNotEmpty && name != _sessionName) {
      _sessionName = name;
      notifyListeners();
    }
  }
}
