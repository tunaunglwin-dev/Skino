import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/api_config.dart';
import '../../../core/api_exception.dart';
import '../models/active_routine.dart';

class RoutineApi {
  const RoutineApi();

  Future<ActiveRoutine?> fetchActive({
    required String baseUrl,
    required String token,
  }) async {
    final response = await _send(
      () => http.get(
        Uri.parse('${ApiConfig.normalizeBaseUrl(baseUrl)}/routine'),
        headers: _headers(token),
      ),
    );
    final payload = _decode(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_message(payload, 'Could not load active routine.'));
    }

    if (payload['data'] == null) {
      return null;
    }

    return ActiveRoutine.fromJson(payload['data'] as Map<String, dynamic>);
  }

  Future<ActiveRoutine> start({
    required String baseUrl,
    required String token,
    required int skinAnalysisId,
  }) async {
    final response = await _send(
      () => http.post(
        Uri.parse('${ApiConfig.normalizeBaseUrl(baseUrl)}/routine/start'),
        headers: _headers(token),
        body: jsonEncode({'skin_analysis_id': skinAnalysisId}),
      ),
    );
    final payload = _decode(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_message(payload, 'Could not start routine.'));
    }

    return ActiveRoutine.fromJson(payload['data'] as Map<String, dynamic>);
  }

  Future<ActiveRoutine> updateToday({
    required String baseUrl,
    required String token,
    String? checkDate,
    bool? morningDone,
    bool? nightDone,
  }) async {
    final fields = <String, Object>{};
    if (checkDate != null) fields['check_date'] = checkDate;
    if (morningDone != null) fields['morning_done'] = morningDone;
    if (nightDone != null) fields['night_done'] = nightDone;

    final response = await _send(
      () => http.put(
        Uri.parse('${ApiConfig.normalizeBaseUrl(baseUrl)}/routine/today'),
        headers: _headers(token),
        body: jsonEncode(fields),
      ),
    );
    final payload = _decode(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_message(payload, 'Could not update routine.'));
    }

    return ActiveRoutine.fromJson(payload['data'] as Map<String, dynamic>);
  }

  Future<void> stop({required String baseUrl, required String token}) async {
    final response = await _send(
      () => http.delete(
        Uri.parse('${ApiConfig.normalizeBaseUrl(baseUrl)}/routine'),
        headers: _headers(token),
      ),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final payload = _decode(response);
      throw ApiException(_message(payload, 'Could not stop routine.'));
    }
  }

  Map<String, String> _headers(String token) {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(const Duration(seconds: 30));
    } on SocketException {
      throw ApiException(
        'Could not reach Laravel API. ${ApiConfig.connectionHelp}',
      );
    } on TimeoutException {
      throw const ApiException('Routine request timed out. Try again soon.');
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw const ApiException('Laravel returned an invalid routine response.');
    }
  }

  String _message(Map<String, dynamic> payload, String fallback) {
    final message = payload['message']?.toString();
    if (message == null || message.trim().isEmpty) {
      return fallback;
    }

    if (message.contains('SQLSTATE') || message.contains('no such table')) {
      return 'Routine service is not ready yet. Please run Laravel migrations, then try again.';
    }

    return message;
  }
}
