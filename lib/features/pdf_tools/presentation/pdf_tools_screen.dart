import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_typography.dart';
import '../domain/pdf_tools_controller.dart';
import 'widgets/tool_card.dart';

/// PDF Utilities suite screen conforming to Stitch specifications.
class PdfToolsScreen extends StatelessWidget {
  const PdfToolsScreen({super.key});

  void _onToolSelected(BuildContext context, PdfToolItem tool) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${tool.title} selected • Offline engine ready'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const tools = PdfToolsController.tools;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'PDF Tools Suite',
          style: AppTypography.headlineMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.margin, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
                borderRadius: AppDimens.roundedLg,
                border: Border.all(
                  color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.offline_bolt_rounded, color: AppColors.primary, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'All PDF operations execute 100% on-device without cloud uploads.',
                      style: AppTypography.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            Text(
              'ALL PDF UTILITIES',
              style: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tools.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final tool = tools[index];
                return ToolCard(
                  tool: tool,
                  onTap: () => _onToolSelected(context, tool),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
