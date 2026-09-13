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

class PdfMetadataScreen extends StatefulWidget {
  const PdfMetadataScreen({super.key});

  @override
  State<PdfMetadataScreen> createState() => _PdfMetadataScreenState();
}

class _PdfMetadataScreenState extends State<PdfMetadataScreen> {
  final PdfToolsRepository _repository = LocalPdfToolsRepository();

  File? _selectedFile;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _keywordsController = TextEditingController();
  final TextEditingController _creatorController = TextEditingController();
  bool _isLoadingMetadata = false;

  final ValueNotifier<PdfProcessingProgress> _progressNotifier = ValueNotifier(
    const PdfProcessingProgress(progress: 0.0, statusMessage: 'Idle'),
  );

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _subjectController.dispose();
    _keywordsController.dispose();
    _creatorController.dispose();
    _progressNotifier.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final picked = await PdfDocumentPickerSheet.show(
      context,
      title: 'Select PDF for Metadata',
      allowMultiple: false,
    );

    if (picked != null && picked.isNotEmpty) {
      final file = picked.first;
      setState(() {
        _selectedFile = file;
        _isLoadingMetadata = true;
      });

      final meta = await _repository.readPdfMetadata(file);
      if (mounted) {
        setState(() {
          _titleController.text = meta.title ?? p.basenameWithoutExtension(file.path);
          _authorController.text = meta.author ?? '';
          _subjectController.text = meta.subject ?? '';
          _keywordsController.text = meta.keywords ?? '';
          _creatorController.text = meta.creator ?? 'ScanVault';
          _isLoadingMetadata = false;
        });
      }
    }
  }

  Future<void> _saveMetadata() async {
    if (_selectedFile == null) return;

    const userId = 'local_user';
    ToolProgressModal.show(context, _progressNotifier);

    final req = PdfMetadataEditRequest(
      title: _titleController.text.trim(),
      author: _authorController.text.trim(),
      subject: _subjectController.text.trim(),
      keywords: _keywordsController.text.trim(),
      creator: _creatorController.text.trim(),
    );

    final result = await _repository.updatePdfMetadata(
      userId: userId,
      sourcePdf: _selectedFile!,
      metadata: req,
      onProgress: (prog) => _progressNotifier.value = prog,
    );

    if (mounted) {
      Navigator.of(context).pop(); // dismiss modal

      if (result.success) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PdfToolResultScreen(
              toolTitle: 'PDF Metadata',
              result: result,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Metadata update failed.'),
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
          'PDF Metadata',
          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. File Selection Card
            InkWell(
              onTap: _pickFile,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _selectedFile != null
                        ? AppColors.primary
                        : (isDark ? AppColors.darkCardBorder : AppColors.cardBorder),
                    width: _selectedFile != null ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF855300).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.info_outline_rounded, color: Color(0xFF855300), size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedFile != null
                                ? p.basename(_selectedFile!.path)
                                : 'Select PDF Document',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _selectedFile != null ? 'Metadata loaded' : 'Tap to inspect & edit document properties',
                            style: AppTypography.bodySmall.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.swap_horiz_rounded),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (_selectedFile != null) ...[
              if (_isLoadingMetadata)
                const Center(child: CircularProgressIndicator(color: AppColors.primary))
              else ...[
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Document Title',
                    prefixIcon: const Icon(Icons.title_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: _authorController,
                  decoration: InputDecoration(
                    labelText: 'Author',
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: _subjectController,
                  decoration: InputDecoration(
                    labelText: 'Subject / Description',
                    prefixIcon: const Icon(Icons.subject_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: _keywordsController,
                  decoration: InputDecoration(
                    labelText: 'Keywords / Tags',
                    hintText: 'e.g. invoice, taxes, 2026',
                    prefixIcon: const Icon(Icons.tag_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: _creatorController,
                  decoration: InputDecoration(
                    labelText: 'Creator / Software',
                    prefixIcon: const Icon(Icons.computer_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 28),

                FilledButton.icon(
                  onPressed: _saveMetadata,
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Update PDF Metadata'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
