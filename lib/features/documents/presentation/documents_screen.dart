import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/document_card.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/filter_chip_group.dart';
import '../../../core/widgets/loading_state_view.dart';
import '../../../shared/models/document.dart';
import '../domain/documents_controller.dart';
import 'widgets/document_search_bar.dart';
import 'widgets/folder_grid_view.dart';
import 'widgets/sort_filter_sheet.dart';

/// Full Documents Management Screen conforming to Stitch specifications.
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

class _DocumentsScreenState extends State<DocumentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    widget.controller.addListener(_onStateChanged);
    widget.controller.loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
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
      case DocumentMenuAction.open:
      case DocumentMenuAction.share:
      case DocumentMenuAction.exportPdf:
      case DocumentMenuAction.rename:
      case DocumentMenuAction.moveToFolder:
      case DocumentMenuAction.ocr:
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Documents',
          style: AppTypography.headlineMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: isDark ? AppColors.primaryFixedDim : AppColors.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
          indicatorColor: isDark ? AppColors.primaryFixedDim : AppColors.primary,
          indicatorWeight: 3,
          labelStyle: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
          unselectedLabelStyle: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w500),
          tabs: const [
            Tab(text: 'All Files'),
            Tab(text: 'Folders'),
            Tab(text: 'Favorites'),
          ],
        ),
      ),
      body: widget.controller.isLoading
          ? const LoadingStateView(message: 'Loading vault...')
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAllFilesTab(context),
                _buildFoldersTab(context),
                _buildFavoritesTab(context),
              ],
            ),
    );
  }

  Widget _buildAllFilesTab(BuildContext context) {
    final docs = widget.controller.documents;

    return RefreshIndicator(
      onRefresh: widget.controller.loadData,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.margin, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search & View Controls
            DocumentSearchBar(
              onChanged: widget.controller.setSearchQuery,
              onFilterTap: _openSortFilterSheet,
              onToggleView: widget.controller.toggleViewMode,
              isGridView: widget.controller.isGridView,
            ),
            const SizedBox(height: 12),

            // Quick Filter Chips
            FilterChipGroup<DocumentFilterType>(
              options: DocumentFilterType.values,
              selectedValue: widget.controller.filterType,
              labelBuilder: (type) {
                switch (type) {
                  case DocumentFilterType.all:
                    return 'All';
                  case DocumentFilterType.pdfOnly:
                    return 'PDFs';
                  case DocumentFilterType.scansOnly:
                    return 'Scans';
                  case DocumentFilterType.ocrOnly:
                    return 'OCR Ready';
                  case DocumentFilterType.favoritesOnly:
                    return 'Favorites';
                }
              },
              onSelected: widget.controller.setFilterType,
            ),
            const SizedBox(height: 16),

            // Documents List / Grid
            if (docs.isEmpty)
              EmptyStateView(
                icon: Icons.folder_open_rounded,
                title: 'No Documents Found',
                message: widget.controller.searchQuery.isNotEmpty
                    ? 'No files matched "${widget.controller.searchQuery}"'
                    : 'Scan or import your first document to store it securely in ScanVault.',
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
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFoldersTab(BuildContext context) {
    final folders = widget.controller.folders;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.margin, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'YOUR FOLDERS',
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Folder creation ready.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.create_new_folder_outlined, size: 18),
                label: const Text('New Folder'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (folders.isEmpty)
            const EmptyStateView(
              icon: Icons.create_new_folder_rounded,
              title: 'No Folders Yet',
              message: 'Organize related scans and contracts into custom offline folders.',
            )
          else
            FolderGridView(
              folders: folders,
              onFolderTap: (folder) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Folder: ${folder.name} (${folder.documentCount} items)'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFavoritesTab(BuildContext context) {
    final favorites = widget.controller.documents.where((d) => d.isFavorite).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.margin, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STARRED DOCUMENTS',
            style: AppTypography.labelMedium.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          if (favorites.isEmpty)
            const EmptyStateView(
              icon: Icons.star_border_rounded,
              title: 'No Favorites Starred',
              message: 'Star important receipts, contracts, and IDs for quick offline access.',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: favorites.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final doc = favorites[index];
                return DocumentCard(
                  document: doc,
                  onTap: () => _handleMenuAction(doc, DocumentMenuAction.open),
                  onFavoriteToggle: () => widget.controller.toggleFavorite(doc.id),
                  onMenuAction: (action) => _handleMenuAction(doc, action),
                );
              },
            ),
        ],
      ),
    );
  }
}
