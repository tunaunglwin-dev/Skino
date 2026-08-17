enum AppLanguage { myanmar, english }

extension AppLanguageLabel on AppLanguage {
  String get label {
    return switch (this) {
      AppLanguage.myanmar => 'မြန်မာ',
      AppLanguage.english => 'English',
    };
  }
}
