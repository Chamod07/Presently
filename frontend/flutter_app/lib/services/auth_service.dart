import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase;

  AuthService({required SupabaseClient supabase}) : _supabase = supabase;

  // Get current user (if any)
  User? get currentUser => _supabase.auth.currentUser;

  // Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  // Check if session is valid
  Future<bool> hasValidSession() async {
    if (!isAuthenticated) return false;

    try {
      // Check if the session is still valid
      final session = _supabase.auth.currentSession;

      if (session == null) return false;

      // Check if token is expired
      if (session.isExpired) {
        // Try to refresh the session
        try {
          await _supabase.auth.refreshSession();
          return _supabase.auth.currentSession != null;
        } catch (e) {
          return false;
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error checking session: ${e.toString()}');
      return false;
    }
  }

  // Listen to auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
