class ModelTrainingConsent {
  const ModelTrainingConsent({
    required this.granted,
    required this.policyVersion,
  });

  final bool granted;
  final String policyVersion;

  factory ModelTrainingConsent.fromJson(Map<String, dynamic> json) {
    return ModelTrainingConsent(
      granted: json['granted'] == true,
      policyVersion: json['policy_version']?.toString() ?? '2026-07-24',
    );
  }
}
