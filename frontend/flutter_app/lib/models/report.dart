class Report {
  final double? score;
  final List<Weakness>? weaknesses;

  Report({this.score, this.weaknesses});

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      score: json['score'] as double?,
      weaknesses: (json['weaknesses'] as List<dynamic>?)
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