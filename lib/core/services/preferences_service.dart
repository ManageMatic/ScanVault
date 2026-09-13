import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local preferences management for user settings and first launch flags.
class PreferencesService {
  static const String _keyFirstLaunch = 'is_first_launch';
  static const String _keyThemeMode = 'app_theme_mode';
  static const String _keyAutoCrop = 'auto_crop_enabled';
  static const String _keyOcrLanguage = 'ocr_language';
  static const String _keyPdfQuality = 'pdf_quality';
  static const String _keyAppLock = 'app_lock_enabled';

  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  static Future<PreferencesService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return PreferencesService(prefs);
  }

  bool get isFirstLaunch => _prefs.getBool(_keyFirstLaunch) ?? true;

  Future<void> setFirstLaunchCompleted() async {
    await _prefs.setBool(_keyFirstLaunch, false);
  }

  ThemeMode get themeMode {
    final modeStr = _prefs.getString(_keyThemeMode);
    switch (modeStr) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    String value = 'system';
    if (mode == ThemeMode.dark) value = 'dark';
    if (mode == ThemeMode.light) value = 'light';
    await _prefs.setString(_keyThemeMode, value);
  }

  bool get autoCropEnabled => _prefs.getBool(_keyAutoCrop) ?? true;
  Future<void> setAutoCropEnabled(bool value) => _prefs.setBool(_keyAutoCrop, value);

  String get ocrLanguage => _prefs.getString(_keyOcrLanguage) ?? 'en';
  Future<void> setOcrLanguage(String lang) => _prefs.setString(_keyOcrLanguage, lang);

  String get pdfQuality => _prefs.getString(_keyPdfQuality) ?? 'high';
  Future<void> setPdfQuality(String quality) => _prefs.setString(_keyPdfQuality, quality);

  bool get appLockEnabled => _prefs.getBool(_keyAppLock) ?? false;
  Future<void> setAppLockEnabled(bool value) => _prefs.setBool(_keyAppLock, value);
}
