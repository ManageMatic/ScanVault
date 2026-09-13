import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/extensions/file_size_extensions.dart';
import '../../../core/widgets/document_card.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/loading_state_view.dart';
import '../../../shared/models/document.dart';
import '../../ocr/data/mlkit_ocr_service.dart';
import '../../ocr/presentation/ocr_text_viewer_sheet.dart';
import '../domain/documents_controller.dart';
import 'widgets/document_search_bar.dart';
import 'widgets/sort_filter_sheet.dart';

/// Full Documents Management Screen conforming to Stitch scanvault_documents_manager specifications.
class DocumentsScreen extends StatefulWidget {
  final DocumentsController controller;
  final VoidCallback onOpenScanner;

  const DocumentsScreen({
    super.key,
    required this.controller,
    required this.onOpenScanner,
  });

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  String _selectedTagFilter = 'all';

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onStateChanged);
    widget.controller.loadData();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  void _openSortFilterSheet() {
    SortFilterSheet.show(
      context: context,
      currentSort: widget.controller.sortOption,
      currentFilter: widget.controller.filterType,
      onApply: (sort, filter) {
        widget.controller.setSortOption(sort);
        widget.controller.setFilterType(filter);
      },
    );
  }

  void _handleMenuAction(Document doc, DocumentMenuAction action) {
    switch (action) {
      case DocumentMenuAction.ocr:
        if (doc.extractedOcrText != null && doc.extractedOcrText!.isNotEmpty) {
          OcrTextViewerSheet.show(
            context: context,
            title: doc.title,
            rawText: doc.extractedOcrText!,
          );
        } else {
          _runOcrOnDocument(doc);
        }
        break;
      case DocumentMenuAction.open:
      case DocumentMenuAction.share:
      case DocumentMenuAction.exportPdf:
      case DocumentMenuAction.rename:
      case DocumentMenuAction.moveToFolder:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${action.name.toUpperCase()}: ${doc.title}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
      case DocumentMenuAction.favorite:
        widget.controller.toggleFavorite(doc.id);
        break;
      case DocumentMenuAction.delete:
        widget.controller.deleteDocument(doc.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted "${doc.title}"'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
    }
  }

  void _runOcrOnDocument(Document doc) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Running on-device OCR recognition...'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
      ),
    );

    final path = doc.thumbnailPath ?? doc.filePath;
    if (path.isNotEmpty) {
      final file = File(path);
      if (await file.exists()) {
        final ocrService = MLKitOcrService();
        final result = await ocrService.recognizeTextFromImage(file);
        if (mounted) {
          OcrTextViewerSheet.show(
            context: context,
            title: doc.title,
            rawText: result.fullText.isNotEmpty ? result.fullText : 'No readable text recognized.',
            ocrResult: result,
          );
        }
        return;
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not read document file for OCR'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  List<Document> _filterByTag(List<Document> docs) {
    switch (_selectedTagFilter) {
      case 'pdf':
        return docs.where((d) => d.type == DocumentType.pdf).toList();
      case 'scan':
        return docs.where((d) => d.type == DocumentType.scan).toList();
      case 'favorite':
        return docs.where((d) => d.isFavorite).toList();
      case 'contracts':
        return docs.where((d) => d.tags.contains('Contract') || d.title.toLowerCase().contains('agreement')).toList();
      case 'receipts':
        return docs.where((d) => d.tags.contains('Paid') || d.title.toLowerCase().contains('invoice')).toList();
      default:
        return docs;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allDocs = widget.controller.documents;
    final docs = _filterByTag(allDocs);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Documents',
          style: AppTypography.headlineMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
      body: widget.controller.isLoading
          ? const LoadingStateView(message: 'Loading vault documents...')
          : RefreshIndicator(
              onRefresh: widget.controller.loadData,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.margin, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Search Bar
                    DocumentSearchBar(
                      onChanged: widget.controller.setSearchQuery,
                      onFilterTap: _openSortFilterSheet,
                      onToggleView: widget.controller.toggleViewMode,
                      isGridView: widget.controller.isGridView,
                    ),
                    const SizedBox(height: 12),

                    // Storage & Vault Privacy Status Banner (from Stitch HTML)
                    _buildStoragePrivacyBanner(isDark),
                    const SizedBox(height: 14),

                    // Filter Carousel (Pill Navigation)
                    _buildFilterPillsCarousel(isDark, allDocs),
                    const SizedBox(height: 18),

                    // Vault Folders Horizontal Carousel (from Stitch HTML)
                    _buildVaultFoldersCarousel(isDark),
                    const SizedBox(height: 22),

                    // Document List / Grid Header with Sort Trigger
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'All Documents',
                              style: AppTypography.titleMedium.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurfaceContainerHigh : AppColors.surfaceContainer,
                                borderRadius: AppDimens.roundedFull,
                              ),
                              child: Text(
                                '${docs.length}',
                                style: AppTypography.labelSmall.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: _openSortFilterSheet,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.sort_rounded, size: 16, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  'Last Modified',
                                  style: AppTypography.labelSmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down_rounded, size: 16, color: AppColors.outline),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Documents List / Grid
                    if (docs.isEmpty)
                      EmptyStateView(
                        icon: Icons.folder_open_rounded,
                        title: 'No Documents Found',
                        message: widget.controller.searchQuery.isNotEmpty
                            ? 'No files matched "${widget.controller.searchQuery}"'
                            : 'Capture or import documents into your offline vault.',
                        actionLabel: 'Scan Document',
                        onActionPressed: widget.onOpenScanner,
                      )
                    else if (widget.controller.isGridView)
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: docs.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.75,
                        ),
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          return DocumentCard(
                            document: doc,
                            isGrid: true,
                            onTap: () => _handleMenuAction(doc, DocumentMenuAction.open),
                            onFavoriteToggle: () => widget.controller.toggleFavorite(doc.id),
                            onMenuAction: (action) => _handleMenuAction(doc, action),
                          );
                        },
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: docs.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          return DocumentCard(
                            document: doc,
                            isGrid: false,
                            onTap: () => _handleMenuAction(doc, DocumentMenuAction.open),
                            onFavoriteToggle: () => widget.controller.toggleFavorite(doc.id),
                            onMenuAction: (action) => _handleMenuAction(doc, action),
                          );
                        },
                      ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStoragePrivacyBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceContainerLowest : AppColors.surfaceContainerLowest,
        borderRadius: AppDimens.roundedLg,
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder,
          width: 1,
        ),
        boxShadow: AppDimens.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceContainerHigh : const Color(0xFFCCFBF1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      '${widget.controller.totalDocumentCount} Local Documents',
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: AppDimens.roundedFull,
                      ),
                      child: Text(
                        '100% Offline',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.controller.totalStorageBytes.formattedFileSize} on device • 0 KB cloud telemetry',
                  style: AppTypography.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Vault',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPillsCarousel(bool isDark, List<Document> allDocs) {
    final pdfCount = allDocs.where((d) => d.type == DocumentType.pdf).length;
    final scanCount = allDocs.where((d) => d.type == DocumentType.scan).length;
    final favCount = allDocs.where((d) => d.isFavorite).length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildPill(
            key: 'all',
            label: 'All Docs (${allDocs.length})',
            icon: Icons.done_rounded,
          ),
          const SizedBox(width: 8),
          _buildPill(
            key: 'pdf',
            label: 'PDFs ($pdfCount)',
          ),
          const SizedBox(width: 8),
          _buildPill(
            key: 'scan',
            label: 'Scans ($scanCount)',
          ),
          const SizedBox(width: 8),
          _buildPill(
            key: 'favorite',
            label: 'Favorites ($favCount)',
            icon: Icons.star_rounded,
            iconColor: AppColors.secondary,
          ),
          const SizedBox(width: 8),
          _buildPill(
            key: 'contracts',
            label: 'Contracts',
          ),
          const SizedBox(width: 8),
          _buildPill(
            key: 'receipts',
            label: 'Receipts',
          ),
        ],
      ),
    );
  }

  Widget _buildPill({
    required String key,
    required String label,
    IconData? icon,
    Color? iconColor,
  }) {
    final isSelected = _selectedTagFilter == key;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isSelected
        ? (isDark ? AppColors.primaryFixedDim : AppColors.primary)
        : (isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow);

    final fgColor = isSelected
        ? (isDark ? AppColors.onPrimaryFixed : Colors.white)
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedTagFilter = key),
        borderRadius: AppDimens.roundedFull,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: AppDimens.roundedFull,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: isSelected ? fgColor : (iconColor ?? fgColor),
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: fgColor,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVaultFoldersCarousel(bool isDark) {
    final folders = widget.controller.folders;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.folder_open_rounded, color: AppColors.primary, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Vault Folders',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            Text(
              '${folders.length} Smart Categories',
              style: AppTypography.labelSmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: folders.map((folder) {
              final folderColor = folder.colorHex != null
                  ? Color(int.parse(folder.colorHex!.replaceFirst('#', '0xFF')))
                  : AppColors.primary;

              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceContainerLowest : AppColors.surfaceContainerLowest,
                  borderRadius: AppDimens.roundedLg,
                  border: Border.all(
                    color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder,
                    width: 1,
                  ),
                  boxShadow: AppDimens.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: folderColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.folder_rounded,
                            size: 20,
                            color: folderColor,
                          ),
                        ),
                        Icon(
                          Icons.more_vert_rounded,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      folder.name,
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${folder.documentCount} files',
                      style: AppTypography.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
