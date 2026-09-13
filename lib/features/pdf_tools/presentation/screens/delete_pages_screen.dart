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

class DeletePagesScreen extends StatefulWidget {
  const DeletePagesScreen({super.key});

  @override
  State<DeletePagesScreen> createState() => _DeletePagesScreenState();
}

class _DeletePagesScreenState extends State<DeletePagesScreen> {
  final PdfToolsRepository _repository = LocalPdfToolsRepository();

  File? _selectedFile;
  List<PdfPageInfo> _pages = [];
  final Set<int> _selectedPageIndicesToDelete = {};
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
      title: 'Select PDF to Delete Pages',
      allowMultiple: false,
    );

    if (picked != null && picked.isNotEmpty) {
      final file = picked.first;
      setState(() {
        _selectedFile = file;
        _isLoadingPages = true;
        _selectedPageIndicesToDelete.clear();
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

  Future<void> _confirmAndDelete() async {
    if (_selectedFile == null || _selectedPageIndicesToDelete.isEmpty) return;

    if (_selectedPageIndicesToDelete.length >= _pages.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete all pages. At least 1 page must remain.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Pages?'),
        content: Text(
          'Are you sure you want to permanently delete ${_selectedPageIndicesToDelete.length} page(s)? '
          '${_pages.length - _selectedPageIndicesToDelete.length} page(s) will remain.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete Pages'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    const userId = 'local_user';
    ToolProgressModal.show(context, _progressNotifier);

    final result = await _repository.deletePages(
      userId: userId,
      sourcePdf: _selectedFile!,
      pageIndicesToDelete: _selectedPageIndicesToDelete,
      onProgress: (prog) => _progressNotifier.value = prog,
    );

    if (mounted) {
      Navigator.of(context).pop(); // dismiss modal

      if (result.success) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PdfToolResultScreen(
              toolTitle: 'Delete Pages',
              result: result,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Deletion failed.'),
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
          'Delete Pages',
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
                        color: AppColors.error.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.delete_outline_rounded, size: 32, color: AppColors.error),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No PDF selected',
                      style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Select a PDF to inspect thumbnails and remove unwanted pages safely.',
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
                              _selectedPageIndicesToDelete.isEmpty
                                  ? 'Tap pages to mark for deletion'
                                  : '${_selectedPageIndicesToDelete.length} page(s) marked for removal',
                              style: AppTypography.labelLarge.copyWith(
                                fontWeight: FontWeight.w700,
                                color: _selectedPageIndicesToDelete.isNotEmpty ? AppColors.error : null,
                              ),
                            ),
                          ),
                          if (_selectedPageIndicesToDelete.isNotEmpty)
                            TextButton(
                              onPressed: () => setState(() => _selectedPageIndicesToDelete.clear()),
                              child: const Text('Clear'),
                            ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: PdfPageGridView(
                        pages: _pages,
                        selectedPageIndices: _selectedPageIndicesToDelete,
                        isSelectionMode: true,
                        allowDelete: true,
                        onPageTapped: (idx) {
                          setState(() {
                            if (_selectedPageIndicesToDelete.contains(idx)) {
                              _selectedPageIndicesToDelete.remove(idx);
                            } else {
                              _selectedPageIndicesToDelete.add(idx);
                            }
                          });
                        },
                        onDeletePage: (idx) {
                          setState(() {
                            if (_selectedPageIndicesToDelete.contains(idx)) {
                              _selectedPageIndicesToDelete.remove(idx);
                            } else {
                              _selectedPageIndicesToDelete.add(idx);
                            }
                          });
                        },
                      ),
                    ),

                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: FilledButton.icon(
                          onPressed: _selectedPageIndicesToDelete.isEmpty ? null : _confirmAndDelete,
                          icon: const Icon(Icons.delete_forever_rounded),
                          label: Text('Delete ${_selectedPageIndicesToDelete.length} Page(s)'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            backgroundColor: AppColors.error,
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
