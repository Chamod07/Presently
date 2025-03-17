import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiClient {
  // Choose the right base URL based on platform
  String get baseUrl {
    if (kIsWeb) {
      // Web uses localhost
      return 'http://localhost:8000/api';
    } else if (Platform.isAndroid) {
      // Android emulator uses 10.0.2.2
      return 'http://10.0.2.2:8000/api';
    } else if (Platform.isIOS) {
      // iOS simulator uses localhost
      return 'http://localhost:8000/api';
    } else {
      // Default for other platforms
      return 'http://localhost:8000/api';
    }
  }

  // Get the auth token from Supabase
  String? _getAuthToken() {
    return Supabase.instance.client.auth.currentSession?.accessToken;
  }

  // GET request
  Future<http.Response> get(String path) async {
    final token = _getAuthToken();
    if (token == null) {
      throw Exception('Authentication required');
    }

    final url = Uri.parse('$baseUrl$path');
    print('GET request to: $url');

    return await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }

  // POST request
  Future<http.Response> post(String path, {Map<String, dynamic>? body}) async {
    final token = _getAuthToken();
    if (token == null) {
      throw Exception('Authentication required');
    }

    final url = Uri.parse('$baseUrl$path');
    print('POST request to: $url');

    return await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body != null ? jsonEncode(body) : null,
    );
  }
}
