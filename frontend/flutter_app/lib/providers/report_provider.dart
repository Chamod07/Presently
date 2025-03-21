import 'package:flutter/material.dart';
import 'package:flutter_app/models/report.dart';
import 'package:flutter_app/services/http_service.dart';
import 'package:flutter_app/config/config.dart';
import 'dart:convert';
import '../services/supabase/supabase_service.dart';

class ReportProvider with ChangeNotifier {
  // initialize supabase service
  final SupabaseService _supabaseService = SupabaseService();
  String? userId;
  String? _reportId;
  String? _sessionId;

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
  String? get reportId => _reportId;
  String? get sessionId => _sessionId;

  final HttpService _httpService = HttpService();

  // Update to fetch session name from the report data

  Future<void> fetchReportData() async {
    if (reportId == null || reportId!.isEmpty) {
      _errorMessage = 'No report ID available';
      notifyListeners();
      return;
    }

    _loading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      debugPrint('Fetching complete report data for report ID: $reportId');
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
    debugPrint('Setting session name: $name');
    if (name.isNotEmpty && name != _sessionName) {
      _sessionName = name;
      notifyListeners();
    } else {
      debugPrint('Session name is empty or same as current name $name');
    }
  }

  // Method to set report id (useful when passing from navigation)
  void setReportId(String repid) {
    debugPrint('Setting report ID: $repid');
    if (repid.isNotEmpty && repid != reportId) {
      _reportId = repid;
      notifyListeners();
    }
  }

  // Method to set session id (useful when passing from navigation)
  void setSessionId(String sesid) {
    debugPrint('Setting session ID: $sesid');
    if (sesid.isNotEmpty && sesid != sessionId) {
      _sessionId = sesid;
      notifyListeners();
    }
  }

  // Method to fetch report ID from UserReport table in Supabase
  Future<String?> fetchReportIdFromSupabase({String? sessionId}) async {
    if (sessionId == null && _sessionId == null) {
      debugPrint('No session ID provided, cannot fetch report ID');
      return null;
    }

    final String targetSessionId = sessionId ?? _sessionId!;
    final userId = await _supabaseService.currentUserId;

    if (userId == null) {
      debugPrint('No user ID available, cannot fetch report ID');
      return null;
    }

    try {
      debugPrint('Fetching report ID for session: $targetSessionId');
      final response = await _supabaseService.client
          .from("UserReport")
          .select("reportId")
          .eq("userId", userId)
          .eq("session_id", targetSessionId)
          .order('createdAt', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null && response['reportId'] != null) {
        final String fetchedReportId = response['reportId'];
        debugPrint('Successfully fetched report ID: $fetchedReportId');

        // Update the stored report ID
        setReportId(fetchedReportId);
        return fetchedReportId;
      } else {
        debugPrint('No report found for session $targetSessionId');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching report ID: $e');
      return null;
    }
  }

  // Enhanced method to load report data that handles both direct report ID and session ID
  Future<void> loadReportData() async {
    _loading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // If we already have a report ID, use it directly
      if (reportId != null && reportId!.isNotEmpty) {
        debugPrint("Using existing report ID: $reportId");
        await fetchReportData();
        return;
      }

      // fetch report ID from session ID if available
      if (sessionId != null && sessionId!.isNotEmpty) {
        debugPrint("Fetching report ID for session: $sessionId");
        final fetchedReportId = await fetchReportIdFromSupabase();

        if (fetchedReportId == null) {
          _errorMessage = 'No report found for this session';
          _loading = false;
          notifyListeners();
          return;
        }

        // fetch the report data from report ID
        await fetchReportData();
        return;
      }

      // If there is neither report ID nor session ID
      _errorMessage = 'No report ID or session ID available';
      _loading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load report: $e';
      debugPrint('Error in loadReportData: $e');
      _loading = false;
      notifyListeners();
    }
  }

  // Method to set both session ID and report ID at once
  void setSessionAndReportIds({String? sessionId, String? reportId}) {
    if (sessionId != null && sessionId.isNotEmpty) {
      setSessionId(sessionId);
    }

    if (reportId != null && reportId.isNotEmpty) {
      setReportId(reportId);
    }
  }

  // Method to load data by session name - useful when navigating from other screens
  Future<void> loadReportDataBySessionName(String sessionName) async {
    setSessionName(sessionName);

    // First try to fetch session ID from the session name
    final userId = await _supabaseService.currentUserId;
    if (userId == null) {
      _errorMessage = 'User not logged in';
      notifyListeners();
      return;
    }

    try {
      // Get session ID from session name
      final sessionResponse = await _supabaseService.client
          .from('Sessions')
          .select('session_id')
          .eq('user_id', userId)
          .eq('session_name', sessionName)
          .maybeSingle();

      if (sessionResponse != null && sessionResponse['session_id'] != null) {
        final String sessionId = sessionResponse['session_id'];
        setSessionId(sessionId);

        // Now load the report with the session ID
        await loadReportData();
      } else {
        _errorMessage = 'No session found with name: $sessionName';
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Error finding session: $e';
      notifyListeners();
    }
  }
}
