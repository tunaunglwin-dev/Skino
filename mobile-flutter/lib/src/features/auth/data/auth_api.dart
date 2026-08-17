import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/api_config.dart';
import '../../../core/api_exception.dart';
import '../models/auth_session.dart';

class AuthApi {
  const AuthApi();

  Future<void> checkHealth({required String baseUrl}) async {
    final normalizedBaseUrl = ApiConfig.normalizeBaseUrl(baseUrl);

    try {
      final response = await http
          .get(
            Uri.parse('$normalizedBaseUrl/health'),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          'Laravel API is reachable but not healthy. Open $normalizedBaseUrl/health on this computer and check the server logs.',
        );
      }
    } on SocketException {
      throw ApiException(
        'Could not reach Laravel API at $normalizedBaseUrl. ${ApiConfig.connectionHelp}',
      );
    } on TimeoutException {
      throw ApiException(
        'Laravel API did not respond at $normalizedBaseUrl. ${ApiConfig.connectionHelp}',
      );
    }
  }

  Future<AuthSession> login({
    required String baseUrl,
    required String email,
    required String password,
  }) async {
    final normalizedBaseUrl = ApiConfig.normalizeBaseUrl(baseUrl);
    final response = await _post(
      Uri.parse('$normalizedBaseUrl/auth/login'),
      body: {'email': email, 'password': password},
    );

    final payload = _decode(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_messageFrom(payload));
    }

    return AuthSession.fromJson(payload['data'] as Map<String, dynamic>);
  }

  Future<AuthSession> loginWithGoogle({
    required String baseUrl,
    required String idToken,
  }) async {
    final normalizedBaseUrl = ApiConfig.normalizeBaseUrl(baseUrl);
    final response = await _post(
      Uri.parse('$normalizedBaseUrl/auth/google'),
      body: {'id_token': idToken},
    );

    final payload = _decode(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_messageFrom(payload));
    }

    return AuthSession.fromJson(payload['data'] as Map<String, dynamic>);
  }

  Future<http.Response> _post(
    Uri uri, {
    required Map<String, String> body,
  }) async {
    try {
      return await http
          .post(
            uri,
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 12));
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

  Map<String, dynamic> _decode(http.Response response) {
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw const ApiException(
        'Laravel returned HTML or an invalid response. Make sure the URL ends with /api.',
      );
    }
  }

  String _messageFrom(Map<String, dynamic> payload) {
    final errors = payload['errors'];

    if (errors is Map<String, dynamic>) {
      for (final entry in errors.entries) {
        final messages = entry.value;

        if (messages is List && messages.isNotEmpty) {
          return messages.first.toString();
        }
      }
    }

    return payload['message']?.toString() ?? 'The API request failed.';
  }
}
