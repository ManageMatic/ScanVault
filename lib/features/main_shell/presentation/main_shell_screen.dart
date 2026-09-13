import 'package:flutter/material.dart';
import '../../../core/services/preferences_service.dart';
import '../../../core/widgets/bottom_nav_bar.dart';
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
  late final LocalDocumentsRepository _repository;
  late final HomeController _homeController;
  late final DocumentsController _documentsController;
  late final SettingsController _settingsController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _repository = LocalDocumentsRepository();
    _homeController = HomeController(_repository);
    _documentsController = DocumentsController(_repository);
    _settingsController = SettingsController(widget.preferencesService);
  }

  @override
  void dispose() {
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
          onBack: () {
            Navigator.of(context).pop();
            _homeController.refresh();
            _documentsController.loadData();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Map index 0->Home, 1->Documents, 3->Tools, 4->Settings
    final screenIndex = _currentIndex > 2 ? _currentIndex - 1 : _currentIndex;

    final screens = [
      HomeScreen(
        controller: _homeController,
        onNavigateToDocuments: () => setState(() => _currentIndex = 1),
        onOpenScanner: _openScanner,
        onOpenTools: () => setState(() => _currentIndex = 3),
      ),
      DocumentsScreen(
        controller: _documentsController,
        onOpenScanner: _openScanner,
      ),
      const PdfToolsScreen(),
      SettingsScreen(controller: _settingsController),
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
