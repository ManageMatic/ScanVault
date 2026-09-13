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
import 'package:scanvault/features/pdf_tools/presentation/widgets/tool_progress_modal.dart';

class ReorderPagesScreen extends StatefulWidget {
  const ReorderPagesScreen({super.key});

  @override
  State<ReorderPagesScreen> createState() => _ReorderPagesScreenState();
}

class _ReorderPagesScreenState extends State<ReorderPagesScreen> {
  final PdfToolsRepository _repository = LocalPdfToolsRepository();

  File? _selectedFile;
  List<PdfPageInfo> _orderedPages = [];
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
      title: 'Select PDF to Reorder',
      allowMultiple: false,
    );

    if (picked != null && picked.isNotEmpty) {
      final file = picked.first;
      setState(() {
        _selectedFile = file;
        _isLoadingPages = true;
        _orderedPages.clear();
      });

      final pages = await _repository.getPdfPages(pdfFile: file, generateThumbnails: true);
      if (mounted) {
        setState(() {
          _orderedPages = pages;
          _isLoadingPages = false;
        });
      }
    }
  }

  Future<void> _saveReorderedPdf() async {
    if (_selectedFile == null || _orderedPages.isEmpty) return;

    const userId = 'local_user';
    final order = _orderedPages.map((p) => p.pageIndex).toList();

    ToolProgressModal.show(context, _progressNotifier);

    final result = await _repository.reorderPages(
      userId: userId,
      sourcePdf: _selectedFile!,
      newPageIndexOrder: order,
      onProgress: (prog) => _progressNotifier.value = prog,
    );

    if (mounted) {
      Navigator.of(context).pop(); // dismiss modal

      if (result.success) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PdfToolResultScreen(
              toolTitle: 'Reorder Pages',
              result: result,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Reordering failed.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Reorder Pages',
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
                      child: const Icon(Icons.drag_indicator_rounded, size: 32, color: AppColors.primary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No PDF selected',
                      style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Select a PDF to rearrange pages via drag-and-drop.',
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
                          const Icon(Icons.touch_app_rounded, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Long-press and drag cards to reorder',
                              style: AppTypography.labelMedium.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: ReorderableListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _orderedPages.length,
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) newIndex--;
                            final item = _orderedPages.removeAt(oldIndex);
                            _orderedPages.insert(newIndex, item);
                          });
                        },
                        itemBuilder: (context, index) {
                          final page = _orderedPages[index];

                          return Card(
                            key: ValueKey(page.pageIndex),
                            margin: const EdgeInsets.only(bottom: 10),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder,
                              ),
                            ),
                            child: ListTile(
                              leading: Container(
                                width: 44,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkSurfaceContainerHigh : AppColors.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: page.thumbnailBytes != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.memory(page.thumbnailBytes!, fit: BoxFit.cover),
                                      )
                                    : const Icon(Icons.description_outlined, size: 24),
                              ),
                              title: Text(
                                'Position ${index + 1}',
                                style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'Original Page ${page.pageNumber}',
                                style: AppTypography.bodySmall.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                              trailing: const Icon(Icons.drag_handle_rounded),
                            ),
                          );
                        },
                      ),
                    ),

                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: FilledButton.icon(
                          onPressed: _saveReorderedPdf,
                          icon: const Icon(Icons.save_rounded),
                          label: const Text('Save Reordered Document'),
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
