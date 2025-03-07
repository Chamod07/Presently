import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Singleton service for managing Supabase client instance and authentication
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  late SupabaseClient _client;

  // Factory constructor
  factory SupabaseService() {
    return _instance;
  }

  // Private constructor
  SupabaseService._internal();

  // Getter for the client
  SupabaseClient get client => _client;

  // Initialize Supabase
  Future<void> initialize({
    required String supabaseUrl,
    required String supabaseKey,
    required FlutterAuthClientOptions authOptions,
  }) async {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseKey,
        authOptions: authOptions,
      );
      _client = Supabase.instance.client;
      debugPrint('Supabase client initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Supabase: $e');
      rethrow;
    }
  }

  // Check if user is authenticated
  bool isAuthenticated() {
    return _client.auth.currentSession != null;
  }

  // Get current user
  User? getCurrentUser() {
    return _client.auth.currentUser;
  }

  // Sign out user
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
