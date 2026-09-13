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

class PdfToImagesScreen extends StatefulWidget {
  const PdfToImagesScreen({super.key});

  @override
  State<PdfToImagesScreen> createState() => _PdfToImagesScreenState();
}

class _PdfToImagesScreenState extends State<PdfToImagesScreen> {
  final PdfToolsRepository _repository = LocalPdfToolsRepository();

  File? _selectedFile;
  List<PdfPageInfo> _pages = [];
  final Set<int> _selectedPageIndices = {};
  bool _isLoadingPages = false;
  bool _isPng = false; // false = JPG, true = PNG
  int _dpi = 200;

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
      title: 'Select PDF to Convert to Images',
      allowMultiple: false,
    );

    if (picked != null && picked.isNotEmpty) {
      final file = picked.first;
      setState(() {
        _selectedFile = file;
        _isLoadingPages = true;
        _selectedPageIndices.clear();
      });

      final pages = await _repository.getPdfPages(pdfFile: file, generateThumbnails: true);
      if (mounted) {
        setState(() {
          _pages = pages;
          _isLoadingPages = false;
          _selectedPageIndices.addAll(List.generate(pages.length, (i) => i));
        });
      }
    }
  }

  Future<void> _exportImages() async {
    if (_selectedFile == null || _selectedPageIndices.isEmpty) return;

    const userId = 'local_user';
    final pageList = _selectedPageIndices.toList()..sort();

    ToolProgressModal.show(context, _progressNotifier);

    final result = await _repository.pdfToImages(
      userId: userId,
      sourcePdf: _selectedFile!,
      pageIndices: pageList,
      isPng: _isPng,
      dpi: _dpi,
      onProgress: (prog) => _progressNotifier.value = prog,
    );

    if (mounted) {
      Navigator.of(context).pop(); // dismiss modal

      if (result.success) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PdfToolResultScreen(
              toolTitle: 'PDF → Images',
              result: result,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Image export failed.'),
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
          'PDF → Images',
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
                      child: const Icon(Icons.image_rounded, size: 32, color: AppColors.primary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No PDF selected',
                      style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Select a PDF to render high-resolution JPG or PNG images of pages.',
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
                    // Format Options Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      child: Row(
                        children: [
                          SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment(value: false, label: Text('JPG')),
                              ButtonSegment(value: true, label: Text('PNG')),
                            ],
                            selected: {_isPng},
                            onSelectionChanged: (val) => setState(() => _isPng = val.first),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue: _dpi,
                              decoration: const InputDecoration(
                                isDense: true,
                                labelText: 'Resolution',
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(value: 150, child: Text('150 DPI (Fast)')),
                                DropdownMenuItem(value: 200, child: Text('200 DPI (Crisp)')),
                                DropdownMenuItem(value: 300, child: Text('300 DPI (HD)')),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _dpi = v);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: PdfPageGridView(
                        pages: _pages,
                        selectedPageIndices: _selectedPageIndices,
                        isSelectionMode: true,
                        onPageTapped: (idx) {
                          setState(() {
                            if (_selectedPageIndices.contains(idx)) {
                              _selectedPageIndices.remove(idx);
                            } else {
                              _selectedPageIndices.add(idx);
                            }
                          });
                        },
                      ),
                    ),

                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: FilledButton.icon(
                          onPressed: _selectedPageIndices.isEmpty ? null : _exportImages,
                          icon: const Icon(Icons.download_rounded),
                          label: Text(
                            'Export ${_selectedPageIndices.length} Image(s) as ${_isPng ? 'PNG' : 'JPG'}',
                          ),
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
