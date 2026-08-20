import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String emulatorBaseUrl = 'http://10.0.2.2:8000/api';
  static const String localBaseUrl = 'http://127.0.0.1:8000/api';
  static const String homeWifiBaseUrl = 'http://192.168.100.44:8000/api';
  static const String hackathonWifiBaseUrl = 'http://10.160.198.174:8000/api';
  static const String phoneBaseUrlExample = homeWifiBaseUrl;
  static const Set<String> stalePhoneBaseUrls = {
    'http://172.16.14.205:8000/api',
  };

  static String get defaultBaseUrl {
    if (kIsWeb) {
      return localBaseUrl;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return phoneBaseUrlExample;
    }

    return localBaseUrl;
  }

  static String normalizeBaseUrl(String value) {
    final fallback = value.trim().isEmpty ? defaultBaseUrl : value.trim();
    final withoutTrailingSlash = fallback.replaceFirst(RegExp(r'/+$'), '');
    if (stalePhoneBaseUrls.contains(withoutTrailingSlash)) {
      return defaultBaseUrl;
    }
    final uri = Uri.tryParse(withoutTrailingSlash);

    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return withoutTrailingSlash;
    }

    final segments = uri.pathSegments
        .where((segment) => segment.trim().isNotEmpty)
        .toList();

    if (segments.isEmpty) {
      segments.add('api');
    } else if (segments.last != 'api') {
      segments.add('api');
    }

    return uri
        .replace(pathSegments: segments)
        .toString()
        .replaceFirst(RegExp(r'/+$'), '');
  }

  static const String connectionHelp =
      'Android emulator: use http://10.0.2.2:8000/api. Real phone on the same Wi-Fi or phone hotspot: run Laravel with --host=0.0.0.0 and use the laptop IP from that network, for example http://192.168.100.44:8000/api. If Wi-Fi or power changes, recheck the laptop IP, save it in Settings, then tap Test. Also start the Python AI service on port 5000 before analysis.';
}
