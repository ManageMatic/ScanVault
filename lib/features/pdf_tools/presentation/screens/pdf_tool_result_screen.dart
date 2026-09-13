import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:scanvault/core/constants/app_colors.dart';
import 'package:scanvault/core/constants/app_typography.dart';
import 'package:scanvault/core/extensions/file_size_extensions.dart';
import 'package:scanvault/features/pdf_tools/domain/entities/pdf_tool_result.dart';
import 'package:scanvault/features/pdf_viewer/presentation/pdf_viewer_screen.dart';

class PdfToolResultScreen extends StatelessWidget {
  final String toolTitle;
  final PdfToolResult result;

  const PdfToolResultScreen({
    super.key,
    required this.toolTitle,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final doc = result.document;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          toolTitle,
          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Success Icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.onPrimaryContainer,
                size: 40,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Operation Completed',
              style: AppTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              result.summaryMessage ?? 'Your PDF has been processed and saved safely.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),

            // Metrics Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  if (result.originalSizeBytes != null && result.outputSizeBytes != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetricColumn(
                          context,
                          label: 'Original Size',
                          value: result.originalSizeBytes!.formattedFileSize,
                        ),
                        Container(
                          height: 36,
                          width: 1,
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        _buildMetricColumn(
                          context,
                          label: 'New Size',
                          value: result.outputSizeBytes!.formattedFileSize,
                          valueColor: AppColors.primary,
                        ),
                      ],
                    ),
                    if (result.sizeSavedPercentage != null && result.sizeSavedPercentage! > 0) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Text(
                          '${result.sizeSavedPercentage!.toStringAsFixed(1)}% Smaller (${result.bytesSaved!.formattedFileSize} saved)',
                          style: AppTypography.labelMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                    const Divider(height: 24),
                  ],

                  if (doc != null) ...[
                    _buildInfoRow(context, 'Document Name', doc.title),
                    const SizedBox(height: 8),
                    _buildInfoRow(context, 'Total Pages', '${doc.pageCount} pages'),
                    const SizedBox(height: 8),
                    _buildInfoRow(context, 'Saved Path', doc.filePath),
                  ] else if (result.generatedFilePaths.isNotEmpty) ...[
                    _buildInfoRow(
                      context,
                      'Generated Files',
                      '${result.generatedFilePaths.length} files created',
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Action Buttons
            if (doc != null) ...[
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PdfViewerScreen(
                        document: doc,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.visibility_rounded),
                label: const Text('Open PDF in Viewer'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Share.shareXFiles([XFile(doc.filePath)], text: doc.title);
                },
                icon: const Icon(Icons.share_rounded),
                label: const Text('Share PDF'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
            ] else if (result.generatedFilePaths.isNotEmpty) ...[
              OutlinedButton.icon(
                onPressed: () {
                  final xFiles = result.generatedFilePaths.map((p) => XFile(p)).toList();
                  Share.shareXFiles(xFiles, text: toolTitle);
                },
                icon: const Icon(Icons.share_rounded),
                label: const Text('Share All Generated Files'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
            ],

            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Done',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricColumn(
    BuildContext context, {
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.w800,
            color: valueColor ?? Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: Theme.of(context).colorScheme.outline,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
