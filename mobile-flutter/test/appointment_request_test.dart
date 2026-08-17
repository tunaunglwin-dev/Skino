import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_flutter/src/features/analysis/models/appointment_request.dart';
import 'package:mobile_flutter/src/features/analysis/models/skin_analysis_result.dart';
import 'package:mobile_flutter/src/features/analysis/models/skin_concern.dart';

void main() {
  test('appointment request payload carries CRM scheduling context', () {
    final preferredDate = DateTime(2026, 8, 1, 10, 30);
    final draft = AppointmentRequestDraft(
      name: 'Tun Aung Lwin',
      email: 'tun@example.com',
      phone: '091234567',
      preferredContactMethod: 'telegram',
      beautyGoal: 'Specialist acne consultation',
      notes: 'Painful acne near cheek',
      preferredDate: preferredDate,
      requestedSpecialist: 'Dr. May Thandar',
      result: const SkinAnalysisResult(
        id: 7,
        skinType: 'oily',
        skinTypeConfidence: 0.92,
        concerns: [
          SkinConcern(name: 'acne', confidence: 0.81, severity: 'moderate'),
        ],
        skinZones: [],
        acneSeverity: 'moderate',
        skinHealthScore: 66,
        recommendedProducts: [],
        treatmentPackage: null,
        createdAt: null,
      ),
    );

    expect(draft.toJson(), {
      'name': 'Tun Aung Lwin',
      'email': 'tun@example.com',
      'phone': '091234567',
      'preferred_contact_method': 'telegram',
      'preferred_date': preferredDate.toIso8601String(),
      'requested_specialist': 'Dr. May Thandar',
      'beauty_goal': 'Specialist acne consultation',
      'notes': 'Painful acne near cheek',
      'skin_type': 'oily',
      'skin_analysis_id': 7,
      'acne_severity': 'moderate',
      'skin_health_score': 66,
      'concern_summary': 'acne 81% moderate',
    });
  });
}
