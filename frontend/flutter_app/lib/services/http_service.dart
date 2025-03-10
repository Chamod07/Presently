import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'auth_service.dart';
import '../config/config.dart';

class HttpService {
  static final AuthService _authService = AuthService();
  
  // Base URL from config
  final String baseUrl = Config.baseUrl;

  Future<http.Response> get(String url) async => _makeRequest(() async => 
    http.get(Uri.parse(url), headers: await _getHeaders()));
    
  Future<http.Response> post(String url, {Object? body}) async => 
    _makeRequest(() async => http.post(Uri.parse(url), body: body, headers: await _getHeaders()));
    
  Future<http.Response> put(String url, {Object? body}) async => 
    _makeRequest(() async => http.put(Uri.parse(url), body: body, headers: await _getHeaders()));
    
  Future<http.Response> delete(String url) async => 
    _makeRequest(() async => http.delete(Uri.parse(url), headers: await _getHeaders()));

  Future<http.Response> _makeRequest(Future<http.Response> Function() fn) async {
    try {
      var response = await fn();
      
      if (response.statusCode == 401 && await _handleTokenRefresh()) {
        response = await fn();
      }
      
      debugPrint('[JWT DEBUG] Response status: ${response.statusCode}');
      if (response.statusCode >= 400) {
        debugPrint('[JWT DEBUG] Error response body: ${response.body}');
      }
      
      return response;
    } catch (e) {
      debugPrint('[JWT DEBUG] Request error: $e');
      rethrow;
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    final token = await _authService.getAccessToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
      debugPrint('[JWT DEBUG] Using token: ${token.substring(0, 10)}...');
    } else {
      debugPrint('[JWT DEBUG] No token found');
    }
    
    return headers;
  }

  Future<bool> _handleTokenRefresh() async {
    try {
      await _authService.refreshSession();
      return true;
    } catch (e) {
      debugPrint('[JWT DEBUG] Refresh failed: $e');
      return false;
    }
  }
}