import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_typography.dart';
import '../../domain/pdf_tools_controller.dart';

/// Reusable interactive tile for PDF utilities conforming to Google Stitch specs.
class ToolCard extends StatelessWidget {
  final PdfToolItem tool;
  final VoidCallback onTap;

  const ToolCard({
    super.key,
    required this.tool,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceContainerLowest : AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder,
              width: 1,
            ),
            boxShadow: AppDimens.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceContainerHigh
                      : tool.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  tool.icon,
                  size: 24,
                  color: isDark ? AppColors.primaryFixedDim : tool.accentColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tool.title,
                            style: AppTypography.titleSmall.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (tool.badgeText != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSurfaceContainerHigh
                                  : AppColors.primaryFixed,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              tool.badgeText!,
                              style: AppTypography.labelSmall.copyWith(
                                color: isDark ? AppColors.primaryFixedDim : AppColors.onPrimaryFixed,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      tool.subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
