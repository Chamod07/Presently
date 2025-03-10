import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _storage = const FlutterSecureStorage();
  final _supabase = Supabase.instance.client;

  Future<void> persistSession(Session session) async {
    debugPrint('[AUTH] Persisting new session');
    await _storage.write(key: 'access_token', value: session.accessToken);
    await _storage.write(key: 'refresh_token', value: session.refreshToken);
    debugPrint('[AUTH] Session persisted successfully');
  }

  Future<String?> getAccessToken() async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) {
      debugPrint('[AUTH] No access token found in storage');
      // Try getting the current token from Supabase
      final currentSession = _supabase.auth.currentSession;
      if (currentSession != null) {
        debugPrint('[AUTH] Retrieved token from current session');
        return currentSession.accessToken;
      }
    }
    return token;
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: 'refresh_token');
  }

  Future<Session> refreshSession() async {
    debugPrint('[AUTH] Attempting to refresh session');
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) {
      debugPrint('[AUTH] No refresh token available');
      throw Exception('No refresh token available');
    }
    
    try {
      final response = await _supabase.auth.setSession(refreshToken);
      if (response.session != null) {
        debugPrint('[AUTH] Session refreshed successfully');
        await persistSession(response.session!);
        return response.session!;
      } else {
        debugPrint('[AUTH] Session refresh failed - no session returned');
        throw Exception('Failed to refresh session');
      }
    } catch (e) {
      debugPrint('[AUTH] Error refreshing session: $e');
      throw Exception('Failed to refresh session: $e');
    }
  }

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}