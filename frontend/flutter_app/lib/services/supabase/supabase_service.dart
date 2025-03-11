import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A service class that provides a centralized Supabase client instance
/// and authentication functionality for the application.
class SupabaseService {
  /// Singleton instance of the SupabaseService
  static final SupabaseService _instance = SupabaseService._internal();

  /// Factory constructor to return the singleton instance
  factory SupabaseService() {
    return _instance;
  }

  /// Private constructor for singleton pattern
  SupabaseService._internal();

  /// Flag to track if Supabase has been initialized
  bool _initialized = false;

  /// Get initialization status
  bool get isInitialized => _initialized;

  /// Initialize Supabase with required credentials
  /// Must be called before accessing any Supabase functionality
  Future<void> initialize({
    required String supabaseUrl,
    required String supabaseKey,
  }) async {
    if (_initialized) return;

    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseKey,
      );
      _initialized = true;
    } catch (e) {
      _initialized = false;
      rethrow;
    }
  }

  /// Get the Supabase client instance
  SupabaseClient get client {
    assert(_initialized,
    'Supabase must be initialized before accessing the client');
    return Supabase.instance.client;
  }

  /// Get the current user
  User? get currentUser => _initialized ? client.auth.currentUser : null;

  /// Get the current user's ID
  String? get currentUserId => currentUser?.id;

  /// Check if a user is signed in
  bool get isSignedIn => currentUser != null;

  /// Get current session if available
  Session? get currentSession =>
      _initialized ? client.auth.currentSession : null;

  /// Check if session is valid and not expired
  Future<bool> hasValidSession() async {
    if (!isSignedIn) return false;

    try {
      final session = currentSession;

      if (session == null) return false;

      // Check if token is expired
      if (session.isExpired) {
        // Try to refresh the session
        try {
          await client.auth.refreshSession();
          return client.auth.currentSession != null;
        } catch (e) {
          return false;
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error checking session: $e');
      return false;
    }
  }

  /// Listen to auth state changes
  Stream<AuthState> get authStateChanges =>
      _initialized ? client.auth.onAuthStateChange : Stream.empty();

  /// Sign out
  Future<void> signOut() async {
    if (_initialized) {
      await client.auth.signOut();
    }
  }
}