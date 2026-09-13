import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_typography.dart';
import '../domain/pdf_tools_controller.dart';
import 'widgets/tool_card.dart';

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

  void _onToolSelected(BuildContext context, PdfToolItem tool) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${tool.title} selected • Sandbox ready'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final groups = _controller.groupedCategories;
    final totalCount = _controller.filteredTools.length;

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
            // 1. Offline Engine Status Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(
                  color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Offline Engine',
                        style: AppTypography.labelSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '•',
                        style: TextStyle(color: Theme.of(context).colorScheme.outlineVariant, fontSize: 10),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '100% On-Device',
                        style: AppTypography.labelSmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Zero Telemetry',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 2. Pro Utilities Hero Banner
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
                                'LOCAL ONLY',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.onSecondaryContainer,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Native Sandbox',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.tertiaryFixed,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '13 Pro Utilities • Free Forever',
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

            // 3. Recently Used Row
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
                  onPressed: () {},
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
                  _buildRecentChip(
                    context,
                    title: 'Merge (Yesterday)',
                    icon: Icons.call_merge_rounded,
                    iconColor: AppColors.primary,
                    onTap: () {},
                  ),
                  const SizedBox(width: 8),
                  _buildRecentChip(
                    context,
                    title: 'Compress (~68% saved)',
                    icon: Icons.zoom_in_map_rounded,
                    iconColor: AppColors.secondary,
                    onTap: () {},
                  ),
                  const SizedBox(width: 8),
                  _buildRecentChip(
                    context,
                    title: 'Quick Sign',
                    icon: Icons.draw_rounded,
                    iconColor: AppColors.tertiary,
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4. Search Bar
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

            // 5. Categorized Tool Groups
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
                        "Try searching for synonyms like 'convert', 'secure', 'sign', or 'extract'.",
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

            // 6. Bottom WebAssembly SIMD Acceleration Info Card
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
                          'WebAssembly PDF Engine',
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Hardware-accelerated processing via SIMD v2.4',
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
