import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
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

class ExtractPagesScreen extends StatefulWidget {
  const ExtractPagesScreen({super.key});

  @override
  State<ExtractPagesScreen> createState() => _ExtractPagesScreenState();
}

class _ExtractPagesScreenState extends State<ExtractPagesScreen> {
  final PdfToolsRepository _repository = LocalPdfToolsRepository();

  File? _selectedFile;
  List<PdfPageInfo> _pages = [];
  final List<int> _extractedPageIndices = [];
  bool _isLoadingPages = false;
  final TextEditingController _titleController = TextEditingController(text: 'Extracted_Pages');

  final ValueNotifier<PdfProcessingProgress> _progressNotifier = ValueNotifier(
    const PdfProcessingProgress(progress: 0.0, statusMessage: 'Idle'),
  );

  @override
  void dispose() {
    _titleController.dispose();
    _progressNotifier.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final picked = await PdfDocumentPickerSheet.show(
      context,
      title: 'Select PDF to Extract Pages',
      allowMultiple: false,
    );

    if (picked != null && picked.isNotEmpty) {
      final file = picked.first;
      setState(() {
        _selectedFile = file;
        _isLoadingPages = true;
        _extractedPageIndices.clear();
        _titleController.text = '${p.basenameWithoutExtension(file.path)}_Extracted';
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

  Future<void> _extractPages() async {
    if (_selectedFile == null || _extractedPageIndices.isEmpty) return;

    const userId = 'local_user';
    ToolProgressModal.show(context, _progressNotifier);

    final result = await _repository.extractPages(
      userId: userId,
      sourcePdf: _selectedFile!,
      pageIndices: _extractedPageIndices,
      outputTitle: _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : 'Extracted_Pages',
      onProgress: (prog) => _progressNotifier.value = prog,
    );

    if (mounted) {
      Navigator.of(context).pop(); // dismiss modal

      if (result.success) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PdfToolResultScreen(
              toolTitle: 'Extract Pages',
              result: result,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Extraction failed.'),
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
          'Extract Pages',
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
                      child: const Icon(Icons.content_copy_rounded, size: 32, color: AppColors.primary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No PDF selected',
                      style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Select a PDF to extract specific pages into a new document.',
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${_extractedPageIndices.length} of ${_pages.length} Pages Selected',
                              style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                if (_extractedPageIndices.length == _pages.length) {
                                  _extractedPageIndices.clear();
                                } else {
                                  _extractedPageIndices.clear();
                                  _extractedPageIndices.addAll(List.generate(_pages.length, (i) => i));
                                }
                              });
                            },
                            child: Text(_extractedPageIndices.length == _pages.length ? 'Clear' : 'Select All'),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: PdfPageGridView(
                        pages: _pages,
                        selectedPageIndices: _extractedPageIndices.toSet(),
                        isSelectionMode: true,
                        onPageTapped: (idx) {
                          setState(() {
                            if (_extractedPageIndices.contains(idx)) {
                              _extractedPageIndices.remove(idx);
                            } else {
                              _extractedPageIndices.add(idx);
                            }
                          });
                        },
                      ),
                    ),

                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: FilledButton.icon(
                          onPressed: _extractedPageIndices.isEmpty ? null : _extractPages,
                          icon: const Icon(Icons.save_alt_rounded),
                          label: Text('Extract ${_extractedPageIndices.length} Page(s) as New PDF'),
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
