abstract class BaseReport {
  double? score;
  List<Weakness>? weaknesses;
  BaseReport({this.score, this.weaknesses});
}

// NEW: Combined report container that replaces the deprecated Report class
class PresentationReport {
  final ContextReport context;
  final GrammarReport grammar;
  final BodyLanguageReport bodyLanguage;
  final VoiceAnalysisReport voice;

  PresentationReport({
    required this.context,
    required this.grammar, 
    required this.bodyLanguage,
    required this.voice,
  });

  // Factory constructor to create an empty report
  factory PresentationReport.empty() {
    return PresentationReport(
      context: ContextReport(),
      grammar: GrammarReport(),
      bodyLanguage: BodyLanguageReport(),
      voice: VoiceAnalysisReport(),
    );
  }
}

// TODO: Remove deprecated class after full migration
@Deprecated('Use PresentationReport instead')
class Report {
  double? scoreContext;
  double? scoreGrammar;
  List<Weakness>? contextWeaknesses;
  List<Weakness>? grammarWeaknesses;

  Report({this.scoreContext, this.scoreGrammar, this.contextWeaknesses, this.grammarWeaknesses});
}

class ContextReport extends BaseReport {
  ContextReport({super.score, super.weaknesses});

  factory ContextReport.fromJson(Map<String, dynamic> json) {
    return ContextReport(
      score: json['overall_score']?.toDouble(),
      weaknesses: (json['weakness_topics'] as List<dynamic>?)
          ?.map((e) => Weakness.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class GrammarReport extends BaseReport {
  GrammarReport({super.score, super.weaknesses});

  factory GrammarReport.fromJson(Map<String, dynamic> json) {
    return GrammarReport(
      score: json['grammar_score']?.toDouble(),
      weaknesses: (json['weakness_topics'] as List<dynamic>?)
          ?.map((e) => Weakness.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class BodyLanguageReport extends BaseReport {
  BodyLanguageReport({super.score, super.weaknesses});

  factory BodyLanguageReport.fromJson(Map<String, dynamic> json) {
    return BodyLanguageReport(
      score: json['scoreBodyLanguage']?.toDouble(),
      weaknesses: (json['weaknessTopics'] as List<dynamic>?)
          ?.map((e) => Weakness.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class VoiceAnalysisReport extends BaseReport {
  VoiceAnalysisReport({super.score, super.weaknesses});

  factory VoiceAnalysisReport.fromJson(Map<String, dynamic> json) {
    return VoiceAnalysisReport(
      score: json['scoreVoice']?.toDouble(),
      weaknesses: (json['weaknessTopics'] as List<dynamic>?)
          ?.map((e) => Weakness.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Weakness {
  final String? topic;
  final List<String>? examples;
  final List<String>? suggestions;

  Weakness({this.topic, this.examples, this.suggestions});

  factory Weakness.fromJson(Map<String, dynamic> json) {
    return Weakness(
      topic: json['topic'] as String?,
      examples: (json['examples'] as List<dynamic>?)?.map((e) => e as String).toList(),
      suggestions: (json['suggestions'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );
  }
}
