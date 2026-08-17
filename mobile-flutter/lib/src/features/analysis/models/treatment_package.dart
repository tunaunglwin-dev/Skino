class TreatmentPackage {
  const TreatmentPackage({
    required this.key,
    required this.name,
    required this.steps,
    required this.followUpDays,
    required this.reason,
  });

  final String key;
  final String name;
  final List<String> steps;
  final int followUpDays;
  final String reason;

  factory TreatmentPackage.fromJson(Map<String, dynamic> json) {
    final rawSteps = json['steps'] as List<dynamic>? ?? const [];

    return TreatmentPackage(
      key: json['key']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Personalized care plan',
      steps: rawSteps.map((step) => step.toString()).toList(),
      followUpDays:
          int.tryParse(json['follow_up_days']?.toString() ?? '') ?? 14,
      reason:
          json['reason']?.toString() ?? 'Recommended from your latest scan.',
    );
  }
}
