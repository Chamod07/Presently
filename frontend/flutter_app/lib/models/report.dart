class Report {
  final double? scoreContext;
  final double? scoreGrammar; // new field
  final List<Weakness>? weaknesses;
  final List<Weakness>? grammarWeaknesses;

  Report({this.scoreContext, this.scoreGrammar, this.weaknesses, this.grammarWeaknesses});

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      scoreContext: json['score'] as double?,
      scoreGrammar: json['scoreGrammar'] as double?, // new property parse
      weaknesses: (json['weaknesses'] as List<dynamic>?)
          ?.map((e) => Weakness.fromJson(e as Map<String, dynamic>))
          .toList(),
      grammarWeaknesses: (json['weaknessTopicsGrammar'] as List<dynamic>?)
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