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
}
