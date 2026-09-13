import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local preferences management for user settings and privacy flags.
class PreferencesService {
  static const String _keyFirstLaunch = 'is_first_launch';
  static const String _keyThemeMode = 'app_theme_mode';
  static const String _keyAutoCrop = 'auto_crop_enabled';
  static const String _keyOcrLanguage = 'ocr_language';
  static const String _keyPdfQuality = 'pdf_quality';
  static const String _keyAppLock = 'app_lock_enabled';
  static const String _keyBiometric = 'biometric_unlock_enabled';
  static const String _keyBruteForce = 'brute_force_destruction_enabled';
  static const String _keyCameraSound = 'camera_sound_enabled';
  static const String _keyGyroscope = 'gyroscope_guide_enabled';
  static const String _keyAutoOcr = 'auto_ocr_scans_enabled';
  static const String _keyDefaultFilter = 'default_filter_name';
  static const String _keyFlashMode = 'default_flash_mode';

  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  static Future<PreferencesService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return PreferencesService(prefs);
  }

  bool get isFirstLaunch => _prefs.getBool(_keyFirstLaunch) ?? true;
  Future<void> setFirstLaunchCompleted() async => _prefs.setBool(_keyFirstLaunch, false);

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

  String get ocrLanguage => _prefs.getString(_keyOcrLanguage) ?? 'English, Spanish';
  Future<void> setOcrLanguage(String lang) => _prefs.setString(_keyOcrLanguage, lang);

  String get pdfQuality => _prefs.getString(_keyPdfQuality) ?? 'high';
  Future<void> setPdfQuality(String quality) => _prefs.setString(_keyPdfQuality, quality);

  bool get appLockEnabled => _prefs.getBool(_keyAppLock) ?? true;
  Future<void> setAppLockEnabled(bool value) => _prefs.setBool(_keyAppLock, value);

  bool get biometricEnabled => _prefs.getBool(_keyBiometric) ?? true;
  Future<void> setBiometricEnabled(bool value) => _prefs.setBool(_keyBiometric, value);

  bool get bruteForceEnabled => _prefs.getBool(_keyBruteForce) ?? false;
  Future<void> setBruteForceEnabled(bool value) => _prefs.setBool(_keyBruteForce, value);

  bool get cameraSoundEnabled => _prefs.getBool(_keyCameraSound) ?? false;
  Future<void> setCameraSoundEnabled(bool value) => _prefs.setBool(_keyCameraSound, value);

  bool get gyroscopeGuideEnabled => _prefs.getBool(_keyGyroscope) ?? true;
  Future<void> setGyroscopeGuideEnabled(bool value) => _prefs.setBool(_keyGyroscope, value);

  bool get autoOcrEnabled => _prefs.getBool(_keyAutoOcr) ?? true;
  Future<void> setAutoOcrEnabled(bool value) => _prefs.setBool(_keyAutoOcr, value);

  String get defaultFilter => _prefs.getString(_keyDefaultFilter) ?? 'Document Clean';
  Future<void> setDefaultFilter(String filter) => _prefs.setString(_keyDefaultFilter, filter);

  String get flashMode => _prefs.getString(_keyFlashMode) ?? 'Auto';
  Future<void> setFlashMode(String mode) => _prefs.setString(_keyFlashMode, mode);
}
