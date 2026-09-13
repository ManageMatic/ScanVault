import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/document_card.dart';
import '../../../../shared/models/document.dart';

/// Recent documents list section on Home Dashboard.
class RecentDocumentsSection extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                    '${documents.length}',
                    style: AppTypography.labelSmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: onViewAll,
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
        if (documents.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceContainerLowest : AppColors.surfaceContainerLowest,
              borderRadius: AppDimens.roundedLg,
              border: Border.all(
                color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder,
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                'No recent documents yet.\nTap "Scan Doc" to capture your first document.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: documents.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final doc = documents[index];
              return DocumentCard(
                document: doc,
                onTap: () => onDocumentTap(doc),
                onFavoriteToggle: () => onFavoriteToggle(doc),
              );
            },
          ),
      ],
    );
  }
}
