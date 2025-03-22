import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class Config {
  // Choose the right base URL based on platform
  static String get baseUrl {
    if (kIsWeb) {
      // Web uses localhost
      return 'http://localhost:8000';
    } else if (Platform.isAndroid) {
      // Android emulator uses 10.0.2.2
      return 'http://10.0.2.2:8000';
    } else if (Platform.isIOS) {
      // iOS simulator uses localhost
      return 'http://localhost:8000';
    } else {
      // Default for other platforms
      return 'http://localhost:8000';
    }
  }

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

  static const String poseScoreEndpoint = '/analyser/body-language/score';
  static const String poseWeaknessEndpoint =
      '/analyser/body-language/weaknesses';

  static const String voiceScoreEndpoint = '/analyser/voice/score';
  static const String voiceWeaknessEndpoint = '/analyser/voice/weaknesses';
}
