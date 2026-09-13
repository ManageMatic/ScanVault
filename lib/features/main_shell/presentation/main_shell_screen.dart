import 'package:flutter/material.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/preferences_service.dart';
import '../../../core/widgets/bottom_nav_bar.dart';
import '../../auth/data/offline_auth_repository.dart';
import '../../auth/data/supabase_auth_repository.dart';
import '../../auth/domain/auth_controller.dart';
import '../../auth/presentation/account_profile_screen.dart';
import '../../auth/presentation/login_screen.dart';
import '../../documents/data/local_documents_repository.dart';
import '../../documents/domain/documents_controller.dart';
import '../../documents/presentation/documents_screen.dart';
import '../../home/domain/home_controller.dart';
import '../../home/presentation/home_screen.dart';
import '../../pdf_tools/presentation/pdf_tools_screen.dart';
import '../../scanner/presentation/scanner_screen.dart';
import '../../settings/domain/settings_controller.dart';
import '../../settings/presentation/settings_screen.dart';

/// Main Shell hosting bottom navigation and tab switching.
class MainShellScreen extends StatefulWidget {
  final PreferencesService preferencesService;
  final int initialIndex;

  const MainShellScreen({
    super.key,
    required this.preferencesService,
    this.initialIndex = 0,
  });

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  late int _currentIndex;
  late final AuthController _authController;
  late final LocalDocumentsRepository _repository;
  late final HomeController _homeController;
  late final DocumentsController _documentsController;
  late final SettingsController _settingsController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    final authRepo = AppConfig.isSupabaseConfigured
        ? SupabaseAuthRepository()
        : OfflineAuthRepository();
    _authController = AuthController(authRepo);

    _repository = LocalDocumentsRepository(
      userIdProvider: () => _authController.currentUser?.id ?? 'local_user',
    );
    _homeController = HomeController(_repository);
    _documentsController = DocumentsController(_repository);
    _settingsController = SettingsController(widget.preferencesService);

    _authController.addListener(_onAuthChanged);
  }

  void _onAuthChanged() {
    _homeController.refresh();
    _documentsController.loadData();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _authController.removeListener(_onAuthChanged);
    _authController.dispose();
    _homeController.dispose();
    _documentsController.dispose();
    _settingsController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (index == 2) {
      _openScanner();
      return;
    }
    setState(() => _currentIndex = index);
  }

  void _openScanner() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => ScannerScreen(
          userId: _authController.currentUser?.id ?? 'local_user',
          onBack: () {
            Navigator.of(context).pop();
            _homeController.refresh();
            _documentsController.loadData();
          },
        ),
      ),
    );
  }

  void _openAccount() {
    if (_authController.isAuthenticated) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AccountProfileScreen(
            controller: _authController,
            onSignedOut: () {
              Navigator.of(context).pop();
              _onAuthChanged();
            },
          ),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LoginScreen(
            controller: _authController,
            onLoginSuccess: () {
              Navigator.of(context).pop();
              _onAuthChanged();
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Map index 0->Home, 1->Documents, 3->Tools, 4->Settings
    final screenIndex = _currentIndex > 2 ? _currentIndex - 1 : _currentIndex;

    final screens = [
      HomeScreen(
        controller: _homeController,
        authController: _authController,
        onNavigateToDocuments: () => setState(() => _currentIndex = 1),
        onOpenScanner: _openScanner,
        onOpenTools: () => setState(() => _currentIndex = 3),
        onOpenAccount: _openAccount,
      ),
      DocumentsScreen(
        controller: _documentsController,
        onOpenScanner: _openScanner,
      ),
      const PdfToolsScreen(),
      SettingsScreen(
        controller: _settingsController,
        authController: _authController,
        onOpenAccount: _openAccount,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: screenIndex.clamp(0, screens.length - 1),
        children: screens,
      ),
      bottomNavigationBar: ScanVaultBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
        onScanPressed: _openScanner,
      ),
    );
  }
}
