import 'dart:io';
import 'package:flutter/material.dart';
import 'package:scanvault/core/constants/app_colors.dart';
import 'package:scanvault/core/constants/app_typography.dart';
import 'package:scanvault/core/extensions/file_size_extensions.dart';
import 'package:scanvault/features/pdf_tools/data/repositories/local_file_source_repository.dart';
import 'package:scanvault/features/pdf_tools/domain/repositories/file_source_repository.dart';
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

class _PdfDocumentPickerSheetState extends State<PdfDocumentPickerSheet> with SingleTickerProviderStateMixin {
  final FileSourceRepository _fileSourceRepo = LocalFileSourceRepository();
  List<Document> _documents = [];
  List<Document> _filteredDocuments = [];
  final Set<String> _selectedDocIds = {};
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  bool _isDevicePicking = false;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filteredDocuments = _documents;
      } else {
        _filteredDocuments = _documents.where((d) => d.title.toLowerCase().contains(q)).toList();
      }
    });
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    try {
      const userId = 'local_user';
      final docs = await _fileSourceRepo.getScanVaultDocuments(userId);
      if (mounted) {
        setState(() {
          _documents = docs;
          _filteredDocuments = docs;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickFromDevice() async {
    setState(() => _isDevicePicking = true);
    try {
      List<File> picked;
      if (widget.allowImagePicker) {
        picked = await _fileSourceRepo.pickImagesFromDevice(allowMultiple: widget.allowMultiple);
      } else {
        picked = await _fileSourceRepo.pickPdfFromDevice(allowMultiple: widget.allowMultiple);
      }

      if (picked.isNotEmpty && mounted) {
        Navigator.of(context).pop(picked);
      }
    } finally {
      if (mounted) {
        setState(() => _isDevicePicking = false);
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
      height: MediaQuery.of(context).size.height * 0.82,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
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

          // Header
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
          const SizedBox(height: 14),

          // Choose from Device Storage Card (Prominent SAF button)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.15),
                  AppColors.primaryContainer.withValues(alpha: 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
            ),
            child: ListTile(
              onTap: _isDevicePicking ? null : _pickFromDevice,
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _isDevicePicking
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Icon(
                        widget.allowImagePicker ? Icons.add_photo_alternate_rounded : Icons.folder_open_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
              ),
              title: Text(
                widget.allowImagePicker ? 'Choose Images from Device' : 'Choose PDF from Device Storage',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              subtitle: Text(
                widget.allowImagePicker
                    ? 'Pick JPG, PNG, WEBP from Photos / Downloads'
                    : 'Pick PDF files from Downloads, Documents, or SD card',
                style: AppTypography.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            ),
          ),
          const SizedBox(height: 16),

          // Section Divider with Label
          Row(
            children: [
              Expanded(child: Divider(color: Theme.of(context).colorScheme.outlineVariant)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'OR SELECT FROM SCANVAULT',
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.outline,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Theme.of(context).colorScheme.outlineVariant)),
            ],
          ),
          const SizedBox(height: 12),

          // Search Box for Vault Docs
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search ScanVault documents...',
              hintStyle: AppTypography.bodySmall.copyWith(color: Theme.of(context).colorScheme.outline),
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Document List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _filteredDocuments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 44, color: Theme.of(context).colorScheme.outline),
                            const SizedBox(height: 10),
                            Text(
                              _searchController.text.isNotEmpty
                                  ? 'No matching documents'
                                  : 'No documents in vault yet',
                              style: AppTypography.titleMedium.copyWith(color: Theme.of(context).colorScheme.onSurface),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Use "Choose PDF from Device Storage" above to pick files directly from your phone.',
                              style: AppTypography.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _filteredDocuments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final doc = _filteredDocuments[index];
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
