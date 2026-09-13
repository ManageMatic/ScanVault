import 'package:flutter/material.dart';
import '../core/services/preferences_service.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/main_shell/presentation/main_shell_screen.dart';
import '../features/scanner/presentation/scanner_screen.dart';
import '../features/settings/presentation/about_screen.dart';

/// Centralized route constants and page generator for ScanVault.
class AppRouter {
  AppRouter._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String scanner = '/scanner';
  static const String about = '/about';

  static Route<dynamic> generateRoute(RouteSettings settings, PreferencesService prefs) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => SplashScreen(preferencesService: prefs),
        );
      case onboarding:
        return MaterialPageRoute(
          builder: (_) => OnboardingScreen(preferencesService: prefs),
        );
      case home:
        final initialIndex = settings.arguments as int? ?? 0;
        return MaterialPageRoute(
          builder: (_) => MainShellScreen(
            preferencesService: prefs,
            initialIndex: initialIndex,
          ),
        );
      case scanner:
        return MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const ScannerScreen(),
        );
      case about:
        return MaterialPageRoute(
          builder: (_) => const AboutScreen(),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => SplashScreen(preferencesService: prefs),
        );
    }
  }
}
