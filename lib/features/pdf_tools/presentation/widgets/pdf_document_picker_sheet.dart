import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:scanvault/core/constants/app_colors.dart';
import 'package:scanvault/core/constants/app_typography.dart';
import 'package:scanvault/core/database/app_database.dart';
import 'package:scanvault/core/extensions/file_size_extensions.dart';
import 'package:scanvault/shared/models/document.dart';

class PdfDocumentPickerSheet extends StatefulWidget {
  final String title;
  final bool allowMultiple;
  final bool allowImagePicker;

  const PdfDocumentPickerSheet({
    super.key,
    this.title = 'Select Document',
    this.allowMultiple = false,
    this.allowImagePicker = false,
  });

  static Future<List<File>?> show(
    BuildContext context, {
    String title = 'Select Document',
    bool allowMultiple = false,
    bool allowImagePicker = false,
  }) {
    return showModalBottomSheet<List<File>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => PdfDocumentPickerSheet(
        title: title,
        allowMultiple: allowMultiple,
        allowImagePicker: allowImagePicker,
      ),
    );
  }

  @override
  State<PdfDocumentPickerSheet> createState() => _PdfDocumentPickerSheetState();
}

class _PdfDocumentPickerSheetState extends State<PdfDocumentPickerSheet> {
  final AppDatabase _database = AppDatabase();
  List<Document> _documents = [];
  final Set<String> _selectedDocIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    try {
      const userId = 'local_user';
      final docs = await _database.getDocumentsForUser(userId);
      if (mounted) {
        setState(() {
          _documents = docs;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    if (widget.allowMultiple) {
      final picked = await picker.pickMultiImage();
      if (picked.isNotEmpty && mounted) {
        final files = picked.map((x) => File(x.path)).toList();
        Navigator.of(context).pop(files);
      }
    } else {
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null && mounted) {
        Navigator.of(context).pop([File(picked.path)]);
      }
    }
  }

  void _onConfirmSelection() {
    final selectedFiles = <File>[];
    for (final id in _selectedDocIds) {
      final doc = _documents.firstWhere((d) => d.id == id);
      if (doc.filePath.isNotEmpty) {
        final file = File(doc.filePath);
        if (file.existsSync()) {
          selectedFiles.add(file);
        }
      }
    }
    Navigator.of(context).pop(selectedFiles);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(9999),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              if (widget.allowMultiple && _selectedDocIds.isNotEmpty)
                FilledButton.tonal(
                  onPressed: _onConfirmSelection,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    foregroundColor: AppColors.onPrimaryContainer,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text('Select (${_selectedDocIds.length})'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.allowImagePicker)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: OutlinedButton.icon(
                onPressed: _pickFromGallery,
                icon: const Icon(Icons.photo_library_rounded, size: 18),
                label: const Text('Pick from Gallery'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _documents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.folder_open_rounded, size: 48, color: Theme.of(context).colorScheme.outline),
                            const SizedBox(height: 12),
                            Text(
                              'No documents in vault yet',
                              style: AppTypography.titleMedium.copyWith(color: Theme.of(context).colorScheme.onSurface),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Scan or import documents first to use PDF tools.',
                              style: AppTypography.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _documents.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final doc = _documents[index];
                          final isSelected = _selectedDocIds.contains(doc.id);
                          final fileExists = doc.filePath.isNotEmpty && File(doc.filePath).existsSync();

                          return ListTile(
                            onTap: () {
                              if (!fileExists) return;
                              if (widget.allowMultiple) {
                                setState(() {
                                  if (isSelected) {
                                    _selectedDocIds.remove(doc.id);
                                  } else {
                                    _selectedDocIds.add(doc.id);
                                  }
                                });
                              } else {
                                Navigator.of(context).pop([File(doc.filePath)]);
                              }
                            },
                            tileColor: isSelected
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : (isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isSelected ? AppColors.primary : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary, size: 22),
                            ),
                            title: Text(
                              doc.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            subtitle: Text(
                              '${doc.pageCount} pages • ${doc.fileSize.formattedFileSize}',
                              style: AppTypography.bodySmall.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            trailing: widget.allowMultiple
                                ? Checkbox(
                                    value: isSelected,
                                    activeColor: AppColors.primary,
                                    onChanged: (v) {
                                      setState(() {
                                        if (v == true) {
                                          _selectedDocIds.add(doc.id);
                                        } else {
                                          _selectedDocIds.remove(doc.id);
                                        }
                                      });
                                    },
                                  )
                                : const Icon(Icons.chevron_right_rounded),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
