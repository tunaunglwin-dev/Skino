import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/api_config.dart';
import '../../../core/api_exception.dart';
import '../../auth/models/auth_session.dart';
import '../models/active_routine.dart';
import '../models/skin_analysis_result.dart';

class BuddyChatApi {
  const BuddyChatApi();

  Future<String> ask({
    required String baseUrl,
    required AuthSession session,
    required String message,
    required SkinAnalysisResult? result,
    required ActiveRoutine? activeRoutine,
  }) async {
    final normalizedBaseUrl = ApiConfig.normalizeBaseUrl(baseUrl);
    final response = await _send(
      () => http.post(
        Uri.parse('$normalizedBaseUrl/chat/routine-assistant'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session.token}',
        },
        body: jsonEncode({
          'message': message,
          'context': {
            'scan': _scanContext(result),
            'routine': _routineContext(activeRoutine),
          },
        }),
      ),
    );
    final payload = _decode(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        payload['message']?.toString() ?? 'Buddy could not answer right now.',
      );
    }

    final reply = (payload['data'] as Map<String, dynamic>?)?['reply']
        ?.toString()
        .trim();
    if (reply == null || reply.isEmpty) {
      throw const ApiException('Buddy returned an empty answer.');
    }

    return reply;
  }

  Map<String, Object?>? _scanContext(SkinAnalysisResult? result) {
    if (result == null) {
      return null;
    }

    final package = result.treatmentPackage;

    return {
      'skin_type': result.skinType,
      'skin_type_confidence': result.skinTypeConfidence,
      'skin_health_score': result.skinHealthScore,
      'acne_severity': result.acneSeverity,
      'concerns': result.concerns
          .take(5)
          .map(
            (concern) => {
              'name': concern.name,
              'severity': concern.severity,
              'confidence': concern.confidence,
            },
          )
          .toList(),
      'scan_quality': result.scanQuality == null
          ? null
          : {
              'level': result.scanQuality!.level,
              'message': result.scanQuality!.message,
            },
      'treatment_package': package == null
          ? null
          : {
              'name': package.name,
              'reason': package.reason,
              'follow_up_days': package.followUpDays,
              'steps': package.steps.take(5).toList(),
            },
      'created_at': result.createdAt?.toIso8601String(),
    };
  }

  Map<String, Object?>? _routineContext(ActiveRoutine? activeRoutine) {
    if (activeRoutine == null) {
      return null;
    }

    return {
      'name': activeRoutine.routine.name,
      'started_at': activeRoutine.startedAt?.toIso8601String(),
      'follow_up_days': activeRoutine.routine.followUpDays,
      'today': {
        'date': activeRoutine.today.date,
        'morning_done': activeRoutine.today.morningDone,
        'night_done': activeRoutine.today.nightDone,
      },
      'steps': activeRoutine.routine.steps.take(6).toList(),
    };
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(const Duration(seconds: 18));
    } on SocketException {
      throw ApiException(
        'Could not reach Laravel API. ${ApiConfig.connectionHelp}',
      );
    } on TimeoutException {
      throw const ApiException('Buddy timed out. Try a shorter question.');
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw const ApiException('Laravel returned an invalid Buddy response.');
    }
  }
}
