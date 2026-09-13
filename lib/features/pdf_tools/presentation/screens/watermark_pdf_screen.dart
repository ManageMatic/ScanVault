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

class WatermarkPdfScreen extends StatefulWidget {
  const WatermarkPdfScreen({super.key});

  @override
  State<WatermarkPdfScreen> createState() => _WatermarkPdfScreenState();
}

class _WatermarkPdfScreenState extends State<WatermarkPdfScreen> {
  final PdfToolsRepository _repository = LocalPdfToolsRepository();

  File? _selectedFile;
  final TextEditingController _watermarkTextController = TextEditingController(text: 'CONFIDENTIAL');
  final TextEditingController _titleController = TextEditingController();

  WatermarkPosition _position = WatermarkPosition.diagonal;
  double _opacity = 0.35;
  double _fontSize = 36.0;
  final double _rotation = 45.0;

  final ValueNotifier<PdfProcessingProgress> _progressNotifier = ValueNotifier(
    const PdfProcessingProgress(progress: 0.0, statusMessage: 'Idle'),
  );

  @override
  void dispose() {
    _watermarkTextController.dispose();
    _titleController.dispose();
    _progressNotifier.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final picked = await PdfDocumentPickerSheet.show(
      context,
      title: 'Select PDF to Watermark',
      allowMultiple: false,
    );

    if (picked != null && picked.isNotEmpty) {
      final file = picked.first;
      setState(() {
        _selectedFile = file;
        _titleController.text = '${p.basenameWithoutExtension(file.path)}_Watermarked';
      });
    }
  }

  Future<void> _applyWatermark() async {
    if (_selectedFile == null) return;

    final text = _watermarkTextController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter watermark text.')),
      );
      return;
    }

    const userId = 'local_user';
    ToolProgressModal.show(context, _progressNotifier);

    final config = WatermarkConfig(
      text: text,
      fontSize: _fontSize,
      opacity: _opacity,
      rotationDegrees: _rotation,
      position: _position,
    );

    final result = await _repository.watermarkPdf(
      userId: userId,
      sourcePdf: _selectedFile!,
      config: config,
      outputTitle: _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : null,
      onProgress: (prog) => _progressNotifier.value = prog,
    );

    if (mounted) {
      Navigator.of(context).pop(); // dismiss modal

      if (result.success) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PdfToolResultScreen(
              toolTitle: 'Watermark PDF',
              result: result,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Watermarking failed.'),
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
          'Watermark PDF',
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
                      child: const Icon(Icons.branding_watermark_rounded, color: Color(0xFF855300), size: 26),
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
                            _selectedFile != null ? 'Ready to stamp' : 'Tap to select document',
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
              TextField(
                controller: _watermarkTextController,
                decoration: InputDecoration(
                  labelText: 'Watermark Stamp Text',
                  prefixIcon: const Icon(Icons.text_fields_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'POSITION',
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              const SizedBox(height: 8),

              SegmentedButton<WatermarkPosition>(
                segments: const [
                  ButtonSegment(value: WatermarkPosition.diagonal, label: Text('Diagonal')),
                  ButtonSegment(value: WatermarkPosition.center, label: Text('Center')),
                  ButtonSegment(value: WatermarkPosition.top, label: Text('Top')),
                  ButtonSegment(value: WatermarkPosition.bottom, label: Text('Bottom')),
                ],
                selected: {_position},
                onSelectionChanged: (val) => setState(() => _position = val.first),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Opacity (${(_opacity * 100).toInt()}%)', style: AppTypography.labelMedium),
                ],
              ),
              Slider(
                value: _opacity,
                min: 0.1,
                max: 1.0,
                divisions: 9,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => _opacity = v),
              ),
              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Font Size (${_fontSize.toInt()} pt)', style: AppTypography.labelMedium),
                ],
              ),
              Slider(
                value: _fontSize,
                min: 18.0,
                max: 72.0,
                divisions: 9,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => _fontSize = v),
              ),
              const SizedBox(height: 24),

              FilledButton.icon(
                onPressed: _applyWatermark,
                icon: const Icon(Icons.branding_watermark_rounded),
                label: const Text('Apply Watermark to PDF'),
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
