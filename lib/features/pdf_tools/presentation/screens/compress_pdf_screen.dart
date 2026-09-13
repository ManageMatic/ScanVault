import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:scanvault/core/constants/app_colors.dart';
import 'package:scanvault/core/constants/app_typography.dart';
import 'package:scanvault/core/extensions/file_size_extensions.dart';
import 'package:scanvault/features/pdf_tools/data/repositories/local_pdf_tools_repository.dart';
import 'package:scanvault/features/pdf_tools/domain/entities/pdf_processing_progress.dart';
import 'package:scanvault/features/pdf_tools/domain/repositories/pdf_tools_repository.dart';
import 'package:scanvault/features/pdf_tools/presentation/screens/pdf_tool_result_screen.dart';
import 'package:scanvault/features/pdf_tools/presentation/widgets/pdf_document_picker_sheet.dart';
import 'package:scanvault/features/pdf_tools/presentation/widgets/tool_progress_modal.dart';
import 'package:scanvault/shared/models/document.dart';

class CompressPdfScreen extends StatefulWidget {
  const CompressPdfScreen({super.key});

  @override
  State<CompressPdfScreen> createState() => _CompressPdfScreenState();
}

class _CompressPdfScreenState extends State<CompressPdfScreen> {
  final PdfToolsRepository _repository = LocalPdfToolsRepository();

  File? _selectedFile;
  int _originalSizeBytes = 0;
  CompressionPreset _selectedPreset = CompressionPreset.small;

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
      title: 'Select PDF to Compress',
      allowMultiple: false,
    );

    if (picked != null && picked.isNotEmpty) {
      final file = picked.first;
      final size = await file.length();
      setState(() {
        _selectedFile = file;
        _originalSizeBytes = size;
      });
    }
  }

  Future<void> _compressPdf() async {
    if (_selectedFile == null) return;

    const userId = 'local_user';
    ToolProgressModal.show(context, _progressNotifier);

    final result = await _repository.compressPdf(
      userId: userId,
      sourcePdf: _selectedFile!,
      preset: _selectedPreset,
      onProgress: (prog) => _progressNotifier.value = prog,
    );

    if (mounted) {
      Navigator.of(context).pop(); // dismiss modal

      if (result.success) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PdfToolResultScreen(
              toolTitle: 'Compress PDF',
              result: result,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Compression failed.'),
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
          'Compress PDF',
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
                                ? 'Original Size: ${_originalSizeBytes.formattedFileSize}'
                                : 'Tap to select document to shrink',
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
            const SizedBox(height: 24),

            if (_selectedFile != null) ...[
              Text(
                'COMPRESSION PRESET',
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              const SizedBox(height: 12),

              _buildPresetCard(
                preset: CompressionPreset.small,
                title: 'Small (~65-75% reduction)',
                subtitle: 'Maximum compression. Best for emailing, sharing, and archiving.',
                icon: Icons.compress_rounded,
              ),
              const SizedBox(height: 10),

              _buildPresetCard(
                preset: CompressionPreset.balanced,
                title: 'Balanced (~40-55% reduction)',
                subtitle: 'Great balance of file size and visual sharpness for reading.',
                icon: Icons.tune_rounded,
              ),
              const SizedBox(height: 10),

              _buildPresetCard(
                preset: CompressionPreset.highQuality,
                title: 'High Quality (~15-25% reduction)',
                subtitle: 'Near-lossless clarity for high-resolution graphics and printing.',
                icon: Icons.high_quality_rounded,
              ),
              const SizedBox(height: 28),

              FilledButton.icon(
                onPressed: _compressPdf,
                icon: const Icon(Icons.zoom_in_map_rounded),
                label: const Text('Compress PDF Now'),
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

  Widget _buildPresetCard({
    required CompressionPreset preset,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedPreset == preset;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => setState(() => _selectedPreset = preset),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : (isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : (isDark ? AppColors.darkCardBorder : AppColors.cardBorder),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.darkSurfaceContainerHigh : AppColors.surfaceContainerHigh),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isSelected ? AppColors.primary : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Radio<CompressionPreset>(
              value: preset,
              groupValue: _selectedPreset,
              activeColor: AppColors.primary,
              onChanged: (v) {
                if (v != null) setState(() => _selectedPreset = v);
              },
            ),
          ],
        ),
      ),
    );
  }
}
