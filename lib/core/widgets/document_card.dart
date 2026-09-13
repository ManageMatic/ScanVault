import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimens.dart';
import '../constants/app_typography.dart';
import '../extensions/datetime_extensions.dart';
import '../extensions/file_size_extensions.dart';
import '../../shared/models/document.dart';
import 'document_thumbnail.dart';

enum DocumentMenuAction { open, share, exportPdf, rename, moveToFolder, ocr, favorite, delete }

/// Reusable Document Card supporting Grid and List displays as specified in Stitch designs.
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppDimens.roundedLg,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: AppDimens.roundedLg,
            border: Border.all(color: borderColor, width: 1),
            boxShadow: AppDimens.cardShadow,
          ),
          child: Row(
            children: [
              // 3:4 Thumbnail
              SizedBox(
                width: 54,
                height: 72,
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
                            style: AppTypography.titleMedium.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (document.isFavorite)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.star_rounded,
                              size: 18,
                              color: Color(0xFFF59E0B),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${document.createdAt.relativeTime} • ${document.fileSize.formattedFileSize}',
                      style: AppTypography.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (document.hasOcr)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'OCR',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        if (document.type == DocumentType.pdf)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.pdfRed.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'PDF',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.pdfRed,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
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
                            color: Color(0xFFF59E0B),
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
                      '${document.createdAt.relativeTime} • ${document.fileSize.formattedFileSize}',
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
          child: _buildMenuItem(Icons.visibility_outlined, 'Open'),
        ),
        PopupMenuItem(
          value: DocumentMenuAction.share,
          child: _buildMenuItem(Icons.share_outlined, 'Share Document'),
        ),
        PopupMenuItem(
          value: DocumentMenuAction.exportPdf,
          child: _buildMenuItem(Icons.picture_as_pdf_outlined, 'Export as PDF'),
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
          child: _buildMenuItem(Icons.edit_outlined, 'Rename'),
        ),
        PopupMenuItem(
          value: DocumentMenuAction.ocr,
          child: _buildMenuItem(Icons.text_fields_outlined, 'Extract Text (OCR)'),
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
