import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_flutter/src/core/api_config.dart';

void main() {
  group('ApiConfig.normalizeBaseUrl', () {
    test('adds the Laravel API prefix when only the server URL is entered', () {
      expect(
        ApiConfig.normalizeBaseUrl('http://127.0.0.1:8000'),
        'http://127.0.0.1:8000/api',
      );
    });

    test('keeps an existing API prefix and removes trailing slashes', () {
      expect(
        ApiConfig.normalizeBaseUrl('http://10.0.2.2:8000/api///'),
        'http://10.0.2.2:8000/api',
      );
    });

    test('preserves a configured subpath before adding the API prefix', () {
      expect(
        ApiConfig.normalizeBaseUrl('https://example.test/skin-platform'),
        'https://example.test/skin-platform/api',
      );
    });

    test('migrates the old same Wi-Fi address to the current computer IP', () {
      expect(
        ApiConfig.normalizeBaseUrl('http://172.16.14.205:8000/api'),
        ApiConfig.phoneBaseUrlExample,
      );
    });

    test('keeps the home router same Wi-Fi address', () {
      expect(
        ApiConfig.normalizeBaseUrl('http://192.168.100.44:8000/api'),
        ApiConfig.homeWifiBaseUrl,
      );
    });
  });
}
