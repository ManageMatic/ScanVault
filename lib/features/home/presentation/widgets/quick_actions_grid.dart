import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_typography.dart';

enum QuickActionType { scanDoc, importPhotos, importPdf, extractOcr, createPdf }

/// Horizontal Quick Actions row matching Stitch specifications (w-28 h-32).
class QuickActionsGrid extends StatelessWidget {
  final ValueChanged<QuickActionType> onActionSelected;

  const QuickActionsGrid({
    super.key,
    required this.onActionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'QUICK ACTIONS',
              style: AppTypography.labelMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              'Auto-Crop Ready',
              style: AppTypography.labelSmall.copyWith(
                color: isDark ? AppColors.primaryFixedDim : AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              // 1. Primary Scan Card (Stitch: w-28 h-32 bg-primary text-on-primary p-3 rounded-xl)
              _buildActionCard(
                context: context,
                isPrimary: true,
                icon: Icons.document_scanner_rounded,
                category: 'Camera',
                title: 'Scan Doc',
                onTap: () => onActionSelected(QuickActionType.scanDoc),
              ),
              const SizedBox(width: 10),
              // 2. Import Images
              _buildActionCard(
                context: context,
                isPrimary: false,
                icon: Icons.photo_library_rounded,
                iconColor: AppColors.primary,
                category: 'Gallery',
                title: 'Import Photos',
                onTap: () => onActionSelected(QuickActionType.importPhotos),
              ),
              const SizedBox(width: 10),
              // 3. Import PDF
              _buildActionCard(
                context: context,
                isPrimary: false,
                icon: Icons.picture_as_pdf_rounded,
                iconColor: AppColors.secondary,
                category: 'Storage',
                title: 'Import PDF',
                onTap: () => onActionSelected(QuickActionType.importPdf),
              ),
              const SizedBox(width: 10),
              // 4. Extract OCR
              _buildActionCard(
                context: context,
                isPrimary: false,
                icon: Icons.text_fields_rounded,
                iconColor: AppColors.tertiary,
                category: 'AI Vision',
                title: 'Extract OCR',
                onTap: () => onActionSelected(QuickActionType.extractOcr),
              ),
              const SizedBox(width: 10),
              // 5. Create PDF
              _buildActionCard(
                context: context,
                isPrimary: false,
                icon: Icons.note_add_rounded,
                iconColor: Theme.of(context).colorScheme.onSurfaceVariant,
                category: 'Blank',
                title: 'Create PDF',
                onTap: () => onActionSelected(QuickActionType.createPdf),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required bool isPrimary,
    required IconData icon,
    Color? iconColor,
    required String category,
    required String title,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isPrimary
        ? (isDark ? AppColors.primary : AppColors.primary)
        : (isDark ? AppColors.darkSurfaceContainerLowest : AppColors.surfaceContainerLowest);

    final borderColor = isPrimary
        ? Colors.transparent
        : (isDark ? AppColors.darkCardBorder : AppColors.cardBorder);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppDimens.roundedLg,
        child: Container(
          width: 112,
          height: 128,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: AppDimens.roundedLg,
            border: Border.all(color: borderColor, width: 1),
            boxShadow: isPrimary ? AppDimens.fabShadow : AppDimens.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isPrimary
                      ? Colors.white.withValues(alpha: 0.18)
                      : (isDark ? AppColors.darkSurfaceContainerHigh : AppColors.surfaceContainerLow),
                  borderRadius: AppDimens.roundedDefault,
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: isPrimary ? Colors.white : (iconColor ?? AppColors.primary),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category,
                    style: AppTypography.labelSmall.copyWith(
                      color: isPrimary
                          ? AppColors.primaryFixed
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: AppTypography.titleSmall.copyWith(
                      color: isPrimary ? Colors.white : Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      height: 1.15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
