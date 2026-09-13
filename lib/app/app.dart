import 'package:flutter/material.dart';
import '../core/constants/app_strings.dart';
import '../core/services/preferences_service.dart';
import 'app_router.dart';
import 'app_theme.dart';

/// Root ScanVault Application Widget with reactive Theme switching.
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
  @override
  void initState() {
    super.initState();
    widget.preferencesService.addListener(_onPreferencesChanged);
  }

  @override
  void dispose() {
    widget.preferencesService.removeListener(_onPreferencesChanged);
    super.dispose();
  }

  void _onPreferencesChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: widget.preferencesService.themeMode,
      initialRoute: AppRouter.splash,
      onGenerateRoute: (settings) => AppRouter.generateRoute(settings, widget.preferencesService),
    );
  }
}
