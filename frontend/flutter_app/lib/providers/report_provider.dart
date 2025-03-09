import 'package:flutter/material.dart';
import 'package:flutter_app/models/report.dart';
import 'package:flutter_app/services/http_service.dart';
import 'package:flutter_app/config/config.dart';
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
      debugPrint('Fetching report data for report ID: $reportId');
      
      // Fetch context score
      final contextScoreResponse = await _httpService.get(
        '${Config.apiUrl}${Config.contextScoreEndpoint}?report_id=$reportId'
      );
      
      if (contextScoreResponse.statusCode == 200) {
        final scoreData = jsonDecode(contextScoreResponse.body);
        _report = Report(scoreContext: scoreData['overall_score']?.toDouble());
        debugPrint('Successfully fetched score: ${_report.scoreContext}');
      } else {
        _errorMessage += 'Error fetching score: ${contextScoreResponse.statusCode}\n';
        debugPrint('Error fetching score: ${contextScoreResponse.statusCode}, ${contextScoreResponse.body}');
      }

      // Fetch context weaknesses
      final weaknessResponse = await _httpService.get(
        '${Config.apiUrl}${Config.contextWeaknessEndpoint}?report_id=$reportId'
      );
      
      if (weaknessResponse.statusCode == 200) {
        final weaknessData = jsonDecode(weaknessResponse.body);
        _report = Report(
          scoreContext: _report.scoreContext, // Keep existing score
          contextWeaknesses: (weaknessData['weakness_topics'] as List<dynamic>?)
              ?.map((e) => Weakness.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
        debugPrint('Successfully fetched weaknesses: ${_report.contextWeaknesses?.length ?? 0}');
      } else {
        _errorMessage += 'Error fetching weaknesses: ${weaknessResponse.statusCode}\n';
        debugPrint('Error fetching weaknesses: ${weaknessResponse.statusCode}, ${weaknessResponse.body}');
      }

      //Grammar data fetching happens below

      // Fetch context score
      final grammarScoreResponse = await _httpService.get(
          '${Config.apiUrl}${Config.grammarScoreEndPoint}?report_id=$reportId'
      );

      double? grammarScore;
      if (grammarScoreResponse.statusCode == 200) {
        final scoreData = jsonDecode(grammarScoreResponse.body);
        grammarScore = scoreData['grammar_score']?.toDouble();
        debugPrint('Successfully fetched grammar score: $grammarScore');
      } else {
        _errorMessage += 'Error fetching grammar score: ${grammarScoreResponse.statusCode}\n';
        debugPrint('Error fetching grammar score: ${grammarScoreResponse.statusCode}, ${grammarScoreResponse.body}');
      }


      // Fetch grammar weaknesses
      final grammarResponse = await _httpService.get(
        '${Config.apiUrl}${Config.grammarWeaknessEndpoint}?report_id=$reportId'
      );
      
      if (grammarResponse.statusCode == 200) {
        final grammarData = jsonDecode(grammarResponse.body);
        _report = Report(
          scoreContext: _report.scoreContext,
          contextWeaknesses: _report.contextWeaknesses,
          scoreGrammar: grammarScore,
          grammarWeaknesses: (grammarData['weakness_topics'] as List<dynamic>?)
              ?.map((e) => Weakness.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
        debugPrint('Successfully fetched grammar weaknesses');
      } else {
        _errorMessage += 'Error fetching grammar: ${grammarResponse.statusCode}\n';
        debugPrint('Error fetching grammar: ${grammarResponse.statusCode}, ${grammarResponse.body}');
      }
    } catch (e) {
      _errorMessage = 'An unexpected error occurred: $e';
      debugPrint('Error in fetchReportData: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}