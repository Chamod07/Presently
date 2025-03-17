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
  Future<String?> saveToSupabase() async {
    final userId = _supabaseService.currentUserId;
    if (userId == null) return "User not logged in";

    final timestamp = DateTime.now().toIso8601String();

    try {
      await _supabaseService.client.from('Sessions').insert({
        'session_name': _selectedName,
        'session_type': _selectedPresentationType,
        'session_goal': _selectedPresentationGoal,
        'audience': _selectedAudience,
        'topic': _selectedTopic,
        'user_id': userId,
        'is_favorite': false,
        'created_at': timestamp,
      });

      // Add the session to local list after successful save
      addSession(_selectedName!,
          type: _selectedPresentationType,
          goal: _selectedPresentationGoal,
          audience: _selectedAudience,
          topic: _selectedTopic);

      return null; // Success, no error
    } catch (e) {
      return 'Error saving session: $e';
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
      final response = await _supabaseService.client
          .from('Sessions')
          .select()
          .eq('user_id', userId);

      List<dynamic> data = response as List<dynamic>;
      for (var session in data) {
        _sessions.add({
          'name': session['session_name'],
          'type': session['session_type'],
          'goal': session['session_goal'],
          'audience': session['audience'],
          'topic': session['topic'],
          'is_favorite': session['is_favorite'] ?? false,
          'created_at':
              session['created_at'] ?? DateTime.now().toIso8601String(),
        });
      }

      notifyListeners();
    } catch (e) {
      print('Error loading sessions: $e');
    }
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
