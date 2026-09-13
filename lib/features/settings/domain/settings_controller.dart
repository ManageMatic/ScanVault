import 'package:flutter/material.dart';
import '../../../core/services/preferences_service.dart';

/// Controller for user settings, theme, security toggles, and storage info.
class SettingsController extends ChangeNotifier {
  final PreferencesService _preferencesService;

  SettingsController(this._preferencesService);

  ThemeMode get themeMode => _preferencesService.themeMode;
  bool get autoCropEnabled => _preferencesService.autoCropEnabled;
  String get ocrLanguage => _preferencesService.ocrLanguage;
  String get pdfQuality => _preferencesService.pdfQuality;
  bool get appLockEnabled => _preferencesService.appLockEnabled;
  bool get biometricEnabled => _preferencesService.biometricEnabled;
  bool get bruteForceEnabled => _preferencesService.bruteForceEnabled;
  bool get cameraSoundEnabled => _preferencesService.cameraSoundEnabled;
  bool get gyroscopeGuideEnabled => _preferencesService.gyroscopeGuideEnabled;
  bool get autoOcrEnabled => _preferencesService.autoOcrEnabled;
  String get defaultFilter => _preferencesService.defaultFilter;
  String get flashMode => _preferencesService.flashMode;

  Future<void> setThemeMode(ThemeMode mode) async {
    await _preferencesService.setThemeMode(mode);
    notifyListeners();
  }

  Future<void> setAutoCrop(bool value) async {
    await _preferencesService.setAutoCropEnabled(value);
    notifyListeners();
  }

  Future<void> setOcrLanguage(String lang) async {
    await _preferencesService.setOcrLanguage(lang);
    notifyListeners();
  }

  Future<void> setPdfQuality(String quality) async {
    await _preferencesService.setPdfQuality(quality);
    notifyListeners();
  }

  Future<void> setAppLock(bool enabled) async {
    await _preferencesService.setAppLockEnabled(enabled);
    notifyListeners();
  }

  Future<void> setBiometric(bool enabled) async {
    await _preferencesService.setBiometricEnabled(enabled);
    notifyListeners();
  }

  Future<void> setBruteForce(bool enabled) async {
    await _preferencesService.setBruteForceEnabled(enabled);
    notifyListeners();
  }

  Future<void> setCameraSound(bool enabled) async {
    await _preferencesService.setCameraSoundEnabled(enabled);
    notifyListeners();
  }

  Future<void> setGyroscopeGuide(bool enabled) async {
    await _preferencesService.setGyroscopeGuideEnabled(enabled);
    notifyListeners();
  }

  Future<void> setAutoOcr(bool enabled) async {
    await _preferencesService.setAutoOcrEnabled(enabled);
    notifyListeners();
  }

  Future<void> setDefaultFilter(String filter) async {
    await _preferencesService.setDefaultFilter(filter);
    notifyListeners();
  }

  Future<void> setFlashMode(String mode) async {
    await _preferencesService.setFlashMode(mode);
    notifyListeners();
  }
}
