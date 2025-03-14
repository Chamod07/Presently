import 'package:flutter/material.dart';
import 'package:flutter_app/models/report.dart';
import 'package:flutter_app/services/http_service.dart';
import 'package:flutter_app/config/config.dart';
import 'dart:convert';

class ReportProvider with ChangeNotifier {
  final String reportId = '123e4567-e89b-12d3-a456-426614174000';
  

  // New report structure
  PresentationReport _report = PresentationReport.empty();
  
  bool _loading = false;
  String _errorMessage = '';


  // New getter
  PresentationReport get report => _report;
  bool get loading => _loading;
  String get errorMessage => _errorMessage;

  final HttpService _httpService = HttpService();

  Future<void> fetchReportData() async {
    _loading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await Future.wait([
        _fetchContextData(),
        _fetchGrammarData(),
        _fetchBodyLanguageData(),
        _fetchVoiceData(),
      ]);
    } catch (e) {
      _errorMessage = 'An unexpected error occurred: $e';
      debugPrint('Error in fetchReportData: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchContextData() async {
    try {
      debugPrint('Fetching context data for report ID: $reportId');
      
      // Fetch context score
      final contextScoreResponse = await _httpService.get(
        '${Config.apiUrl}${Config.contextScoreEndpoint}?report_id=$reportId'
      );
      
      if (contextScoreResponse.statusCode == 200) {
        final scoreData = jsonDecode(contextScoreResponse.body);
        final double? contextScore = scoreData['overall_score']?.toDouble();
        
        // Fetch context weaknesses
        final weaknessResponse = await _httpService.get(
          '${Config.apiUrl}${Config.contextWeaknessEndpoint}?report_id=$reportId'
        );
        
        if (weaknessResponse.statusCode == 200) {
          final weaknessData = jsonDecode(weaknessResponse.body);
          final weaknesses = (weaknessData['weakness_topics'] as List<dynamic>?)
                ?.map((e) => Weakness.fromJson(e as Map<String, dynamic>))
                .toList();

          
          // Update new report structure
          _report = PresentationReport(
            context: ContextReport(score: contextScore, weaknesses: weaknesses),
            grammar: _report.grammar,
            bodyLanguage: _report.bodyLanguage,
            voice: _report.voice,
          );
          
          debugPrint('Successfully fetched context data');
        } else {
          _addError('Error fetching context weaknesses', weaknessResponse);
        }
      } else {
        _addError('Error fetching context score', contextScoreResponse);
      }
    } catch (e) {
      debugPrint('Error in _fetchContextData: $e');
      _errorMessage += 'Error fetching context data: $e\n';
    }
  }

  Future<void> _fetchGrammarData() async {
    try {
      // Fetch grammar score
      final grammarScoreResponse = await _httpService.get(
        '${Config.apiUrl}${Config.grammarScoreEndPoint}?report_id=$reportId'
      );

      if (grammarScoreResponse.statusCode == 200) {
        final scoreData = jsonDecode(grammarScoreResponse.body);
        final double? grammarScore = scoreData['grammar_score']?.toDouble();


        // Fetch grammar weaknesses
        final grammarResponse = await _httpService.get(
          '${Config.apiUrl}${Config.grammarWeaknessEndpoint}?report_id=$reportId'
        );
        
        if (grammarResponse.statusCode == 200) {
          final grammarData = jsonDecode(grammarResponse.body);
          final weaknesses = (grammarData['weakness_topics'] as List<dynamic>?)
                ?.map((e) => Weakness.fromJson(e as Map<String, dynamic>))
                .toList();
          
          // Update new report structure
          _report = PresentationReport(
            context: _report.context,
            grammar: GrammarReport(score: grammarScore, weaknesses: weaknesses),
            bodyLanguage: _report.bodyLanguage,
            voice: _report.voice,
          );
          
          debugPrint('Successfully fetched grammar data');
        } else {
          _addError('Error fetching grammar weaknesses', grammarResponse);
        }
      } else {
        _addError('Error fetching grammar score', grammarScoreResponse);
      }
    } catch (e) {
      debugPrint('Error in _fetchGrammarData: $e');
      _errorMessage += 'Error fetching grammar data: $e\n';
    }
  }


  Future<void> _fetchBodyLanguageData() async {
    try {
      // Fetch body language score
      final poseScoreResponse = await _httpService.get(
        '${Config.apiUrl}${Config.poseScoreEndpoint}?report_id=$reportId'
      );

      if (poseScoreResponse.statusCode == 200) {
        final scoreData = jsonDecode(poseScoreResponse.body);
        final double? poseScore = scoreData['scoreBodyLanguage']?.toDouble();

        // Fetch body language weaknesses
        final poseWeaknessResponse = await _httpService.get(
          '${Config.apiUrl}${Config.poseWeaknessEndpoint}?report_id=$reportId'
        );
        
        if (poseWeaknessResponse.statusCode == 200) {
          final poseData = jsonDecode(poseWeaknessResponse.body);
          final weaknesses = (poseData['weaknessTopics'] as List<dynamic>?)
                ?.map((e) => Weakness.fromJson(e as Map<String, dynamic>))
                .toList();
          
          // Update new report structure
          _report = PresentationReport(
            context: _report.context,
            grammar: _report.grammar,
            bodyLanguage: BodyLanguageReport(score: poseScore, weaknesses: weaknesses),
            voice: _report.voice,
          );
          
          debugPrint('Successfully fetched body language data');
        } else {
          _addError('Error fetching body language weaknesses', poseWeaknessResponse);
        }
      } else {
        _addError('Error fetching body language score', poseScoreResponse);
      }
    } catch (e) {
      debugPrint('Error in _fetchBodyLanguageData: $e');
      _errorMessage += 'Error fetching body language data: $e\n';
    }
  }

  Future<void> _fetchVoiceData() async {
    try {
      // Fetch voice score
      final voiceScoreResponse = await _httpService.get(
        '${Config.apiUrl}${Config.voiceScoreEndpoint}?report_id=$reportId'
      );

      if (voiceScoreResponse.statusCode == 200) {
        final scoreData = jsonDecode(voiceScoreResponse.body);
        final double? voiceScore = scoreData['scoreVoice']?.toDouble();

        // Fetch voice weaknesses
        final voiceWeaknessResponse = await _httpService.get(
          '${Config.apiUrl}${Config.voiceWeaknessEndpoint}?report_id=$reportId'
        );
        
        if (voiceWeaknessResponse.statusCode == 200) {
          final voiceData = jsonDecode(voiceWeaknessResponse.body);
          final weaknesses = (voiceData['weaknessTopics'] as List<dynamic>?)
                ?.map((e) => Weakness.fromJson(e as Map<String, dynamic>))
                .toList();
          
          // Update new report structure
          _report = PresentationReport(
            context: _report.context,
            grammar: _report.grammar,
            bodyLanguage: _report.bodyLanguage,
            voice: VoiceAnalysisReport(score: voiceScore, weaknesses: weaknesses),
          );
          
          debugPrint('Successfully fetched voice data');
        } else {
          _addError('Error fetching voice weaknesses', voiceWeaknessResponse);
        }
      } else {
        _addError('Error fetching voice score', voiceScoreResponse);
      }
    } catch (e) {
      debugPrint('Error in _fetchVoiceData: $e');
      _errorMessage += 'Error fetching voice data: $e\n';
    }
  }

  void _addError(String message, dynamic response) {
    _errorMessage += '$message: ${response.statusCode}\n';
    debugPrint('$message: ${response.statusCode}, ${response.body}');
  }
}
