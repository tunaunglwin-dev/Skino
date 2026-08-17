import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/api_config.dart';
import '../../../core/api_exception.dart';
import '../models/appointment_request.dart';

class AppointmentRequestApi {
  const AppointmentRequestApi();

  Future<void> create({
    required String baseUrl,
    required String? token,
    required AppointmentRequestDraft draft,
  }) async {
    final normalizedBaseUrl = ApiConfig.normalizeBaseUrl(baseUrl);
    final isGuest = token == null || token.isEmpty;

    final response = await _postJson(
      Uri.parse(
        isGuest
            ? '$normalizedBaseUrl/guest/appointment-requests'
            : '$normalizedBaseUrl/appointment-requests',
      ),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (!isGuest) 'Authorization': 'Bearer $token',
      },
      body: draft.toJson(),
    );

    final payload = _decode(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        payload['message']?.toString() ?? 'Appointment request failed.',
      );
    }
  }

  Future<http.Response> _postJson(
    Uri uri, {
    required Map<String, String> headers,
    required Map<String, dynamic> body,
  }) async {
    try {
      return await http
          .post(uri, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 20));
    } on SocketException {
      throw ApiException(
        'Could not reach Laravel API. ${ApiConfig.connectionHelp}',
      );
    } on TimeoutException {
      throw const ApiException('Appointment request timed out.');
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw const ApiException(
        'Laravel returned an invalid appointment response.',
      );
    }
  }
}
