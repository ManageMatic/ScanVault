import 'package:flutter/material.dart';
import 'package:scanvault/core/constants/app_colors.dart';
import 'package:scanvault/core/constants/app_typography.dart';
import 'package:scanvault/features/pdf_tools/domain/entities/pdf_page_info.dart';

class PdfPageGridView extends StatelessWidget {
  final List<PdfPageInfo> pages;
  final Set<int> selectedPageIndices;
  final ValueChanged<int>? onPageTapped;
  final ValueChanged<int>? onRotatePage;
  final ValueChanged<int>? onDeletePage;
  final bool isSelectionMode;
  final bool allowRotation;
  final bool allowDelete;

  const PdfPageGridView({
    super.key,
    required this.pages,
    this.selectedPageIndices = const {},
    this.onPageTapped,
    this.onRotatePage,
    this.onDeletePage,
    this.isSelectionMode = false,
    this.allowRotation = false,
    this.allowDelete = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: pages.length,
      itemBuilder: (context, index) {
        final page = pages[index];
        final isSelected = selectedPageIndices.contains(page.pageIndex);

        return InkWell(
          onTap: () => onPageTapped?.call(page.pageIndex),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.darkCardBorder : AppColors.cardBorder),
                width: isSelected ? 2.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Thumbnail preview
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: page.thumbnailBytes != null
                        ? RotatedBox(
                            quarterTurns: (page.rotationDegrees / 90).round(),
                            child: Image.memory(
                              page.thumbnailBytes!,
                              fit: BoxFit.contain,
                            ),
                          )
                        : Container(
                            color: isDark
                                ? AppColors.darkSurfaceContainerHigh
                                : AppColors.surfaceContainerHigh,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.description_outlined,
                                    size: 36,
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Page ${page.pageNumber}',
                                    style: AppTypography.labelMedium.copyWith(
                                      color: Theme.of(context).colorScheme.outline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                ),

                // Top Page Number Badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Page ${page.pageNumber}',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                // Selection Checkmark Badge
                if (isSelectionMode)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.black.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : null,
                    ),
                  ),

                // Rotation pill if rotated
                if (page.rotationDegrees > 0 && !allowRotation)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.rotate_right_rounded, size: 12, color: AppColors.onPrimaryContainer),
                          const SizedBox(width: 2),
                          Text(
                            '${page.rotationDegrees}°',
                            style: AppTypography.labelSmall.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Bottom Action buttons (Rotate / Delete)
                if (allowRotation || allowDelete)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (allowRotation)
                          InkWell(
                            onTap: () => onRotatePage?.call(page.pageIndex),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.rotate_right_rounded, size: 18, color: Colors.white),
                            ),
                          ),
                        if (allowDelete)
                          InkWell(
                            onTap: () => onDeletePage?.call(page.pageIndex),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
