import 'package:flutter/material.dart';
import '../../services/supabase/supabase_service.dart';

class SessionProvider with ChangeNotifier {
  final _supabaseService = SupabaseService();
  String? _selectedPresentationType;
  String? _selectedPresentationGoal;
  String? _selectedName;
  String? _selectedAudience;
  String? _selectedTopic;
  String? _sessionId;
  List<Map<String, dynamic>> _sessions = [];
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Add a compatibility check when accessing sessions
  List<Map<String, dynamic>> get sessions {
    var allSessions = [..._sessions];

    // This ensures backward compatibility if somehow _sessions is a List<String>
    if (allSessions.isNotEmpty && allSessions.first is String) {
      // Convert legacy format to new format
      final legacySessions =
          allSessions.map((item) => item.toString()).toList();
      allSessions = legacySessions
          .map((name) => {
                'name': name,
                'type': 'Presentation',
                'goal': 'inform',
                'audience': 'General',
                'topic': 'General Topic',
                'is_favorite': false,
                'created_at': DateTime.now().toIso8601String(),
              })
          .toList();
      notifyListeners();
    }

    // Filter out soft-deleted sessions
    allSessions = allSessions.where((session) {
      // Check for is_deleted flag
      if (session.containsKey('is_deleted') && session['is_deleted'] == true) {
        return false;
      }

      // Also filter out sessions where name starts with "DELETED_"
      final name = (session['name'] ?? '').toString();
      if (name.startsWith('DELETED_')) {
        return false;
      }

      return true;
    }).toList();

    // Sort sessions by creation time (newest first)
    allSessions.sort((a, b) {
      DateTime timeA =
          DateTime.parse(a['created_at'] ?? DateTime.now().toIso8601String());
      DateTime timeB =
          DateTime.parse(b['created_at'] ?? DateTime.now().toIso8601String());
      return timeB.compareTo(timeA); // Descending order (newest first)
    });

    return allSessions;
  }

  String? get selectedPresentationType => _selectedPresentationType;
  String? get selectedPresentationGoal => _selectedPresentationGoal;
  String? get selectedName => _selectedName;
  String? get selectedAudience => _selectedAudience;
  String? get selectedTopic => _selectedTopic;
  String? get sessionId => _sessionId;

  // Reset all sessions data and clear any cached information
  void resetSessionsData() {
    _sessions = [];
    notifyListeners();
  }

  //session data update
  void startSession(
      String presentationType, String presentationGoal, String sessionName,
      {required String audience, required String topic}) {
    _selectedPresentationType = presentationType;
    _selectedPresentationGoal = presentationGoal;
    _selectedName = sessionName;
    _selectedAudience = audience;
    _selectedTopic = topic;
    notifyListeners();
  }

  // Modified to add the current session details or use provided values
  void addSession(String sessionName,
      {String? type,
      String? goal,
      String? audience,
      String? topic,
      bool isFavorite = false}) {
    _sessions.add({
      'name': sessionName,
      'type': type ?? _selectedPresentationType,
      'goal': goal ?? _selectedPresentationGoal,
      'audience': audience ?? _selectedAudience,
      'topic': topic ?? _selectedTopic,
      'is_favorite': isFavorite,
      'created_at': DateTime.now().toIso8601String(),
    });
    notifyListeners();
  }

  //clear session data
  void clearSession() {
    _selectedPresentationType = null;
    _selectedPresentationGoal = null;
    _selectedName = null;
    _selectedAudience = null;
    _selectedTopic = null;
    notifyListeners();
  }

  //save session in supabase
  Future<Map<String, dynamic>> saveToSupabase() async {
    final userId = _supabaseService.currentUserId;
    if (userId == null) {
      return {
        "error": "User not logged in",
        'sessionId': null,
        'reportId': null,
      };
    }

    final timestamp = DateTime.now().toIso8601String();

    try {
      // Insert the session and get the session ID
      final response = await _supabaseService.client.from('Sessions').insert({
        'session_name': _selectedName,
        'session_type': _selectedPresentationType,
        'session_goal': _selectedPresentationGoal,
        'audience': _selectedAudience,
        'topic': _selectedTopic,
        'user_id': userId,
        'is_favorite': false,
        'created_at': timestamp,
      }).select();

      String? sessionId;
      if (response != null && response.isNotEmpty) {
        sessionId = response[0]['session_id'];
        _sessionId = sessionId; //Store the session ID for future reference
      }

      // Check for an existing report for this session
      String? reportId;
      if (sessionId != null) {
        final reportResponse = await _supabaseService.client
            .from("UserReport")
            .select("reportId")
            .eq("userId", userId)
            .eq("session_id", sessionId)
            .order('createdAt', ascending: false)
            .limit(1)
            .maybeSingle();

        if (reportResponse != null && reportResponse['reportId'] != null) {
          reportId = reportResponse['reportId'];
        }
      }

      // Add the session to local list after successful save
      addSession(_selectedName!,
          type: _selectedPresentationType,
          goal: _selectedPresentationGoal,
          audience: _selectedAudience,
          topic: _selectedTopic);

      return {"error": null, "sessionId": sessionId, "reportId": reportId};
    } catch (e) {
      return {
        "error": 'Error saving session: $e',
        "sessionId": null,
        "reportId": null
      };
    }
  }

  // Helper method to show error dialog
  void showErrorDialog(BuildContext context, String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(errorMessage),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  //load sessions from supabase
  Future<void> loadSessionsFromSupabase() async {
    if (_isLoading) return; // Prevent multiple simultaneous loads

    _isLoading = true;
    notifyListeners();

    // Clear any existing sessions to avoid mixing formats
    _sessions = [];

    final userId = _supabaseService.currentUserId;
    if (userId == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      // First collect all session IDs to use in a single query
      final sessionsResponse = await _supabaseService.client
          .from('Sessions')
          .select()
          .eq('user_id', userId);

      if (sessionsResponse == null ||
          !(sessionsResponse is List) ||
          sessionsResponse.isEmpty) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Extract session IDs for the batch query
      final List<String> sessionIds = sessionsResponse
          .map<String>((session) => session['session_id'].toString())
          .toList();

      // Make a single query to get all reports for these sessions
      // This replaces the individual queries in the loop
      final reportsResponse = await _supabaseService.client
          .from("UserReport")
          .select('reportId, session_id, createdAt')
          .eq("userId", userId)
          .inFilter('session_id', sessionIds)
          .order('createdAt', ascending: false);

      // Create a map of session_id -> most recent reportId for quick lookup
      Map<String, String> sessionToReportMap = {};

      if (reportsResponse != null && reportsResponse is List) {
        // Group by session_id and keep the most recent one (already ordered by createdAt)
        for (var report in reportsResponse) {
          String sessionId = report['session_id'];
          // Only add if this is the first (most recent) report for this session
          if (!sessionToReportMap.containsKey(sessionId)) {
            sessionToReportMap[sessionId] = report['reportId'];
          }
        }
      }

      // Now build the sessions list with the report IDs from our map
      for (var session in sessionsResponse) {
        String sessionId = session['session_id'];
        _sessions.add({
          'name': session['session_name'],
          'type': session['session_type'],
          'goal': session['session_goal'],
          'audience': session['audience'],
          'topic': session['topic'],
          'is_favorite': session['is_favorite'] ?? false,
          'created_at':
              session['created_at'] ?? DateTime.now().toIso8601String(),
          'sessionId': sessionId,
          'reportId': sessionToReportMap[sessionId], // Look up from our map
        });
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error loading sessions: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper method to get report ID by session name
  Future<String?> getReportIdBySessionName(String sessionName) async {
    final index =
        _sessions.indexWhere((session) => session['name'] == sessionName);
    if (index != -1 && _sessions[index]['reportId'] != null) {
      return _sessions[index]['reportId'];
    }

    // If not found in local cache, try fetching from Supabase
    final userId = _supabaseService.currentUserId;
    if (userId == null) return null;

    try {
      final sessionResponse = await _supabaseService.client
          .from('Sessions')
          .select('session_id')
          .eq('user_id', userId)
          .eq('session_name', sessionName)
          .maybeSingle();

      if (sessionResponse != null && sessionResponse['session_id'] != null) {
        return await getReportIdForSession(sessionResponse['session_id']);
      }
    } catch (e) {
      print('Error fetching session ID for session name $sessionName: $e');
    }

    return null;
  }

  // Method to fetch report ID for a specific session ID
  Future<String?> getReportIdForSession(String? sessionId) async {
    if (sessionId == null) return null;

    final userId = _supabaseService.currentUserId;
    if (userId == null) return null;

    try {
      final response = await _supabaseService.client
          .from("UserReport")
          .select("reportId")
          .eq("userId", userId)
          .eq("session_id", sessionId)
          .order('createdAt', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null && response['reportId'] != null) {
        return response['reportId'];
      }
    } catch (e) {
      print('Error fetching report ID for session $sessionId: $e');
    }

    return null;
  }

  Future<bool> renameSession(String oldName, String newName) async {
    // First, find the session with the given name
    final index = _sessions.indexWhere((session) => session['name'] == oldName);
    if (index == -1) {
      print('Session not found with name: $oldName');
      return false;
    }

    // Get the session ID from the local cache
    final String? sessionId = _sessions[index]['sessionId'];
    if (sessionId == null) {
      print('No session ID found for session: $oldName');
      return false;
    }

    // Update local state
    _sessions[index]['name'] = newName;
    notifyListeners();

    // Update in Supabase using session_id (more reliable than name)
    final userId = _supabaseService.currentUserId;
    if (userId != null) {
      try {
        final response = await _supabaseService.client
            .from('Sessions')
            .update({'session_name': newName})
            .eq('user_id', userId)
            .eq('session_id', sessionId); // Use session_id instead of name

        print('Session renamed successfully in database');
        return true;
      } catch (e) {
        print('Error renaming session in Supabase: $e');
        // Revert local change on error
        _sessions[index]['name'] = oldName;
        notifyListeners();
        return false;
      }
    }

    return false;
  }

  Future<bool> deleteSession(String sessionName) async {
    // Find the session with the given name
    final index =
        _sessions.indexWhere((session) => session['name'] == sessionName);
    if (index == -1) {
      print('Session not found with name: $sessionName');
      return false;
    }

    // Get the session ID before removing from local state
    final String? sessionId = _sessions[index]['sessionId'];

    if (sessionId == null) {
      print('No session ID found for session: $sessionName');

      // Still remove from local state if it exists there
      _sessions.removeAt(index);
      notifyListeners();
      return false;
    }

    // Store the session data in case we need to restore it
    final sessionData = Map<String, dynamic>.from(_sessions[index]);

    // Remove from local state first
    _sessions.removeAt(index);
    notifyListeners();

    // Delete from Supabase
    final userId = _supabaseService.currentUserId;
    if (userId != null) {
      try {
        // APPROACH 1: Try direct DELETE with cascade if supported
        print('Trying direct DELETE with explicit join...');
        try {
          // First, force-update any reports to disconnect them from this session
          await _supabaseService.client
              .from('UserReport')
              .update({'session_id': null}) // Set to null instead of deleting
              .eq('session_id', sessionId)
              .eq('userId', userId);

          print('Updated reports to remove session reference');

          // Now try to delete the session
          await _supabaseService.client
              .from('Sessions')
              .delete()
              .eq('session_id', sessionId)
              .eq('user_id', userId);

          print('Session deleted successfully from database');
          return true;
        } catch (e) {
          print('Direct DELETE approach failed: $e');
        }

        // APPROACH 2: Soft delete by marking as deleted
        try {
          print('Trying soft delete approach...');

          // Mark the session as "deleted" without actually deleting it
          await _supabaseService.client
              .from('Sessions')
              .update({
                'is_deleted': true,
                'session_name':
                    'DELETED_${sessionName}_${DateTime.now().millisecondsSinceEpoch}'
              })
              .eq('session_id', sessionId)
              .eq('user_id', userId);

          print('Session soft-deleted successfully');
          return true;
        } catch (e) {
          print('Soft delete approach failed: $e');

          // Final fallback: Check if the session was removed from local state
          // If we can't delete from database, at least keep it hidden in the app
          print('Using client-side filtering as last resort');

          // Don't restore session to local state
          return true;
        }
      } catch (e) {
        print('All deletion approaches failed: $e');

        // Restore the session in local state on error
        _sessions.add(sessionData);
        // Re-sort the sessions
        _sessions.sort((a, b) {
          DateTime timeA = DateTime.parse(
              a['created_at'] ?? DateTime.now().toIso8601String());
          DateTime timeB = DateTime.parse(
              b['created_at'] ?? DateTime.now().toIso8601String());
          return timeB.compareTo(timeA);
        });
        notifyListeners();
        return false;
      }
    }
    return false;
  }

  // Toggle favorite status of a session
  Future<void> toggleFavorite(String sessionName) async {
    final index =
        _sessions.indexWhere((session) => session['name'] == sessionName);
    if (index != -1) {
      _sessions[index]['is_favorite'] = !_sessions[index]['is_favorite'];
      notifyListeners();

      // Update in Supabase
      final userId = _supabaseService.currentUserId;
      if (userId != null) {
        try {
          await _supabaseService.client
              .from('Sessions')
              .update({'is_favorite': _sessions[index]['is_favorite']})
              .eq('user_id', userId)
              .eq('session_name', sessionName);
        } catch (e) {
          print('Error updating favorite status in Supabase: $e');
        }
      }
    }
  }

  // Add this method to filter sessions with search capabilities:

  List<Map<String, dynamic>> getFilteredSessions({
    bool favoritesOnly = false,
    String searchQuery = '',
  }) {
    List<Map<String, dynamic>> result = List.from(sessions);

    // Filter by favorites if needed
    if (favoritesOnly) {
      result =
          result.where((session) => session['is_favorite'] == true).toList();
    }

    // Filter by search query if provided
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      result = result.where((session) {
        final name = (session['name'] ?? '').toLowerCase();
        final topic = (session['topic'] ?? '').toLowerCase();

        return name.contains(query) || topic.contains(query);
      }).toList();
    }

    // Sort by creation date, newest first
    result.sort((a, b) {
      final dateA = a['created_at'] != null
          ? DateTime.parse(a['created_at'])
          : DateTime.now();
      final dateB = b['created_at'] != null
          ? DateTime.parse(b['created_at'])
          : DateTime.now();
      return dateB.compareTo(dateA);
    });

    return result;
  }
}
