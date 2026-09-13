import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:scanvault/core/constants/app_colors.dart';
import 'package:scanvault/core/constants/app_typography.dart';
import 'package:scanvault/features/pdf_creation/domain/pdf_models.dart';
import 'package:scanvault/features/pdf_tools/data/repositories/local_pdf_tools_repository.dart';
import 'package:scanvault/features/pdf_tools/domain/entities/pdf_processing_progress.dart';
import 'package:scanvault/features/pdf_tools/domain/repositories/pdf_tools_repository.dart';
import 'package:scanvault/features/pdf_tools/presentation/screens/pdf_tool_result_screen.dart';
import 'package:scanvault/features/pdf_tools/presentation/widgets/tool_progress_modal.dart';
import 'package:scanvault/shared/models/document.dart';

class ImagesToPdfScreen extends StatefulWidget {
  const ImagesToPdfScreen({super.key});

  @override
  State<ImagesToPdfScreen> createState() => _ImagesToPdfScreenState();
}

class _ImagesToPdfScreenState extends State<ImagesToPdfScreen> {
  final PdfToolsRepository _repository = LocalPdfToolsRepository();

  final List<File> _imageFiles = [];
  final TextEditingController _titleController = TextEditingController(text: 'Photo_Scan_Document');
  PdfPageSize _selectedPageSize = PdfPageSize.a4;
  final CompressionPreset _selectedPreset = CompressionPreset.balanced;

  final ValueNotifier<PdfProcessingProgress> _progressNotifier = ValueNotifier(
    const PdfProcessingProgress(progress: 0.0, statusMessage: 'Idle'),
  );

  @override
  void dispose() {
    _titleController.dispose();
    _progressNotifier.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() {
        _imageFiles.addAll(picked.map((x) => File(x.path)));
      });
    }
  }

  Future<void> _createPdf() async {
    if (_imageFiles.isEmpty) return;

    const userId = 'local_user';
    ToolProgressModal.show(context, _progressNotifier);

    final result = await _repository.imagesToPdf(
      userId: userId,
      imageFiles: _imageFiles,
      outputTitle: _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : 'Photo_Scan_Document',
      pageSize: _selectedPageSize,
      preset: _selectedPreset,
      onProgress: (prog) => _progressNotifier.value = prog,
    );

    if (mounted) {
      Navigator.of(context).pop(); // dismiss modal

      if (result.success) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PdfToolResultScreen(
              toolTitle: 'Images → PDF',
              result: result,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'PDF creation failed.'),
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
          'Images → PDF',
          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Document Title',
                prefixIcon: const Icon(Icons.title_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          Expanded(
            child: _imageFiles.isEmpty
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
                            child: const Icon(Icons.add_photo_alternate_rounded, size: 32, color: AppColors.primary),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No images selected',
                            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Import multiple photos or scans from your gallery to build a pristine PDF document.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: _pickImages,
                            icon: const Icon(Icons.photo_library_rounded),
                            label: const Text('Select Images'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<PdfPageSize>(
                                initialValue: _selectedPageSize,
                                decoration: InputDecoration(
                                  labelText: 'Page Size',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  isDense: true,
                                ),
                                items: const [
                                  DropdownMenuItem(value: PdfPageSize.a4, child: Text('A4 Standard')),
                                  DropdownMenuItem(value: PdfPageSize.letter, child: Text('US Letter')),
                                  DropdownMenuItem(value: PdfPageSize.auto, child: Text('Auto Fit Image')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedPageSize = val);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton.filledTonal(
                              onPressed: _pickImages,
                              icon: const Icon(Icons.add_photo_alternate_rounded),
                              tooltip: 'Add More Photos',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      Expanded(
                        child: ReorderableListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _imageFiles.length,
                          onReorder: (oldIndex, newIndex) {
                            setState(() {
                              if (newIndex > oldIndex) newIndex--;
                              final item = _imageFiles.removeAt(oldIndex);
                              _imageFiles.insert(newIndex, item);
                            });
                          },
                          itemBuilder: (context, index) {
                            final file = _imageFiles[index];

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
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.file(file, width: 44, height: 44, fit: BoxFit.cover),
                                ),
                                title: Text(
                                  'Page ${index + 1}',
                                  style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  file.path.split(Platform.pathSeparator).last,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                                      onPressed: () => setState(() => _imageFiles.removeAt(index)),
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

          if (_imageFiles.isNotEmpty)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: _createPdf,
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  label: Text('Generate PDF from ${_imageFiles.length} Image(s)'),
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
