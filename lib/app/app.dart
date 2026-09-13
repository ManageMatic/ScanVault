import 'package:flutter/material.dart';
import '../core/constants/app_strings.dart';
import '../core/services/preferences_service.dart';
import '../features/settings/domain/settings_controller.dart';
import 'app_router.dart';
import 'app_theme.dart';

/// Root ScanVault Application Widget.
class ScanVaultApp extends StatefulWidget {
  final PreferencesService preferencesService;

  const ScanVaultApp({
    super.key,
    required this.preferencesService,
  });

  @override
  State<ScanVaultApp> createState() => _ScanVaultAppState();
}

class _ScanVaultAppState extends State<ScanVaultApp> {
  late final SettingsController _settingsController;

  @override
  void initState() {
    super.initState();
    _settingsController = SettingsController(widget.preferencesService);
    _settingsController.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _settingsController.removeListener(_onThemeChanged);
    _settingsController.dispose();
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _settingsController.themeMode,
      initialRoute: AppRouter.splash,
      onGenerateRoute: (settings) => AppRouter.generateRoute(settings, widget.preferencesService),
    );
  }
}
