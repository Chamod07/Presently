class Config {
  // Base URL for API requests
  static const String baseUrl = 'http://10.0.2.2:8000'; // Replace with your actual API URL
  static const String apiPath = '/api';
  
  // Full API URL
  static String get apiUrl => '$baseUrl$apiPath';
  
  // Connection timeout in seconds
  static const int timeout = 30;
  
  // Original API endpoints (preserved as requested)
  static const String grammarWeaknessEndpoint = '/analyser/grammar/weaknesses';
  static const String grammarScoreEndPoint = '/analyser/grammar/score';
  static const String contextScoreEndpoint = '/analyser/context/score';
  static const String contextWeaknessEndpoint = '/analyser/context/weaknesses';
}