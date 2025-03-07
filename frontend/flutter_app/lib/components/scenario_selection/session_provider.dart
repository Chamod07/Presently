import 'package:flutter/material.dart';
import '/services/supabase_service.dart';

class SessionProvider with ChangeNotifier {
  final _supabaseService = SupabaseService();
  String? _selectedPresentationType;
  String? _selectedPresentationGoal;
  String? _selectedName;
  List<String> _sessions = [];

  List<String> get sessions => _sessions;
  String? get selectedPresentationType => _selectedPresentationType;
  String? get selectedPresentationGoal => _selectedPresentationGoal;
  String? get selectedName => _selectedName;

  //session data update
  void startSession(String presentationType, String presentationGoal, String sessionName) {
    _selectedPresentationType = presentationType;
    _selectedPresentationGoal = presentationGoal;
    _selectedName = sessionName;
    notifyListeners();
  }

  void addSession(String session) {
    _sessions.add(session);
    notifyListeners();
  }

  //clear session data
  void clearSession() {
    _selectedPresentationType = null;
    _selectedPresentationGoal = null;
    _selectedName = null;
    notifyListeners();
  }

  //save session in supabase
  Future<void> saveToSupabase(String sessionName) async {
    final userId = _supabaseService.currentUserId;
    if (userId == null) return;

    try {
      await _supabaseService.client.from('Sessions').insert({
        'session_name': sessionName,
        'session_type': _selectedPresentationType,
        'session_goal': _selectedPresentationGoal,
        'user_id': userId,
      });
    } catch (e) {
      print('Error saving session: $e');
    }
  }

  //load sessions from supabase
  Future<void> loadSessionsFromSupabase() async {
    final userId = _supabaseService.currentUserId;
    if (userId == null) return;

    try {
      final response = await _supabaseService.client
          .from('Sessions')
          .select()
          .eq('user_id', userId);

      List<dynamic> data = response as List<dynamic>;
      List<String> dbSessions = data.map((s) => s['session_name'] as String).toList();

      for (String session in dbSessions) {
        if (!_sessions.contains(session)) {
          _sessions.add(session);
        }
      }

      notifyListeners();
    } catch (e) {
      print('Error loading sessions: $e');
    }
  }
}