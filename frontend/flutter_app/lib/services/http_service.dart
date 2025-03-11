import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/config.dart';

class HttpService {
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
      final response = await fn();
      
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
    
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      headers['Authorization'] = 'Bearer ${session.accessToken}';
      debugPrint('[JWT DEBUG] Using token: ${session.accessToken.substring(0, 10)}...');
    }
    
    return headers;
  }
}
