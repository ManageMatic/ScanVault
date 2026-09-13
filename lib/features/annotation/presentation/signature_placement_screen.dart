import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:scanvault/core/constants/app_colors.dart';
import 'package:scanvault/core/constants/app_typography.dart';
import 'package:scanvault/core/database/app_database.dart';
import 'package:scanvault/shared/models/document.dart';
import '../data/pdf_annotation_service.dart';
import '../data/signature_storage_service.dart';
import '../domain/models/digital_signature_model.dart';
import 'widgets/signature_pad_dialog.dart';

class SignaturePlacementScreen extends StatefulWidget {
  final Document document;
  final String userId;

  const SignaturePlacementScreen({
    super.key,
    required this.document,
    this.userId = 'local_user',
  });

  @override
  State<SignaturePlacementScreen> createState() => _SignaturePlacementScreenState();
}

class _SignaturePlacementScreenState extends State<SignaturePlacementScreen> {
  final SignatureStorageService _storageService = const SignatureStorageService();
  final PdfAnnotationService _annotationService = const PdfAnnotationService();
  final AppDatabase _database = AppDatabase();

  int _currentPageIndex = 0;
  int _totalPages = 1;
  Uint8List? _currentPageImageBytes;
  bool _isLoadingPage = true;
  bool _isSaving = false;

  List<DigitalSignature> _savedSignatures = [];
  DigitalSignature? _selectedSignature;

  // Normalized placement parameters
  double _posX = 0.5;
  double _posY = 0.75;
  double _scale = 0.35; // 35% of page width
  double _rotation = 0.0;

  @override
  void initState() {
    super.initState();
    _totalPages = widget.document.pageCount > 0 ? widget.document.pageCount : 1;
    _loadSignatures();
    _renderPage(_currentPageIndex);
  }

  Future<void> _loadSignatures() async {
    final list = await _storageService.getSignatures(widget.userId);
    if (mounted) {
      setState(() {
        _savedSignatures = list;
        if (list.isNotEmpty && _selectedSignature == null) {
          _selectedSignature = list.first;
        }
      });
    }
  }

  Future<void> _renderPage(int pageIndex) async {
    setState(() => _isLoadingPage = true);
    try {
      final file = File(widget.document.filePath);
      if (!await file.exists()) return;

      final pdfBytes = await file.readAsBytes();
      await for (final raster in Printing.raster(pdfBytes, pages: [pageIndex], dpi: 150)) {
        final pngBytes = await raster.toPng();
        if (mounted) {
          setState(() {
            _currentPageImageBytes = pngBytes;
            _isLoadingPage = false;
          });
        }
        break;
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingPage = false);
    }
  }

  Future<void> _createNewSignature() async {
    final created = await SignaturePadDialog.show(context, userId: widget.userId);
    if (created != null && mounted) {
      await _loadSignatures();
      setState(() {
        _selectedSignature = created;
      });
    }
  }

  Future<void> _saveSignedPdf() async {
    if (_selectedSignature == null) return;

    setState(() => _isSaving = true);
    try {
      final sourceFile = File(widget.document.filePath);
      final tempTarget = File('${sourceFile.path}.signed.tmp');

      const sigAspect = 2.0; // Standard 2:1 width-to-height ratio
      final normWidth = _scale;
      final normHeight = _scale / sigAspect;

      final placed = PlacedSignature(
        signatureImagePath: _selectedSignature!.imagePath,
        pageIndex: _currentPageIndex,
        normalizedX: (_posX - normWidth / 2).clamp(0.0, 1.0 - normWidth),
        normalizedY: (_posY - normHeight / 2).clamp(0.0, 1.0 - normHeight),
        normalizedWidth: normWidth,
        normalizedHeight: normHeight,
        rotationDegrees: _rotation,
      );

      await _annotationService.applyAnnotationsAndSignatures(
        sourcePdf: sourceFile,
        targetFile: tempTarget,
        annotations: const [],
        signatures: [placed],
      );

      if (await tempTarget.exists()) {
        await tempTarget.rename(sourceFile.path);
      }

      final updatedDoc = widget.document.copyWith(
        updatedAt: DateTime.now(),
        fileSize: await sourceFile.length(),
      );
      await _database.updateDocument(widget.userId, updatedDoc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signature stamped onto PDF safely.')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to stamp signature: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sign Document',
          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          FilledButton.tonal(
            onPressed: (_selectedSignature == null || _isSaving) ? null : _saveSignedPdf,
            child: _isSaving
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Apply Signature'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 1. Signature Selector Carousel
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _createNewSignature,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('New'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _savedSignatures.isEmpty
                      ? Text(
                          'No saved signatures. Tap "+ New" to draw or import.',
                          style: AppTypography.bodySmall.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        )
                      : SizedBox(
                          height: 44,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _savedSignatures.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, idx) {
                              final sig = _savedSignatures[idx];
                              final isSelected = _selectedSignature?.id == sig.id;

                              return InkWell(
                                onTap: () => setState(() => _selectedSignature = sig),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primaryContainer.withValues(alpha: 0.2)
                                        : (isDark ? AppColors.darkSurfaceContainerHigh : Colors.white),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected ? AppColors.primary : Colors.transparent,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Image.file(
                                        File(sig.imagePath),
                                        width: 40,
                                        height: 28,
                                        fit: BoxFit.contain,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        sig.title,
                                        style: AppTypography.labelSmall.copyWith(
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                          color: isSelected ? AppColors.primary : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),

          // 2. Interactive Document Canvas with Draggable Signature
          Expanded(
            child: _isLoadingPage
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _currentPageImageBytes == null
                    ? const Center(child: Text('Failed to load page.'))
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final canvasWidth = constraints.maxWidth;
                          final canvasHeight = constraints.maxHeight;

                          return Center(
                            child: AspectRatio(
                              aspectRatio: 1 / 1.414,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: Image.memory(
                                        _currentPageImageBytes!,
                                        fit: BoxFit.fill,
                                      ),
                                    ),

                                    // Interactive Placed Signature Overlay
                                    if (_selectedSignature != null)
                                      Positioned(
                                        left: (_posX * canvasWidth - (_scale * canvasWidth) / 2)
                                            .clamp(0.0, canvasWidth - (_scale * canvasWidth)),
                                        top: (_posY * canvasHeight - (_scale * canvasWidth / 2) / 2)
                                            .clamp(0.0, canvasHeight - (_scale * canvasWidth / 2)),
                                        child: GestureDetector(
                                          onPanUpdate: (details) {
                                            setState(() {
                                              _posX = (_posX + details.delta.dx / canvasWidth).clamp(0.0, 1.0);
                                              _posY = (_posY + details.delta.dy / canvasHeight).clamp(0.0, 1.0);
                                            });
                                          },
                                          child: Transform.rotate(
                                            angle: _rotation * (math.pi / 180.0),
                                            child: Container(
                                              width: _scale * canvasWidth,
                                              height: (_scale * canvasWidth) / 2,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: AppColors.primary,
                                                  width: 1.5,
                                                ),
                                                borderRadius: BorderRadius.circular(4),
                                                color: Colors.transparent,
                                              ),
                                              child: Stack(
                                                children: [
                                                  Positioned.fill(
                                                    child: Image.file(
                                                      File(_selectedSignature!.imagePath),
                                                      fit: BoxFit.contain,
                                                    ),
                                                  ),
                                                  Positioned(
                                                    top: 2,
                                                    right: 2,
                                                    child: Container(
                                                      padding: const EdgeInsets.all(2),
                                                      decoration: const BoxDecoration(
                                                        color: AppColors.primary,
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: const Icon(
                                                        Icons.open_with_rounded,
                                                        size: 12,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // 3. Size and Rotation Controls
          if (_selectedSignature != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
              child: Row(
                children: [
                  const Icon(Icons.photo_size_select_small_rounded, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Slider(
                      value: _scale,
                      min: 0.15,
                      max: 0.65,
                      activeColor: AppColors.primary,
                      onChanged: (v) => setState(() => _scale = v),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.rotate_right_rounded),
                    tooltip: 'Rotate 90°',
                    onPressed: () => setState(() => _rotation = (_rotation + 90) % 360),
                  ),
                ],
              ),
            ),

          // 4. Page Switcher
          if (_totalPages > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: _currentPageIndex > 0
                        ? () {
                            setState(() => _currentPageIndex--);
                            _renderPage(_currentPageIndex);
                          }
                        : null,
                  ),
                  Text(
                    'Page ${_currentPageIndex + 1} of $_totalPages',
                    style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: _currentPageIndex < _totalPages - 1
                        ? () {
                            setState(() => _currentPageIndex++);
                            _renderPage(_currentPageIndex);
                          }
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
