import 'package:flutter/material.dart';
import '../../services/supabase/supabase_service.dart';

class SessionProvider with ChangeNotifier {
  final _supabaseService = SupabaseService();
  String? _selectedPresentationType;
  String? _selectedPresentationGoal;
  String? _selectedName;
  String? _selectedAudience;
  String? _selectedTopic;
  List<Map<String, dynamic>> _sessions = [];

  // Add a compatibility check when accessing sessions
  List<Map<String, dynamic>> get sessions {
    // This ensures backward compatibility if somehow _sessions is a List<String>
    if (_sessions.isNotEmpty && _sessions.first is String) {
      // Convert legacy format to new format
      final legacySessions = _sessions.map((item) => item.toString()).toList();
      _sessions = legacySessions
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

    // Sort sessions by creation time (newest first)
    _sessions.sort((a, b) {
      DateTime timeA =
          DateTime.parse(a['created_at'] ?? DateTime.now().toIso8601String());
      DateTime timeB =
          DateTime.parse(b['created_at'] ?? DateTime.now().toIso8601String());
      return timeB.compareTo(timeA); // Descending order (newest first)
    });

    return _sessions;
  }

  String? get selectedPresentationType => _selectedPresentationType;
  String? get selectedPresentationGoal => _selectedPresentationGoal;
  String? get selectedName => _selectedName;
  String? get selectedAudience => _selectedAudience;
  String? get selectedTopic => _selectedTopic;

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
    if (userId == null)
      return {
        "error": "User not logged in",
        'sessionId': null,
        'reportId': null
      };

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
    // Clear any existing sessions to avoid mixing formats
    _sessions = [];

    final userId = _supabaseService.currentUserId;
    if (userId == null) return;

    try {
      // Get sessions data from Supabase
      final sessionsResponse = await _supabaseService.client
          .from('Sessions')
          .select()
          .eq('user_id', userId);

      // For each session, also get the most recent report ID if available
      for (var session in sessionsResponse as List<dynamic>) {
        // Get the most recent report ID for this session
        final reportResponse = await _supabaseService.client
            .from("UserReport")
            .select("reportId")
            .eq("userId", userId)
            .eq("session_id", session['session_id'])
            .order('createdAt', ascending: false)
            .limit(1)
            .maybeSingle();

        // Add session with report ID to local sessions list
        _sessions.add({
          'name': session['session_name'],
          'type': session['session_type'],
          'goal': session['session_goal'],
          'audience': session['audience'],
          'topic': session['topic'],
          'is_favorite': session['is_favorite'] ?? false,
          'created_at':
              session['created_at'] ?? DateTime.now().toIso8601String(),
          'sessionId': session['session_id'],
          'reportId':
              reportResponse != null ? reportResponse['reportId'] : null,
        });
      }

      notifyListeners();
    } catch (e) {
      print('Error loading sessions: $e');
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

  Future<void> renameSession(String oldName, String newName) async {
    final index = _sessions.indexWhere((session) => session['name'] == oldName);
    if (index != -1) {
      _sessions[index]['name'] = newName;
      notifyListeners();

      // Update in Supabase
      final userId = _supabaseService.currentUserId;
      if (userId != null) {
        try {
          await _supabaseService.client
              .from('Sessions')
              .update({'session_name': newName})
              .eq('user_id', userId)
              .eq('session_name', oldName);
        } catch (e) {
          print('Error renaming session in Supabase: $e');
        }
      }
    }
  }

  Future<void> deleteSession(String sessionName) async {
    _sessions.removeWhere((session) => session['name'] == sessionName);
    notifyListeners();

    // Delete from Supabase
    final userId = _supabaseService.currentUserId;
    if (userId != null) {
      try {
        await _supabaseService.client
            .from('Sessions')
            .delete()
            .eq('user_id', userId)
            .eq('session_name', sessionName);
      } catch (e) {
        print('Error deleting session from Supabase: $e');
      }
    }
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
