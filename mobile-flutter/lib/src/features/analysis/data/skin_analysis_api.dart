import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/api_config.dart';
import '../../../core/api_exception.dart';
import '../models/skin_analysis_result.dart';

class SkinAnalysisApi {
  const SkinAnalysisApi();

  Future<List<SkinAnalysisResult>> fetchHistory({
    required String baseUrl,
    required String token,
  }) async {
    final normalizedBaseUrl = ApiConfig.normalizeBaseUrl(baseUrl);
    final uri = Uri.parse('$normalizedBaseUrl/skin-analyses?per_page=20');

    final http.Response response;

    try {
      response = await http
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 30));
    } on SocketException {
      throw ApiException(
        'Could not reach Laravel API. ${ApiConfig.connectionHelp}',
      );
    } on TimeoutException {
      throw const ApiException('Scan history timed out. Try again soon.');
    }

    final payload = _decode(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        payload['message']?.toString() ?? 'Could not load scan history.',
      );
    }

    final items = payload['data'] as List<dynamic>? ?? const [];
    return items
        .map(
          (item) => SkinAnalysisResult.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> deleteAnalysis({
    required String baseUrl,
    required String token,
    required int analysisId,
  }) async {
    final normalizedBaseUrl = ApiConfig.normalizeBaseUrl(baseUrl);
    final uri = Uri.parse('$normalizedBaseUrl/skin-analyses/$analysisId');

    final http.Response response;

    try {
      response = await http
          .delete(
            uri,
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 30));
    } on SocketException {
      throw ApiException(
        'Could not reach Laravel API. ${ApiConfig.connectionHelp}',
      );
    } on TimeoutException {
      throw const ApiException('Delete scan timed out. Try again soon.');
    }

    if (response.statusCode == 204) {
      return;
    }

    final payload = _decode(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        payload['message']?.toString() ?? 'Could not delete scan history.',
      );
    }
  }

  Future<SkinAnalysisResult> analyze({
    required String baseUrl,
    required String? token,
    required File image,
    required bool allowModelTraining,
  }) async {
    final normalizedBaseUrl = ApiConfig.normalizeBaseUrl(baseUrl);
    final isGuest = token == null || token.isEmpty;
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
        isGuest
            ? '$normalizedBaseUrl/guest/skin-analysis'
            : '$normalizedBaseUrl/skin-analyses',
      ),
    );

    request.headers.addAll({'Accept': 'application/json'});
    if (!isGuest) {
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['allow_model_training'] = allowModelTraining ? '1' : '0';
    }
    request.files.add(await http.MultipartFile.fromPath('image', image.path));

    final http.Response response;

    try {
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );
      response = await http.Response.fromStream(streamedResponse);
    } on SocketException {
      throw ApiException(
        'Could not reach Laravel API. ${ApiConfig.connectionHelp}',
      );
    } on TimeoutException {
      throw const ApiException(
        'Analysis timed out. Check that Laravel is running, Python AI is on port 5000, and the API URL in Settings is reachable.',
      );
    }

    final payload = _decode(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(payload['message']?.toString() ?? 'Analysis failed.');
    }

    return SkinAnalysisResult.fromJson(payload['data'] as Map<String, dynamic>);
  }

  Map<String, dynamic> _decode(http.Response response) {
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw const ApiException(
        'Laravel returned an invalid analysis response.',
      );
    }
  }
}
