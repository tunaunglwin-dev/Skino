class SkinConcern {
  const SkinConcern({
    required this.name,
    required this.confidence,
    required this.severity,
  });

  final String name;
  final double confidence;
  final String severity;

  factory SkinConcern.fromJson(Map<String, dynamic> json) {
    return SkinConcern(
      name: json['name'].toString(),
      confidence: double.parse(json['confidence'].toString()),
      severity: json['severity'].toString(),
    );
  }
}
