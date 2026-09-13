import 'dart:io';
import 'package:flutter/material.dart';
import 'package:scanvault/core/constants/app_colors.dart';
import 'package:scanvault/core/constants/app_typography.dart';
import 'package:scanvault/features/pdf_tools/data/repositories/local_pdf_tools_repository.dart';
import 'package:scanvault/features/pdf_tools/domain/entities/pdf_page_info.dart';
import 'package:scanvault/features/pdf_tools/domain/entities/pdf_processing_progress.dart';
import 'package:scanvault/features/pdf_tools/domain/repositories/pdf_tools_repository.dart';
import 'package:scanvault/features/pdf_tools/presentation/screens/pdf_tool_result_screen.dart';
import 'package:scanvault/features/pdf_tools/presentation/widgets/pdf_document_picker_sheet.dart';
import 'package:scanvault/features/pdf_tools/presentation/widgets/pdf_page_grid_view.dart';
import 'package:scanvault/features/pdf_tools/presentation/widgets/tool_progress_modal.dart';

class RotatePdfScreen extends StatefulWidget {
  const RotatePdfScreen({super.key});

  @override
  State<RotatePdfScreen> createState() => _RotatePdfScreenState();
}

class _RotatePdfScreenState extends State<RotatePdfScreen> {
  final PdfToolsRepository _repository = LocalPdfToolsRepository();

  File? _selectedFile;
  List<PdfPageInfo> _pages = [];
  final Set<int> _selectedPageIndices = {};
  final Map<int, int> _pageRotations = {};
  bool _isLoadingPages = false;

  final ValueNotifier<PdfProcessingProgress> _progressNotifier = ValueNotifier(
    const PdfProcessingProgress(progress: 0.0, statusMessage: 'Idle'),
  );

  @override
  void dispose() {
    _progressNotifier.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final picked = await PdfDocumentPickerSheet.show(
      context,
      title: 'Select PDF to Rotate',
      allowMultiple: false,
    );

    if (picked != null && picked.isNotEmpty) {
      final file = picked.first;
      setState(() {
        _selectedFile = file;
        _isLoadingPages = true;
        _selectedPageIndices.clear();
        _pageRotations.clear();
      });

      final pages = await _repository.getPdfPages(pdfFile: file, generateThumbnails: true);
      if (mounted) {
        setState(() {
          _pages = pages;
          _isLoadingPages = false;
        });
      }
    }
  }

  void _rotateSinglePage(int pageIndex) {
    setState(() {
      final current = _pageRotations[pageIndex] ?? 0;
      final next = (current + 90) % 360;
      if (next == 0) {
        _pageRotations.remove(pageIndex);
      } else {
        _pageRotations[pageIndex] = next;
      }

      final idx = _pages.indexWhere((p) => p.pageIndex == pageIndex);
      if (idx >= 0) {
        _pages[idx] = _pages[idx].copyWith(rotationDegrees: next);
      }
    });
  }

  void _rotateSelectedPages(int degrees) {
    setState(() {
      final targets = _selectedPageIndices.isNotEmpty
          ? _selectedPageIndices
          : List.generate(_pages.length, (i) => i).toSet();

      for (final idx in targets) {
        final current = _pageRotations[idx] ?? 0;
        final next = (current + degrees) % 360;
        if (next == 0) {
          _pageRotations.remove(idx);
        } else {
          _pageRotations[idx] = next;
        }

        final pageIdx = _pages.indexWhere((p) => p.pageIndex == idx);
        if (pageIdx >= 0) {
          _pages[pageIdx] = _pages[pageIdx].copyWith(rotationDegrees: next);
        }
      }
    });
  }

  Future<void> _saveRotation() async {
    if (_selectedFile == null || _pageRotations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No rotations were applied.')),
      );
      return;
    }

    const userId = 'local_user';
    ToolProgressModal.show(context, _progressNotifier);

    final result = await _repository.rotatePages(
      userId: userId,
      sourcePdf: _selectedFile!,
      pageRotations: _pageRotations,
      onProgress: (prog) => _progressNotifier.value = prog,
    );

    if (mounted) {
      Navigator.of(context).pop(); // dismiss modal

      if (result.success) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PdfToolResultScreen(
              toolTitle: 'Rotate PDF',
              result: result,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Rotation failed.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Rotate PDF',
          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (_selectedFile != null)
            IconButton(
              icon: const Icon(Icons.swap_horiz_rounded),
              tooltip: 'Switch PDF',
              onPressed: _pickFile,
            ),
        ],
      ),
      body: _selectedFile == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.rotate_right_rounded,
                        size: 32,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No PDF selected',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Select a PDF to rotate individual pages or the entire document.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.picture_as_pdf_rounded),
                      label: const Text('Select PDF Document'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : _isLoadingPages
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : Column(
                  children: [
                    // Toolbar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectedPageIndices.isEmpty
                                  ? 'All ${_pages.length} Pages'
                                  : '${_selectedPageIndices.length} Selected',
                              style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.rotate_90_degrees_cw_rounded),
                            tooltip: 'Rotate 90°',
                            onPressed: () => _rotateSelectedPages(90),
                          ),
                          IconButton(
                            icon: const Icon(Icons.sync_rounded),
                            tooltip: 'Rotate 180°',
                            onPressed: () => _rotateSelectedPages(180),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                if (_selectedPageIndices.length == _pages.length) {
                                  _selectedPageIndices.clear();
                                } else {
                                  _selectedPageIndices.addAll(List.generate(_pages.length, (i) => i));
                                }
                              });
                            },
                            child: Text(_selectedPageIndices.length == _pages.length ? 'Deselect' : 'Select All'),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: PdfPageGridView(
                        pages: _pages,
                        selectedPageIndices: _selectedPageIndices,
                        isSelectionMode: true,
                        allowRotation: true,
                        onPageTapped: (idx) {
                          setState(() {
                            if (_selectedPageIndices.contains(idx)) {
                              _selectedPageIndices.remove(idx);
                            } else {
                              _selectedPageIndices.add(idx);
                            }
                          });
                        },
                        onRotatePage: _rotateSinglePage,
                      ),
                    ),

                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: FilledButton.icon(
                          onPressed: _pageRotations.isEmpty ? null : _saveRotation,
                          icon: const Icon(Icons.save_rounded),
                          label: Text('Save Rotated Document (${_pageRotations.length} changed)'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
