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
import 'package:scanvault/features/pdf_tools/presentation/widgets/tool_progress_modal.dart';

enum SplitMode {
  everyPage,
  customRanges,
}

class SplitPdfScreen extends StatefulWidget {
  const SplitPdfScreen({super.key});

  @override
  State<SplitPdfScreen> createState() => _SplitPdfScreenState();
}

class _SplitPdfScreenState extends State<SplitPdfScreen> {
  final PdfToolsRepository _repository = LocalPdfToolsRepository();

  File? _selectedFile;
  List<PdfPageInfo> _pages = [];
  bool _isLoadingPages = false;

  SplitMode _splitMode = SplitMode.customRanges;
  final TextEditingController _rangesController = TextEditingController(text: '1-2, 3-4');
  final TextEditingController _titleController = TextEditingController(text: 'Split_Doc');

  final ValueNotifier<PdfProcessingProgress> _progressNotifier = ValueNotifier(
    const PdfProcessingProgress(progress: 0.0, statusMessage: 'Idle'),
  );

  @override
  void dispose() {
    _rangesController.dispose();
    _titleController.dispose();
    _progressNotifier.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final picked = await PdfDocumentPickerSheet.show(
      context,
      title: 'Select PDF to Split',
      allowMultiple: false,
    );

    if (picked != null && picked.isNotEmpty) {
      final file = picked.first;
      setState(() {
        _selectedFile = file;
        _isLoadingPages = true;
        _titleController.text = p.basenameWithoutExtension(file.path);
      });

      final pages = await _repository.getPdfPages(pdfFile: file, generateThumbnails: false);
      if (mounted) {
        setState(() {
          _pages = pages;
          _isLoadingPages = false;
          if (pages.length > 2) {
            final mid = (pages.length / 2).ceil();
            _rangesController.text = '1-$mid, ${mid + 1}-${pages.length}';
          } else {
            _rangesController.text = '1, 2';
          }
        });
      }
    }
  }

  Future<void> _splitPdf() async {
    if (_selectedFile == null) return;

    const userId = 'local_user';
    final List<String> rangesToProcess;

    if (_splitMode == SplitMode.everyPage) {
      rangesToProcess = List.generate(_pages.length, (i) => '${i + 1}');
    } else {
      rangesToProcess = _rangesController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    if (rangesToProcess.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please specify valid page ranges.')),
      );
      return;
    }

    ToolProgressModal.show(context, _progressNotifier);

    final result = await _repository.splitPdf(
      userId: userId,
      sourcePdf: _selectedFile!,
      ranges: rangesToProcess,
      baseOutputTitle: _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : 'Split_Doc',
      onProgress: (prog) => _progressNotifier.value = prog,
    );

    if (mounted) {
      Navigator.of(context).pop(); // dismiss modal

      if (result.success) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PdfToolResultScreen(
              toolTitle: 'Split PDF',
              result: result,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Split operation failed.'),
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
          'Split PDF',
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
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary, size: 26),
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
                            _selectedFile != null
                                ? '${_pages.length} total pages detected'
                                : 'Tap to choose from vault or device',
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
              // 2. Base Output Title
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Base Output Title',
                  prefixIcon: const Icon(Icons.edit_note_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),

              // 3. Split Strategy
              Text(
                'SPLIT MODE',
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              const SizedBox(height: 8),

              SegmentedButton<SplitMode>(
                segments: const [
                  ButtonSegment(
                    value: SplitMode.customRanges,
                    label: Text('Custom Ranges'),
                    icon: Icon(Icons.view_week_rounded),
                  ),
                  ButtonSegment(
                    value: SplitMode.everyPage,
                    label: Text('Burst All Pages'),
                    icon: Icon(Icons.burst_mode_rounded),
                  ),
                ],
                selected: {_splitMode},
                onSelectionChanged: (val) => setState(() => _splitMode = val.first),
              ),
              const SizedBox(height: 16),

              if (_splitMode == SplitMode.customRanges) ...[
                TextField(
                  controller: _rangesController,
                  decoration: InputDecoration(
                    labelText: 'Page Ranges (Comma-separated)',
                    hintText: 'e.g. 1-3, 4-7, 8-10',
                    helperText: 'Creates separate files for each range expression.',
                    prefixIcon: const Icon(Icons.format_list_numbered_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Info card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 20, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _splitMode == SplitMode.everyPage
                            ? 'Will create ${_pages.length} individual 1-page PDF documents.'
                            : 'Ranges will be validated and saved as standalone documents.',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.onSecondaryContainer),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              FilledButton.icon(
                onPressed: _isLoadingPages ? null : _splitPdf,
                icon: const Icon(Icons.call_split_rounded),
                label: const Text('Split Document Now'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
