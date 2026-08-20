enum AppLanguage { myanmar, english }

extension AppLanguageLabel on AppLanguage {
  String get code {
    return switch (this) {
      AppLanguage.myanmar => 'my',
      AppLanguage.english => 'en',
    };
  }

  String get label {
    return switch (this) {
      AppLanguage.myanmar => 'မြန်မာ',
      AppLanguage.english => 'English',
    };
  }
}
