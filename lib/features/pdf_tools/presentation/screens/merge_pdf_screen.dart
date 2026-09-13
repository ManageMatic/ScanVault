import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:scanvault/core/constants/app_colors.dart';
import 'package:scanvault/core/constants/app_typography.dart';
import 'package:scanvault/features/pdf_tools/data/repositories/local_pdf_tools_repository.dart';
import 'package:scanvault/features/pdf_tools/domain/entities/pdf_processing_progress.dart';
import 'package:scanvault/features/pdf_tools/domain/repositories/pdf_tools_repository.dart';
import 'package:scanvault/features/pdf_tools/presentation/screens/pdf_tool_result_screen.dart';
import 'package:scanvault/features/pdf_tools/presentation/widgets/pdf_document_picker_sheet.dart';
import 'package:scanvault/features/pdf_tools/presentation/widgets/tool_progress_modal.dart';

class MergePdfScreen extends StatefulWidget {
  const MergePdfScreen({super.key});

  @override
  State<MergePdfScreen> createState() => _MergePdfScreenState();
}

class _MergePdfScreenState extends State<MergePdfScreen> {
  final PdfToolsRepository _repository = LocalPdfToolsRepository();
  final TextEditingController _titleController = TextEditingController(text: 'Merged_Document');

  final List<File> _selectedFiles = [];
  bool _isProcessing = false;
  final ValueNotifier<PdfProcessingProgress> _progressNotifier = ValueNotifier(
    const PdfProcessingProgress(progress: 0.0, statusMessage: 'Idle'),
  );

  @override
  void dispose() {
    _titleController.dispose();
    _progressNotifier.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final picked = await PdfDocumentPickerSheet.show(
      context,
      title: 'Select PDFs to Merge',
      allowMultiple: true,
    );

    if (picked != null && picked.isNotEmpty) {
      setState(() {
        for (final f in picked) {
          if (!_selectedFiles.any((existing) => existing.path == f.path)) {
            _selectedFiles.add(f);
          }
        }
      });
    }
  }

  Future<void> _mergePdfs() async {
    if (_selectedFiles.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least 2 PDF documents to merge.')),
      );
      return;
    }

    const userId = 'local_user';
    final outputTitle = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : 'Merged_Document';

    setState(() => _isProcessing = true);
    ToolProgressModal.show(context, _progressNotifier);

    final result = await _repository.mergePdfs(
      userId: userId,
      sourcePdfs: _selectedFiles,
      outputTitle: outputTitle,
      onProgress: (prog) => _progressNotifier.value = prog,
    );

    if (mounted) {
      Navigator.of(context).pop(); // dismiss progress modal
      setState(() => _isProcessing = false);

      if (result.success) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PdfToolResultScreen(
              toolTitle: 'Merge PDF',
              result: result,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Merge operation failed.'),
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
          'Merge PDF',
          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          // Header / Instructions
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Output Document Title',
                prefixIcon: const Icon(Icons.edit_note_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          Expanded(
            child: _selectedFiles.isEmpty
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
                              Icons.call_merge_rounded,
                              size: 32,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No PDF files selected',
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Select 2 or more local PDFs to combine them in your preferred sequence.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: _pickFiles,
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add PDF Documents'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'FILES TO MERGE (${_selectedFiles.length})',
                              style: AppTypography.labelSmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _pickFiles,
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add More'),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ReorderableListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _selectedFiles.length,
                          onReorder: (oldIndex, newIndex) {
                            setState(() {
                              if (newIndex > oldIndex) newIndex--;
                              final item = _selectedFiles.removeAt(oldIndex);
                              _selectedFiles.insert(newIndex, item);
                            });
                          },
                          itemBuilder: (context, index) {
                            final file = _selectedFiles[index];
                            final filename = p.basename(file.path);

                            return Card(
                              key: ValueKey(file.path),
                              margin: const EdgeInsets.only(bottom: 8),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder,
                                ),
                              ),
                              child: ListTile(
                                leading: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: AppTypography.labelMedium.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  filename,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  'Drag handle on right to reorder',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.close_rounded, size: 20),
                                      color: AppColors.error,
                                      onPressed: () {
                                        setState(() => _selectedFiles.removeAt(index));
                                      },
                                    ),
                                    const Icon(Icons.drag_handle_rounded),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),

          if (_selectedFiles.isNotEmpty)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: _isProcessing || _selectedFiles.length < 2 ? null : _mergePdfs,
                  icon: const Icon(Icons.call_merge_rounded),
                  label: Text('Merge ${_selectedFiles.length} PDFs'),
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
