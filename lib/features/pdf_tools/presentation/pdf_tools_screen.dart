import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:scanvault/core/constants/app_colors.dart';
import 'package:scanvault/core/constants/app_dimens.dart';
import 'package:scanvault/core/constants/app_typography.dart';
import 'package:scanvault/features/ocr/data/mlkit_ocr_service.dart';
import 'package:scanvault/features/ocr/presentation/ocr_text_viewer_sheet.dart';
import 'package:scanvault/features/pdf_tools/data/repositories/local_pdf_tools_repository.dart';
import 'package:scanvault/features/pdf_tools/domain/entities/pdf_processing_progress.dart';
import 'package:scanvault/features/pdf_tools/domain/pdf_tools_controller.dart';
import 'package:scanvault/features/pdf_tools/presentation/screens/compress_pdf_screen.dart';
import 'package:scanvault/features/pdf_tools/presentation/screens/delete_pages_screen.dart';
import 'package:scanvault/features/pdf_tools/presentation/screens/extract_pages_screen.dart';
import 'package:scanvault/features/pdf_tools/presentation/screens/images_to_pdf_screen.dart';
import 'package:scanvault/features/pdf_tools/presentation/screens/merge_pdf_screen.dart';
import 'package:scanvault/features/pdf_tools/presentation/screens/pdf_metadata_screen.dart';
import 'package:scanvault/features/pdf_tools/presentation/screens/pdf_to_images_screen.dart';
import 'package:scanvault/features/pdf_tools/presentation/screens/pdf_tool_result_screen.dart';
import 'package:scanvault/features/pdf_tools/presentation/screens/protect_pdf_screen.dart';
import 'package:scanvault/features/pdf_tools/presentation/screens/rotate_pdf_screen.dart';
import 'package:scanvault/features/pdf_tools/presentation/screens/split_pdf_screen.dart';
import 'package:scanvault/features/pdf_tools/presentation/screens/watermark_pdf_screen.dart';
import 'package:scanvault/features/pdf_tools/presentation/widgets/pdf_document_picker_sheet.dart';
import 'package:scanvault/features/pdf_tools/presentation/widgets/tool_card.dart';
import 'package:scanvault/features/pdf_tools/presentation/widgets/tool_progress_modal.dart';

/// PDF Utilities suite screen conforming strictly to Stitch specifications.
class PdfToolsScreen extends StatefulWidget {
  const PdfToolsScreen({super.key});

  @override
  State<PdfToolsScreen> createState() => _PdfToolsScreenState();
}

class _PdfToolsScreenState extends State<PdfToolsScreen> {
  final PdfToolsController _controller = PdfToolsController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  void _onToolSelected(BuildContext context, PdfToolDefinition tool) {
    _controller.recordToolUsed(tool.id);

    switch (tool.type) {
      case PdfToolType.merge:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MergePdfScreen()));
        break;
      case PdfToolType.split:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SplitPdfScreen()));
        break;
      case PdfToolType.compress:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CompressPdfScreen()));
        break;
      case PdfToolType.rotateReorder:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RotatePdfScreen()));
        break;
      case PdfToolType.extractPages:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ExtractPagesScreen()));
        break;
      case PdfToolType.deletePages:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DeletePagesScreen()));
        break;
      case PdfToolType.imagesToPdf:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ImagesToPdfScreen()));
        break;
      case PdfToolType.pdfToImages:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PdfToImagesScreen()));
        break;
      case PdfToolType.protectPin:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProtectPdfScreen()));
        break;
      case PdfToolType.watermark:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WatermarkPdfScreen()));
        break;
      case PdfToolType.metadata:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PdfMetadataScreen()));
        break;
      case PdfToolType.ocrTextExtractor:
        _handleOcrTool(context);
        break;
      case PdfToolType.flatten:
        _handleFlattenTool(context);
        break;
      case PdfToolType.addSignature:
      case PdfToolType.annotateMarkup:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${tool.title} is coming in the next release.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
    }
  }

  Future<void> _handleOcrTool(BuildContext context) async {
    final picked = await PdfDocumentPickerSheet.show(
      context,
      title: 'Select Document for OCR',
      allowMultiple: false,
      allowImagePicker: true,
    );

    if (picked != null && picked.isNotEmpty && context.mounted) {
      final file = picked.first;
      final progressNotifier = ValueNotifier(
        const PdfProcessingProgress(progress: 0.0, statusMessage: 'Extracting text with on-device OCR...'),
      );
      ToolProgressModal.show(context, progressNotifier);

      try {
        final ocrService = MLKitOcrService();
        final ocrResult = await ocrService.recognizeTextFromImage(file);
        if (context.mounted) {
          Navigator.of(context).pop(); // dismiss modal
          OcrTextViewerSheet.show(
            context: context,
            title: p.basename(file.path),
            rawText: ocrResult.fullText.isNotEmpty ? ocrResult.fullText : 'No text recognized in this document.',
            ocrResult: ocrResult,
          );
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('OCR extraction failed: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  Future<void> _handleFlattenTool(BuildContext context) async {
    final picked = await PdfDocumentPickerSheet.show(
      context,
      title: 'Select PDF to Flatten',
      allowMultiple: false,
    );

    if (picked != null && picked.isNotEmpty && context.mounted) {
      final file = picked.first;
      const userId = 'local_user';
      final repository = LocalPdfToolsRepository();
      final progressNotifier = ValueNotifier(
        const PdfProcessingProgress(progress: 0.0, statusMessage: 'Flattening document...'),
      );

      ToolProgressModal.show(context, progressNotifier);

      final result = await repository.flattenPdf(
        userId: userId,
        sourcePdf: file,
        onProgress: (p) => progressNotifier.value = p,
      );

      if (context.mounted) {
        Navigator.of(context).pop(); // dismiss modal

        if (result.success) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PdfToolResultScreen(
                toolTitle: 'Flatten PDF',
                result: result,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.errorMessage ?? 'Flatten failed.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final groups = _controller.groupedCategories;
    final totalCount = _controller.filteredTools.length;
    final recents = _controller.recentUsages;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'SCANVAULT',
              style: AppTypography.labelSmall.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: AppColors.primary,
              ),
            ),
            Text(
              'Tools',
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.margin, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Pro Utilities Hero Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primaryContainer,
                    AppColors.tertiary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: AppColors.primaryFixed,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryContainer,
                                borderRadius: BorderRadius.circular(9999),
                              ),
                              child: Text(
                                '100% LOCAL',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.onSecondaryContainer,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Offline Studio',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.tertiaryFixed,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '13 Pro PDF Utilities',
                          style: AppTypography.titleMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Zero cloud uploads. All cryptographic operations, OCR analysis, and image rendering run locally.',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.onPrimaryContainer.withValues(alpha: 0.9),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Recently Used Row
            if (recents.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'RECENTLY USED',
                    style: AppTypography.labelSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  TextButton(
                    onPressed: _controller.clearRecentTools,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      'Clear',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    for (final usage in recents) ...[
                      Builder(
                        builder: (ctx) {
                          final tool = _controller.findToolById(usage.toolId);
                          if (tool == null) return const SizedBox.shrink();

                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildRecentChip(
                              ctx,
                              title: tool.title,
                              icon: tool.icon,
                              iconColor: tool.accentColor,
                              onTap: () => _onToolSelected(ctx, tool),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 3. Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: Theme.of(context).colorScheme.outline,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _controller.setSearchQuery,
                      style: AppTypography.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search 13 offline PDF tools...',
                        hintStyle: AppTypography.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceContainerHigh : AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$totalCount tools',
                      style: AppTypography.labelSmall.copyWith(
                        fontFamily: 'monospace',
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 4. Categorized Tool Groups
            if (groups.isEmpty) ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurfaceContainerHigh
                              : AppColors.surfaceContainerHigh,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.manage_search_rounded,
                          size: 32,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No utility found',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Try searching for keywords like 'merge', 'split', 'compress', or 'rotate'.",
                        style: AppTypography.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              for (final group in groups) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 5,
                          height: 16,
                          decoration: BoxDecoration(
                            color: group.accentColor,
                            borderRadius: BorderRadius.circular(9999),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          group.title,
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${group.tools.length} Tools',
                      style: AppTypography.labelSmall.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: group.tools.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final tool = group.tools[index];
                    return ToolCard(
                      tool: tool,
                      onTap: () => _onToolSelected(context, tool),
                    );
                  },
                ),
                const SizedBox(height: 22),
              ],
            ],

            // 5. Hardware-Accelerated Engine Footer Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceContainerHighest
                          : AppColors.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.memory_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '100% Offline PDF Engine',
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Local AES-256 encryption, lossless vector parsing & on-device OCR',
                          style: AppTypography.bodySmall.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentChip(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceContainerLowest : AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder,
              width: 1,
            ),
            boxShadow: AppDimens.cardShadow,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceContainerHigh
                      : AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.arrow_forward_rounded,
                size: 14,
                color: Theme.of(context).colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
