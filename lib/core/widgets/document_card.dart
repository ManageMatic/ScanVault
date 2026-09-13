import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimens.dart';
import '../constants/app_typography.dart';
import '../extensions/datetime_extensions.dart';
import '../extensions/file_size_extensions.dart';
import '../../shared/models/document.dart';
import 'document_thumbnail.dart';

enum DocumentMenuAction { open, share, exportPdf, rename, moveToFolder, ocr, favorite, delete }

/// Reusable Document Card perfectly replicating the Stitch specification.
class DocumentCard extends StatelessWidget {
  final Document document;
  final VoidCallback onTap;
  final ValueChanged<DocumentMenuAction>? onMenuAction;
  final VoidCallback? onFavoriteToggle;
  final bool isGrid;

  const DocumentCard({
    super.key,
    required this.document,
    required this.onTap,
    this.onMenuAction,
    this.onFavoriteToggle,
    this.isGrid = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isGrid) {
      return _buildGridCard(context);
    }
    return _buildListCard(context);
  }

  Widget _buildListCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurfaceContainerLowest : AppColors.surfaceContainerLowest;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.cardBorder;
    final containerBg = isDark ? AppColors.darkSurfaceContainerHigh : AppColors.surfaceContainer;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppDimens.roundedLg,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: AppDimens.roundedLg,
            border: Border.all(color: borderColor, width: 1),
            boxShadow: AppDimens.cardShadow,
          ),
          child: Row(
            children: [
              // 3:4 Aspect Ratio Thumbnail with page badge & verified tag
              SizedBox(
                width: 60,
                height: 76,
                child: DocumentThumbnail(document: document),
              ),
              const SizedBox(width: 14),
              // Document Metadata
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            document.title,
                            style: AppTypography.titleSmall.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (document.isFavorite) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: AppColors.secondary,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${document.pageCount} pages • ${document.fileSize.formattedFileSize}',
                      style: AppTypography.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        // Relative time chip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: containerBg,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 12,
                                color: isDark ? AppColors.primaryFixedDim : AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                document.createdAt.relativeTime,
                                style: AppTypography.labelSmall.copyWith(
                                  color: isDark ? AppColors.primaryFixedDim : AppColors.primary,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Format / OCR chip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            document.hasOcr ? 'OCR' : (document.type == DocumentType.pdf ? 'PDF/A-1' : 'SCAN'),
                            style: AppTypography.labelSmall.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Trailing menu
              _buildPopupMenu(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurfaceContainerLowest : AppColors.surfaceContainerLowest;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.cardBorder;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppDimens.roundedLg,
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: AppDimens.roundedLg,
            border: Border.all(color: borderColor, width: 1),
            boxShadow: AppDimens.cardShadow,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top thumbnail
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DocumentThumbnail(document: document, showPageBadge: true),
                    if (document.isFavorite)
                      const Positioned(
                        top: 6,
                        right: 6,
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Metadata
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      style: AppTypography.titleSmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${document.pageCount}p • ${document.fileSize.formattedFileSize}',
                      style: AppTypography.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopupMenu(BuildContext context) {
    return PopupMenuButton<DocumentMenuAction>(
      icon: Icon(
        Icons.more_vert_rounded,
        size: 20,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      shape: const RoundedRectangleBorder(borderRadius: AppDimens.roundedMd),
      onSelected: (action) {
        if (action == DocumentMenuAction.favorite && onFavoriteToggle != null) {
          onFavoriteToggle!();
        } else if (onMenuAction != null) {
          onMenuAction!(action);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: DocumentMenuAction.open,
          child: _buildMenuItem(Icons.visibility_outlined, 'Open Document'),
        ),
        PopupMenuItem(
          value: DocumentMenuAction.share,
          child: _buildMenuItem(Icons.share_outlined, 'Share (Air-Gapped)'),
        ),
        PopupMenuItem(
          value: DocumentMenuAction.exportPdf,
          child: _buildMenuItem(Icons.picture_as_pdf_outlined, 'Export PDF'),
        ),
        PopupMenuItem(
          value: DocumentMenuAction.favorite,
          child: _buildMenuItem(
            document.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
            document.isFavorite ? 'Remove Favorite' : 'Mark Favorite',
          ),
        ),
        PopupMenuItem(
          value: DocumentMenuAction.rename,
          child: _buildMenuItem(Icons.edit_outlined, 'Rename Document'),
        ),
        PopupMenuItem(
          value: DocumentMenuAction.ocr,
          child: _buildMenuItem(Icons.text_fields_outlined, 'Extract OCR Text'),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: DocumentMenuAction.delete,
          child: _buildMenuItem(Icons.delete_outline_rounded, 'Delete', isDestructive: true),
        ),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String label, {bool isDestructive = false}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: isDestructive ? AppColors.error : null,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: isDestructive ? AppColors.error : null,
            fontWeight: isDestructive ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
