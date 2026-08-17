import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api_config.dart';
import '../models/auth_session.dart';

class SessionStore {
  const SessionStore();

  static const _sessionKey = 'skino.auth.session';
  static const _onboardingKey = 'skino.onboarding.complete';
  static const _baseUrlKey = 'skino.api.base_url';

  Future<AuthSession?> readSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionKey);

    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      return AuthSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      await prefs.remove(_sessionKey);
      return null;
    } on TypeError {
      await prefs.remove(_sessionKey);
      return null;
    }
  }

  Future<void> saveSession(AuthSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode(session.toJson()));
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  Future<String> readBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString(_baseUrlKey);
    final normalizedUrl = ApiConfig.normalizeBaseUrl(
      savedUrl ?? ApiConfig.defaultBaseUrl,
    );

    if (savedUrl != null && savedUrl != normalizedUrl) {
      await prefs.setString(_baseUrlKey, normalizedUrl);
    }

    return normalizedUrl;
  }

  Future<void> saveBaseUrl(String baseUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, ApiConfig.normalizeBaseUrl(baseUrl));
  }
}
