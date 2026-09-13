import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimens.dart';
import '../constants/app_typography.dart';
import '../extensions/file_size_extensions.dart';

/// Stitch-styled on-device storage banner highlighting local privacy and document usage.
class StorageStatusCard extends StatelessWidget {
  final int documentCount;
  final int totalStorageBytes;
  final VoidCallback? onTap;

  const StorageStatusCard({
    super.key,
    required this.documentCount,
    required this.totalStorageBytes,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurfaceContainerLowest : AppColors.surfaceContainerLowest;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.cardBorder;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppDimens.roundedLg,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: AppDimens.roundedLg,
            border: Border.all(color: borderColor, width: 1),
            boxShadow: AppDimens.cardShadow,
          ),
          child: Row(
            children: [
              // Shield icon
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceContainerHigh : const Color(0xFFE6F5F3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              // Storage Information (Responsive & Non-overflowing)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'On-Device Storage',
                            style: AppTypography.titleSmall.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '100% Private',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${totalStorageBytes.formattedFileSize} used • $documentCount local document${documentCount == 1 ? '' : 's'}',
                      style: AppTypography.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Lock icon badge
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceContainerHigh : AppColors.surfaceContainerLow,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
