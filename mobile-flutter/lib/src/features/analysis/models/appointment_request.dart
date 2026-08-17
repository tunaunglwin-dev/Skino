import 'skin_analysis_result.dart';

class AppointmentRequestDraft {
  const AppointmentRequestDraft({
    required this.name,
    required this.email,
    required this.phone,
    required this.preferredContactMethod,
    required this.beautyGoal,
    required this.notes,
    required this.result,
    this.preferredDate,
    this.requestedSpecialist,
  });

  final String name;
  final String email;
  final String phone;
  final String preferredContactMethod;
  final String beautyGoal;
  final String notes;
  final SkinAnalysisResult result;
  final DateTime? preferredDate;
  final String? requestedSpecialist;

  Map<String, dynamic> toJson() {
    return {
      if (name.trim().isNotEmpty) 'name': name.trim(),
      if (email.trim().isNotEmpty) 'email': email.trim(),
      if (phone.trim().isNotEmpty) 'phone': phone.trim(),
      'preferred_contact_method': preferredContactMethod,
      if (preferredDate != null)
        'preferred_date': preferredDate!.toIso8601String(),
      if ((requestedSpecialist ?? '').trim().isNotEmpty)
        'requested_specialist': requestedSpecialist!.trim(),
      if (beautyGoal.trim().isNotEmpty) 'beauty_goal': beautyGoal.trim(),
      if (notes.trim().isNotEmpty) 'notes': notes.trim(),
      'skin_type': result.skinType,
      if (result.id != null) 'skin_analysis_id': result.id,
      'acne_severity': result.acneSeverity,
      'skin_health_score': result.skinHealthScore,
      'concern_summary': _concernSummary(),
    };
  }

  String _concernSummary() {
    if (result.concerns.isEmpty) {
      return 'Latest scan found no strong visible concern.';
    }

    return result.concerns
        .map(
          (concern) =>
              '${concern.name} ${(concern.confidence * 100).round()}% ${concern.severity}',
        )
        .join(', ');
  }
}
