import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/extensions/file_size_extensions.dart';
import '../../../core/widgets/document_card.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/loading_state_view.dart';
import '../../../shared/models/document.dart';
import '../../../shared/models/folder.dart';
import '../../ocr/data/mlkit_ocr_service.dart';
import '../../ocr/presentation/ocr_text_viewer_sheet.dart';
import '../../pdf_creation/domain/pdf_models.dart';
import '../../pdf_viewer/presentation/pdf_viewer_screen.dart';
import '../domain/documents_controller.dart';
import 'widgets/document_search_bar.dart';
import 'widgets/sort_filter_sheet.dart';

/// Full Documents Vault Screen conforming to Stitch scanvault_documents_manager specifications.
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
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onStateChanged);
    _scrollController.addListener(_onScroll);
    widget.controller.loadData();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onStateChanged);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      if (widget.controller.hasMore && !widget.controller.isLoadingMore) {
        widget.controller.loadMore();
      }
    }
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
      case DocumentMenuAction.open:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PdfViewerScreen(
              document: doc,
              onDeleted: () => widget.controller.deleteDocument(doc.id),
            ),
          ),
        );
        break;
      case DocumentMenuAction.share:
        _shareDocument(doc);
        break;
      case DocumentMenuAction.exportPdf:
        _exportDocument(doc);
        break;
      case DocumentMenuAction.rename:
        _showRenameDialog(doc);
        break;
      case DocumentMenuAction.moveToFolder:
        _showMoveToFolderSheet(doc);
        break;
      case DocumentMenuAction.favorite:
        widget.controller.toggleFavorite(doc.id);
        break;
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
      case DocumentMenuAction.delete:
        _showDeleteConfirmDialog(doc);
        break;
    }
  }

  void _shareDocument(Document doc) async {
    final file = File(doc.filePath);
    if (!await file.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF file not found on device'), behavior: SnackBarBehavior.floating),
        );
      }
      return;
    }
    final xFile = XFile(file.path, mimeType: 'application/pdf', name: sanitizePdfFilename(doc.title));
    await Share.shareXFiles([xFile], text: doc.title);
  }

  void _exportDocument(Document doc) async {
    final file = File(doc.filePath);
    if (!await file.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF file not found on device'), behavior: SnackBarBehavior.floating),
        );
      }
      return;
    }

    try {
      Directory? targetDir;
      if (Platform.isAndroid) {
        targetDir = Directory('/storage/emulated/0/Download');
        if (!await targetDir.exists()) {
          targetDir = Directory('/sdcard/Download');
        }
      }

      if (targetDir == null || !await targetDir.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not access Downloads. Use Share instead.'), behavior: SnackBarBehavior.floating),
          );
        }
        return;
      }

      final safeName = sanitizePdfFilename(doc.title);
      final destPath = '${targetDir.path}/$safeName';
      await file.copy(destPath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported to Downloads: $safeName'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), behavior: SnackBarBehavior.floating),
        );
      }
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

  void _showRenameDialog(Document doc) {
    final textController = TextEditingController(text: doc.title);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Document'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Document Name',
            hintText: 'Enter new title...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final newName = textController.text.trim();
              if (newName.isNotEmpty) {
                widget.controller.renameDocument(doc.id, newName);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Renamed to "$newName"'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showMoveToFolderSheet(Document doc) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final folders = widget.controller.folders;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Move to Folder',
                      style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Select destination for "${doc.title}":',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.outline),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.folder_off_outlined, color: AppColors.primary),
                  ),
                  title: const Text('Vault Root (No Folder)'),
                  trailing: doc.folderId == null ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
                  onTap: () {
                    widget.controller.moveDocumentToFolder(doc.id, null);
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Moved to Vault Root'), behavior: SnackBarBehavior.floating),
                    );
                  },
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: folders.length,
                    itemBuilder: (context, idx) {
                      final f = folders[idx];
                      final isCurrent = doc.folderId == f.id;
                      final fColor = f.colorHex != null
                          ? Color(int.parse(f.colorHex!.replaceFirst('#', '0xFF')))
                          : AppColors.primary;

                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: fColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.folder_rounded, color: fColor),
                        ),
                        title: Text(f.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${widget.controller.folderCounts[f.id] ?? 0} files'),
                        trailing: isCurrent ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
                        onTap: () {
                          widget.controller.moveDocumentToFolder(doc.id, f.id);
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Moved to "${f.name}"'), behavior: SnackBarBehavior.floating),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmDialog(Document doc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Document?'),
        content: Text(
          'Are you sure you want to delete "${doc.title}"?\n\nThis will permanently remove the document and its PDF file from your device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              widget.controller.deleteDocument(doc.id);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Permanently deleted "${doc.title}"'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  void _showCreateFolderDialog() {
    final textController = TextEditingController();
    String selectedColor = '#00685F';

    final colors = ['#00685F', '#0D9488', '#F59E0B', '#10B981', '#6366F1', '#EC4899', '#8B5CF6'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('New Folder'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: textController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Folder Name',
                  hintText: 'e.g. Invoices 2026',
                ),
              ),
              const SizedBox(height: 16),
              const Text('Color Tag', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: colors.map((hex) {
                  final color = Color(int.parse(hex.replaceFirst('#', '0xFF')));
                  final isSel = selectedColor == hex;
                  return GestureDetector(
                    onTap: () => setDlgState(() => selectedColor = hex),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSel ? Colors.white : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: isSel
                            ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 6)]
                            : null,
                      ),
                      child: isSel ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = textController.text.trim();
                if (name.isNotEmpty) {
                  widget.controller.createFolder(name, colorHex: selectedColor);
                  Navigator.of(ctx).pop();
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFolderActionsSheet(Folder folder) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.drive_file_rename_outline_rounded),
                title: const Text('Rename Folder'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showRenameFolderDialog(folder);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                title: const Text('Delete Folder', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showDeleteFolderConfirm(folder);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRenameFolderDialog(Folder folder) {
    final textController = TextEditingController(text: folder.name);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Folder'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Folder Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final newName = textController.text.trim();
              if (newName.isNotEmpty) {
                widget.controller.renameFolder(folder.id, newName);
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteFolderConfirm(Folder folder) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${folder.name}"?'),
        content: const Text(
          'Documents inside this folder will remain safely stored in your vault root.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              widget.controller.deleteFolder(folder.id);
              Navigator.of(ctx).pop();
            },
            child: const Text('Delete Folder'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final docs = widget.controller.documents;
    final activeFolder = widget.controller.selectedFolder;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Documents',
          style: AppTypography.headlineMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined),
            tooltip: 'New Folder',
            onPressed: _showCreateFolderDialog,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: widget.controller.isLoading
          ? const LoadingStateView(message: 'Loading vault documents...')
          : RefreshIndicator(
              onRefresh: widget.controller.loadData,
              color: AppColors.primary,
              child: SingleChildScrollView(
                controller: _scrollController,
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

                    // Active Folder Breadcrumb Filter (if selected)
                    if (activeFolder != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.folder_open_rounded, color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Folder: ${activeFolder.name}',
                                style: AppTypography.labelLarge.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.primary),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Clear Folder Filter',
                              onPressed: () => widget.controller.selectFolder(null),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Storage & Vault Privacy Status Banner
                    _buildStoragePrivacyBanner(isDark),
                    const SizedBox(height: 14),

                    // Filter Carousel (Pill Navigation)
                    _buildFilterPillsCarousel(isDark),
                    const SizedBox(height: 18),

                    // Vault Folders Carousel
                    _buildVaultFoldersCarousel(isDark),
                    const SizedBox(height: 22),

                    // Document List / Grid Header with Sort Trigger
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              activeFolder != null ? activeFolder.name : 'All Documents',
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
                                  _getSortLabel(widget.controller.sortOption),
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
                        icon: activeFolder != null ? Icons.folder_open_rounded : Icons.description_outlined,
                        title: activeFolder != null
                            ? 'Folder "${activeFolder.name}" is Empty'
                            : (widget.controller.searchQuery.isNotEmpty
                                ? 'No Documents Found'
                                : 'No Documents Yet'),
                        message: widget.controller.searchQuery.isNotEmpty
                            ? 'No files matched "${widget.controller.searchQuery}"'
                            : (activeFolder != null
                                ? 'Move documents into this folder from the document action menu.'
                                : 'Capture or import documents into your offline vault.'),
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

                    // Infinite Scroll Loading Indicator
                    if (widget.controller.isLoadingMore)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 18.0),
                        child: Center(
                          child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
                        ),
                      ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  String _getSortLabel(DocumentSortOption option) {
    switch (option) {
      case DocumentSortOption.newest:
        return 'Recently Modified';
      case DocumentSortOption.oldest:
        return 'Oldest First';
      case DocumentSortOption.nameAsc:
        return 'Name (A-Z)';
      case DocumentSortOption.nameDesc:
        return 'Name (Z-A)';
      case DocumentSortOption.sizeLargest:
        return 'Largest Size';
      case DocumentSortOption.sizeSmallest:
        return 'Smallest Size';
    }
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

  Widget _buildFilterPillsCarousel(bool isDark) {
    final filter = widget.controller.filterType;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildPill(
            type: DocumentFilterType.all,
            label: 'All Docs',
            icon: Icons.done_rounded,
            isSelected: filter == DocumentFilterType.all,
          ),
          const SizedBox(width: 8),
          _buildPill(
            type: DocumentFilterType.pdfOnly,
            label: 'PDFs',
            isSelected: filter == DocumentFilterType.pdfOnly,
          ),
          const SizedBox(width: 8),
          _buildPill(
            type: DocumentFilterType.scansOnly,
            label: 'Scans',
            isSelected: filter == DocumentFilterType.scansOnly,
          ),
          const SizedBox(width: 8),
          _buildPill(
            type: DocumentFilterType.favoritesOnly,
            label: 'Favorites',
            icon: Icons.star_rounded,
            iconColor: AppColors.secondary,
            isSelected: filter == DocumentFilterType.favoritesOnly,
          ),
          const SizedBox(width: 8),
          _buildPill(
            type: DocumentFilterType.ocrOnly,
            label: 'With OCR',
            icon: Icons.text_snippet_outlined,
            isSelected: filter == DocumentFilterType.ocrOnly,
          ),
        ],
      ),
    );
  }

  Widget _buildPill({
    required DocumentFilterType type,
    required String label,
    IconData? icon,
    Color? iconColor,
    required bool isSelected,
  }) {
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
        onTap: () => widget.controller.setFilterType(type),
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
    final selectedFolderId = widget.controller.selectedFolderId;

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
              final isSelected = selectedFolderId == folder.id;
              final folderColor = folder.colorHex != null
                  ? Color(int.parse(folder.colorHex!.replaceFirst('#', '0xFF')))
                  : AppColors.primary;
              final count = widget.controller.folderCounts[folder.id] ?? 0;

              return GestureDetector(
                onTap: () {
                  if (isSelected) {
                    widget.controller.selectFolder(null);
                  } else {
                    widget.controller.selectFolder(folder.id);
                  }
                },
                child: Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : (isDark ? AppColors.darkSurfaceContainerLowest : AppColors.surfaceContainerLowest),
                    borderRadius: AppDimens.roundedLg,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : (isDark ? AppColors.darkCardBorder : AppColors.cardBorder),
                      width: isSelected ? 2 : 1,
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
                          IconButton(
                            icon: const Icon(Icons.more_vert_rounded, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                            onPressed: () => _showFolderActionsSheet(folder),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        folder.name,
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: isSelected ? AppColors.primary : Theme.of(context).colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$count file${count == 1 ? '' : 's'}',
                        style: AppTypography.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
