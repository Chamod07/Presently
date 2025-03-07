import 'package:flutter/material.dart';
import 'package:flutter_app/models/report.dart';
import 'package:flutter_app/services/http_service.dart';
import 'dart:convert';

class ReportProvider with ChangeNotifier {
  final String reportId = '123e4567-e89b-12d3-a456-426614174000';
  Report _report = Report();
  bool _loading = false;
  String _errorMessage = '';

  Report get report => _report;
  bool get loading => _loading;
  String get errorMessage => _errorMessage;

  final HttpService _httpService = HttpService();

  Future<void> fetchReportData() async {
    _loading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // Fetch context score
      final scoreResponse = await _httpService.get('http://192.168.1.5:8000/api/analyser/context/score?report_id=$reportId');
      if (scoreResponse.statusCode == 200) {
        final scoreData = jsonDecode(scoreResponse.body);
        _report = Report(score: scoreData['overall_score']?.toDouble());
      } else {
        _errorMessage += 'Error fetching score: ${scoreResponse.statusCode}\\n';
      }

      // Fetch context weaknesses
      final weaknessResponse = await _httpService.get('http://192.168.1.5:8000/api/analyser/context/weaknesses?report_id=$reportId');
      if (weaknessResponse.statusCode == 200) {
        final weaknessData = jsonDecode(weaknessResponse.body);
        _report = Report(
          score: _report.score, // Keep existing score
          weaknesses: (weaknessData['weakness_topics'] as List<dynamic>?)
              ?.map((e) => Weakness.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
      } else {
        _errorMessage += 'Error fetching weaknesses: ${weaknessResponse.statusCode}\\n';
      }
    } catch (e) {
      _errorMessage = 'An unexpected error occurred: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}