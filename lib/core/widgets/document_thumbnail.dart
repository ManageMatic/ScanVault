import 'dart:io';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimens.dart';
import '../constants/app_typography.dart';
import '../../shared/models/document.dart';

/// Renders a responsive 3:4 document thumbnail matching the Stitch specifications.
class DocumentThumbnail extends StatelessWidget {
  final Document document;
  final double? width;
  final double? height;
  final bool showPageBadge;

  const DocumentThumbnail({
    super.key,
    required this.document,
    this.width,
    this.height,
    this.showPageBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerBg = isDark ? AppColors.darkSurfaceContainerHigh : AppColors.surfaceContainer;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: containerBg,
        borderRadius: AppDimens.roundedDefault,
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder,
          width: 0.8,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // If image thumbnail exists
          if (document.thumbnailPath != null && File(document.thumbnailPath!).existsSync())
            Image.file(
              File(document.thumbnailPath!),
              fit: BoxFit.cover,
            )
          else
            _buildFallbackPreview(context, isDark),

          // Stitch Top-left Verified Badge
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 11,
                color: Colors.white,
              ),
            ),
          ),

          // Stitch Bottom-right Page Count Badge
          if (showPageBadge)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black.withValues(alpha: 0.75) : AppColors.surfaceDim.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${document.pageCount}p',
                  style: AppTypography.labelSmall.copyWith(
                    color: isDark ? Colors.white : AppColors.onSurface,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFallbackPreview(BuildContext context, bool isDark) {
    IconData typeIcon = Icons.description_rounded;
    Color iconColor = AppColors.primary;

    if (document.type == DocumentType.pdf) {
      typeIcon = Icons.picture_as_pdf_rounded;
      iconColor = AppColors.pdfRed;
    } else if (document.type == DocumentType.image) {
      typeIcon = Icons.image_rounded;
      iconColor = AppColors.imageBlue;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppColors.darkSurfaceContainerHigh, AppColors.darkSurfaceContainer]
              : [const Color(0xFFFFFFFF), const Color(0xFFF1F3F5)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            typeIcon,
            size: 24,
            color: iconColor.withValues(alpha: 0.9),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2.5,
            width: 20,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 2.5),
          Container(
            height: 2.5,
            width: 14,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
