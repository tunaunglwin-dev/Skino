import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/api_config.dart';
import '../../../core/api_exception.dart';
import '../models/model_training_consent.dart';

class PrivacyConsentApi {
  const PrivacyConsentApi();

  Future<ModelTrainingConsent> fetchModelTrainingConsent({
    required String baseUrl,
    required String token,
  }) async {
    final normalizedBaseUrl = ApiConfig.normalizeBaseUrl(baseUrl);
    final response = await _send(
      () => http.get(
        Uri.parse('$normalizedBaseUrl/privacy/model-training-consent'),
        headers: _headers(token),
      ),
    );

    return _consentFromResponse(response);
  }

  Future<ModelTrainingConsent> updateModelTrainingConsent({
    required String baseUrl,
    required String token,
    required bool granted,
  }) async {
    final normalizedBaseUrl = ApiConfig.normalizeBaseUrl(baseUrl);
    final response = await _send(
      () => http.put(
        Uri.parse('$normalizedBaseUrl/privacy/model-training-consent'),
        headers: _headers(token),
        body: jsonEncode({'granted': granted}),
      ),
    );

    return _consentFromResponse(response);
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(const Duration(seconds: 12));
    } on SocketException {
      throw ApiException(
        'Could not reach Laravel API. ${ApiConfig.connectionHelp}',
      );
    } on TimeoutException {
      throw ApiException(
        'Laravel API did not respond in time. ${ApiConfig.connectionHelp}',
      );
    }
  }

  ModelTrainingConsent _consentFromResponse(http.Response response) {
    final payload = _decode(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        payload['message']?.toString() ?? 'Privacy update failed.',
      );
    }

    return ModelTrainingConsent.fromJson(
      payload['data'] as Map<String, dynamic>,
    );
  }

  Map<String, String> _headers(String token) {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _decode(http.Response response) {
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw const ApiException('Laravel returned an invalid privacy response.');
    }
  }
}
