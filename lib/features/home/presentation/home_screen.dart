import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/scanvault_logo.dart';
import '../../../core/widgets/storage_status_card.dart';
import '../../../core/widgets/loading_state_view.dart';
import '../../../shared/models/document.dart';
import '../domain/home_controller.dart';
import 'widgets/quick_actions_grid.dart';
import 'widgets/privacy_banner.dart';
import 'widgets/recent_documents_section.dart';

import '../../auth/domain/auth_controller.dart';

/// Primary Home Dashboard Screen adhering to Google Stitch specifications.
class HomeScreen extends StatefulWidget {
  final HomeController controller;
  final AuthController? authController;
  final VoidCallback onNavigateToDocuments;
  final VoidCallback onOpenScanner;
  final VoidCallback onOpenTools;
  final VoidCallback? onOpenAccount;

  const HomeScreen({
    super.key,
    required this.controller,
    this.authController,
    required this.onNavigateToDocuments,
    required this.onOpenScanner,
    required this.onOpenTools,
    this.onOpenAccount,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onStateChanged);
    widget.controller.refresh();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  void _handleQuickAction(QuickActionType action) {
    switch (action) {
      case QuickActionType.scanDoc:
        widget.onOpenScanner();
        break;
      case QuickActionType.importPhotos:
      case QuickActionType.importPdf:
      case QuickActionType.createPdf:
      case QuickActionType.extractOcr:
        widget.onOpenTools();
        break;
    }
  }

  void _showDocumentDetails(Document document) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      document.title,
                      style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Pages: ${document.pageCount} • Size: ${(document.fileSize / (1024 * 1024)).toStringAsFixed(2)} MB',
                style: AppTypography.bodyMedium,
              ),
              if (document.extractedOcrText != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Extracted OCR Text:',
                  style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    document.extractedOcrText!,
                    style: AppTypography.bodySmall,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppDimens.margin,
        title: const ScanVaultLogo(size: 34, isCompact: true),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Search Documents',
            onPressed: widget.onNavigateToDocuments,
          ),
          IconButton(
            icon: widget.authController?.currentUser?.avatarUrl != null &&
                    widget.authController!.currentUser!.avatarUrl!.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      widget.authController!.currentUser!.avatarUrl!,
                      width: 28,
                      height: 28,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.account_circle_rounded,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                  )
                : Icon(
                    widget.authController?.isAuthenticated == true
                        ? Icons.account_circle_rounded
                        : Icons.account_circle_outlined,
                    color: widget.authController?.isAuthenticated == true
                        ? AppColors.primary
                        : null,
                    size: 28,
                  ),
            tooltip: widget.authController?.isAuthenticated == true
                ? 'Account Profile (${widget.authController?.currentUser?.email})'
                : 'Account & Sign In',
            onPressed: widget.onOpenAccount,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: widget.controller.isLoading
          ? const LoadingStateView(message: 'Loading vault documents...')
          : RefreshIndicator(
              onRefresh: widget.controller.refresh,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.margin, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Storage & Privacy Indicator Card
                    StorageStatusCard(
                      documentCount: widget.controller.totalDocumentCount,
                      totalStorageBytes: widget.controller.totalStorageBytes,
                      onTap: widget.onNavigateToDocuments,
                    ),
                    const SizedBox(height: 18),

                    // Quick Actions
                    QuickActionsGrid(
                      onActionSelected: _handleQuickAction,
                    ),
                    const SizedBox(height: 18),

                    // Zero Cloud Footprint Privacy Tip Card
                    const PrivacyBanner(),
                    const SizedBox(height: 22),

                    // Recent Documents Section
                    RecentDocumentsSection(
                      documents: widget.controller.recentDocuments,
                      onViewAll: widget.onNavigateToDocuments,
                      onDocumentTap: _showDocumentDetails,
                      onFavoriteToggle: (doc) => widget.controller.toggleFavorite(doc.id),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}
