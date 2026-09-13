import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/document_card.dart';
import '../../../../shared/models/document.dart';

enum RecentFilterChipType { allDocs, favorites, invoices, contracts, receipts }

/// Recent documents list section on Home Dashboard conforming to Stitch layout.
class RecentDocumentsSection extends StatefulWidget {
  final List<Document> documents;
  final VoidCallback onViewAll;
  final ValueChanged<Document> onDocumentTap;
  final ValueChanged<Document> onFavoriteToggle;

  const RecentDocumentsSection({
    super.key,
    required this.documents,
    required this.onViewAll,
    required this.onDocumentTap,
    required this.onFavoriteToggle,
  });

  @override
  State<RecentDocumentsSection> createState() => _RecentDocumentsSectionState();
}

class _RecentDocumentsSectionState extends State<RecentDocumentsSection> {
  RecentFilterChipType _selectedFilter = RecentFilterChipType.allDocs;

  List<Document> get _filteredDocuments {
    switch (_selectedFilter) {
      case RecentFilterChipType.favorites:
        return widget.documents.where((d) => d.isFavorite).toList();
      case RecentFilterChipType.invoices:
        return widget.documents
            .where((d) => d.title.toLowerCase().contains('invoice') || d.tags.contains('Utility') || d.tags.contains('Finance'))
            .toList();
      case RecentFilterChipType.contracts:
        return widget.documents
            .where((d) => d.title.toLowerCase().contains('agreement') || d.title.toLowerCase().contains('lease') || d.tags.contains('Contract'))
            .toList();
      case RecentFilterChipType.receipts:
        return widget.documents
            .where((d) => d.title.toLowerCase().contains('receipt') || d.tags.contains('Paid'))
            .toList();
      case RecentFilterChipType.allDocs:
        return widget.documents;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final docs = _filteredDocuments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Recent Documents',
                  style: AppTypography.titleLarge.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceContainerHigh : AppColors.surfaceContainerHighest,
                    borderRadius: AppDimens.roundedFull,
                  ),
                  child: Text(
                    '${widget.documents.length}',
                    style: AppTypography.labelSmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: widget.onViewAll,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View All',
                    style: AppTypography.labelMedium.copyWith(
                      color: isDark ? AppColors.primaryFixedDim : AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: isDark ? AppColors.primaryFixedDim : AppColors.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Interactive Filter Chips from Stitch (h-8 px-3.5)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildFilterChip(
                type: RecentFilterChipType.allDocs,
                label: 'All Docs',
                icon: Icons.check_rounded,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                type: RecentFilterChipType.favorites,
                label: 'Favorites',
                icon: Icons.star_rounded,
                iconColor: AppColors.secondary,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                type: RecentFilterChipType.invoices,
                label: 'Invoices',
                icon: Icons.receipt_long_rounded,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                type: RecentFilterChipType.contracts,
                label: 'Contracts',
                icon: Icons.history_edu_rounded,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                type: RecentFilterChipType.receipts,
                label: 'Receipts',
                icon: Icons.point_of_sale_rounded,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (docs.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceContainerLowest : AppColors.surfaceContainerLowest,
              borderRadius: AppDimens.roundedLg,
              border: Border.all(
                color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder,
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.document_scanner_outlined,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.documents.isEmpty ? 'Your Vault is Ready' : 'No matching documents',
                  textAlign: TextAlign.center,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.documents.isEmpty
                      ? 'Tap "Scan Doc" above or import files to start adding secure documents to your on-device vault.'
                      : 'No documents match the selected filter category.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
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
                onTap: () => widget.onDocumentTap(doc),
                onFavoriteToggle: () => widget.onFavoriteToggle(doc),
              );
            },
          ),
      ],
    );
  }

  Widget _buildFilterChip({
    required RecentFilterChipType type,
    required String label,
    required IconData icon,
    Color? iconColor,
  }) {
    final isSelected = _selectedFilter == type;
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
        onTap: () => setState(() => _selectedFilter = type),
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
              Icon(
                icon,
                size: 15,
                color: isSelected ? fgColor : (iconColor ?? fgColor),
              ),
              const SizedBox(width: 5),
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
}
