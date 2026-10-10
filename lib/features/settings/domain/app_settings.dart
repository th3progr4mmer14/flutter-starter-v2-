import 'package:flutter/material.dart';

class AppSettings {
  final ThemeMode themeMode;

  /// null = usar el idioma del sistema.
  final String? languageCode;
  final bool notificationsEnabled;
  final bool soundEnabled;
  final int refreshSeconds;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.languageCode,
    this.notificationsEnabled = true,
    this.soundEnabled = true,
    this.refreshSeconds = 5,
  });

  Locale? get locale => languageCode == null ? null : Locale(languageCode!);

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? languageCode,
    bool clearLanguage = false,
    bool? notificationsEnabled,
    bool? soundEnabled,
    int? refreshSeconds,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      languageCode: clearLanguage ? null : (languageCode ?? this.languageCode),
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      refreshSeconds: refreshSeconds ?? this.refreshSeconds,
    );
  }
}
