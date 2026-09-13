import 'dart:io';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimens.dart';
import '../constants/app_typography.dart';
import '../../shared/models/document.dart';

/// Renders a responsive 3:4 document thumbnail with page count badge and fallback document art.
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
    final containerBg = isDark ? AppColors.darkSurfaceContainerHigh : AppColors.surfaceContainerLow;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: containerBg,
        borderRadius: AppDimens.roundedMd,
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

          // Page Count Badge
          if (showPageBadge)
            Positioned(
              bottom: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${document.pageCount}p',
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white,
                    fontSize: 10,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppColors.darkSurfaceContainerHigh, AppColors.darkSurfaceContainer]
              : [const Color(0xFFFFFFFF), const Color(0xFFF1F5F9)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            typeIcon,
            size: 28,
            color: iconColor.withValues(alpha: 0.85),
          ),
          const SizedBox(height: 6),
          Container(
            height: 3,
            width: 24,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 3),
          Container(
            height: 3,
            width: 16,
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
