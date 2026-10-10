import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/providers/providers.dart';
import '../../domain/app_settings.dart';

/// Ajustes de la app, guardados en el dispositivo (SharedPreferences).
class SettingsController extends Notifier<AppSettings> {
  static const _kTheme = 'settings_theme';
  static const _kLang = 'settings_lang';
  static const _kNotif = 'settings_notifications';
  static const _kSound = 'settings_sound';
  static const _kRefresh = 'settings_refresh_seconds';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  AppSettings build() {
    final p = ref.read(sharedPreferencesProvider);
    final themeName = p.getString(_kTheme);

    return AppSettings(
      themeMode: ThemeMode.values.firstWhere(
        (m) => m.name == themeName,
        orElse: () => ThemeMode.system,
      ),
      languageCode: p.getString(_kLang),
      notificationsEnabled: p.getBool(_kNotif) ?? true,
      soundEnabled: p.getBool(_kSound) ?? true,
      refreshSeconds: p.getInt(_kRefresh) ?? 5,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs.setString(_kTheme, mode.name);
  }

  /// code == null -> idioma del sistema.
  Future<void> setLanguage(String? code) async {
    if (code == null) {
      state = state.copyWith(clearLanguage: true);
      await _prefs.remove(_kLang);
    } else {
      state = state.copyWith(languageCode: code);
      await _prefs.setString(_kLang, code);
    }
  }

  Future<void> setNotifications(bool value) async {
    state = state.copyWith(notificationsEnabled: value);
    await _prefs.setBool(_kNotif, value);
  }

  Future<void> setSound(bool value) async {
    state = state.copyWith(soundEnabled: value);
    await _prefs.setBool(_kSound, value);
  }

  Future<void> setRefreshSeconds(int seconds) async {
    state = state.copyWith(refreshSeconds: seconds);
    await _prefs.setInt(_kRefresh, seconds);
  }
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);
