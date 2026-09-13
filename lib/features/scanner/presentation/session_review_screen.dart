import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/database/app_database.dart';
import '../../../core/storage/storage_manager_service.dart';
import '../../../shared/models/document.dart';
import '../../../shared/models/folder.dart';
import '../../pdf_creation/domain/pdf_generator_service.dart';
import '../domain/scanned_page_item.dart';
import '../domain/scanner_controller.dart';
import 'crop_screen.dart';
import 'enhancement_screen.dart';

/// Screen allowing users to review, reorder, enhance, crop pages, and generate optimized PDFs.
class SessionReviewScreen extends StatefulWidget {
  final ScannerController scannerController;
  final String userId;
  final VoidCallback onSaved;

  const SessionReviewScreen({
    super.key,
    required this.scannerController,
    this.userId = 'local_user',
    required this.onSaved,
  });

  @override
  State<SessionReviewScreen> createState() => _SessionReviewScreenState();
}

class _SessionReviewScreenState extends State<SessionReviewScreen> {
  late PageController _pageController;
  int _currentPageIndex = 0;
  bool _isGeneratingPdf = false;
  CompressionPreset _selectedPreset = CompressionPreset.balanced;
  List<Folder> _folders = [];
  String? _selectedFolderId;
  final TextEditingController _titleController = TextEditingController();

  final AppDatabase _db = AppDatabase();
  late final StorageManagerService _storageService;
  late final PdfGeneratorService _pdfGenerator;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _storageService = StorageManagerService();
    _pdfGenerator = PdfGeneratorService(_db, _storageService);

    final nowStr = DateFormat('ddMMM_HHmm').format(DateTime.now());
    _titleController.text = 'ScanDoc_$nowStr';

    _loadFolders();
  }

  Future<void> _loadFolders() async {
    final folders = await _db.getFoldersForUser(widget.userId);
    if (mounted) {
      setState(() {
        _folders = folders;
        if (folders.isNotEmpty) {
          _selectedFolderId = folders.first.id;
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _openCrop(ScannedPageItem page) async {
    final updated = await Navigator.of(context).push<ScannedPageItem>(
      MaterialPageRoute(
        builder: (_) => CropScreen(page: page),
      ),
    );
    if (updated != null) {
      widget.scannerController.updatePage(updated);
      setState(() {});
    }
  }

  void _openEnhance(ScannedPageItem page) async {
    final updated = await Navigator.of(context).push<ScannedPageItem>(
      MaterialPageRoute(
        builder: (_) => EnhancementScreen(page: page),
      ),
    );
    if (updated != null) {
      widget.scannerController.updatePage(updated);
      setState(() {});
    }
  }

  void _showSaveDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Save to Vault',
                      style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Document Title Field
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Document Title',
                    prefixIcon: const Icon(Icons.description_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),

                // Folder Selector
                Text(
                  'Destination Folder',
                  style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.outlineVariant),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedFolderId,
                      items: _folders.map((f) {
                        return DropdownMenuItem<String>(
                          value: f.id,
                          child: Text(f.name),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setModalState(() => _selectedFolderId = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Compression Presets
                Text(
                  'PDF Optimization Preset',
                  style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildPresetOption(
                      title: 'Small',
                      desc: '~150 DPI',
                      preset: CompressionPreset.small,
                      selected: _selectedPreset,
                      onTap: () => setModalState(() => _selectedPreset = CompressionPreset.small),
                    ),
                    const SizedBox(width: 8),
                    _buildPresetOption(
                      title: 'Balanced',
                      desc: '~200 DPI',
                      preset: CompressionPreset.balanced,
                      selected: _selectedPreset,
                      onTap: () => setModalState(() => _selectedPreset = CompressionPreset.balanced),
                    ),
                    const SizedBox(width: 8),
                    _buildPresetOption(
                      title: 'High',
                      desc: '~300 DPI',
                      preset: CompressionPreset.highQuality,
                      selected: _selectedPreset,
                      onTap: () => setModalState(() => _selectedPreset = CompressionPreset.highQuality),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Confirm Save Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _executeSavePdf();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.save_rounded, color: Colors.white),
                    label: Text(
                      'Save PDF Document',
                      style: AppTypography.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPresetOption({
    required String title,
    required String desc,
    required CompressionPreset preset,
    required CompressionPreset selected,
    required VoidCallback onTap,
  }) {
    final isSel = preset == selected;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSel ? AppColors.primary.withValues(alpha: 0.12) : AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSel ? AppColors.primary : AppColors.outlineVariant,
              width: isSel ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                title,
                style: AppTypography.labelMedium.copyWith(
                  color: isSel ? AppColors.primary : null,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: AppTypography.labelSmall.copyWith(
                  color: isSel ? AppColors.primary : Colors.grey,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _executeSavePdf() async {
    setState(() => _isGeneratingPdf = true);

    try {
      final pages = widget.scannerController.pages;
      final rawImages = <dynamic>[];

      for (final p in pages) {
        if (p.cachedProcessedBytes != null) {
          rawImages.add(p.cachedProcessedBytes!);
        } else {
          final f = File(p.originalImagePath);
          if (await f.exists()) {
            rawImages.add(await f.readAsBytes());
          }
        }
      }

      final doc = await _pdfGenerator.createOptimizedPdf(
        userId: widget.userId,
        params: PdfCreationParams(
          title: _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : 'Scan Document',
          pageImages: rawImages.cast(),
          compressionPreset: _selectedPreset,
          folderId: _selectedFolderId,
        ),
      );

      widget.scannerController.clearSession();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved "${doc.title}" (${(doc.fileSize / 1024).toStringAsFixed(1)} KB) to Vault'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onSaved();
      }
    } catch (e) {
      debugPrint('Error generating PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save document: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = widget.scannerController.pages;

    if (pages.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Review Pages')),
        body: const Center(child: Text('No pages captured.')),
      );
    }

    final currentPage = pages[_currentPageIndex.clamp(0, pages.length - 1)];

    return Scaffold(
      backgroundColor: const Color(0xFF101418),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101418),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Page ${_currentPageIndex + 1} of ${pages.length}',
          style: AppTypography.titleMedium.copyWith(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            tooltip: 'Delete Page',
            onPressed: () {
              widget.scannerController.removePage(currentPage.id);
              if (widget.scannerController.pages.isEmpty) {
                Navigator.of(context).pop();
              } else {
                setState(() {
                  _currentPageIndex = _currentPageIndex.clamp(0, widget.scannerController.pages.length - 1);
                });
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Swipeable Big Preview
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: pages.length,
                  onPageChanged: (idx) => setState(() => _currentPageIndex = idx),
                  itemBuilder: (context, index) {
                    final page = pages[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A222B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.6),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _buildPagePreview(page),
                      ),
                    );
                  },
                ),
              ),

              // Page Editing Action Toolbar
              Container(
                height: 64,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFF1E2632),
                  border: Border(top: BorderSide(color: Colors.white12)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPageActionBtn(
                      icon: Icons.crop_rounded,
                      label: 'Crop',
                      onTap: () => _openCrop(currentPage),
                    ),
                    _buildPageActionBtn(
                      icon: Icons.auto_fix_high_rounded,
                      label: 'Filters',
                      onTap: () => _openEnhance(currentPage),
                    ),
                    _buildPageActionBtn(
                      icon: Icons.rotate_right_rounded,
                      label: 'Rotate',
                      onTap: () {
                        widget.scannerController.rotatePage(currentPage.id);
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),

              // Bottom Ribbon with Page Counter and Actions
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFF141920),
                  border: Border(top: BorderSide(color: Colors.white10)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      // Add Page Button
                      OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop(), // Back to camera
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white38),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.add_a_photo_rounded, size: 18),
                        label: const Text('+ Add Page'),
                      ),
                      const SizedBox(width: 12),

                      // Save to Vault Button
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _showSaveDialog,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.save_rounded, color: Colors.white),
                          label: Text(
                            'Save to Vault (${pages.length})',
                            style: AppTypography.labelLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Loading Progress Overlay during PDF Generation
          if (_isGeneratingPdf)
            Container(
              color: Colors.black87,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E242B),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: AppColors.primary),
                      const SizedBox(height: 18),
                      Text(
                        'Generating Optimized PDF...',
                        style: AppTypography.titleSmall.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Applying filters & compressing pages',
                        style: AppTypography.bodySmall.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPagePreview(ScannedPageItem page) {
    if (page.cachedProcessedBytes != null && page.cachedProcessedBytes!.isNotEmpty) {
      return Image.memory(
        page.cachedProcessedBytes!,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Image.memory error in review: $error');
          return _buildFileFallback(page.originalImagePath);
        },
      );
    }
    return _buildFileFallback(page.originalImagePath);
  }

  Widget _buildFileFallback(String path) {
    if (path.isNotEmpty) {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Image.file error in review: $error');
            return _buildErrorCard('Image could not be rendered');
          },
        );
      }
    }
    return _buildErrorCard('Image file not found on device');
  }

  Widget _buildErrorCard(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.broken_image_rounded, color: Colors.white38, size: 56),
            const SizedBox(height: 12),
            Text(
              message,
              style: AppTypography.bodySmall.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageActionBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
