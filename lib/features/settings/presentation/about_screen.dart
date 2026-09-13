import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/scanvault_logo.dart';

/// About ScanVault screen detailing privacy philosophy and app specifications.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About ScanVault'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.margin, vertical: 24),
        child: Column(
          children: [
            const Center(child: ScanVaultLogo(size: 64)),
            const SizedBox(height: 16),
            Text(
              AppStrings.appName,
              style: AppTypography.headlineLarge.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.version,
              style: AppTypography.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // Privacy Manifesto Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceContainerLowest : AppColors.surfaceContainerLowest,
                borderRadius: AppDimens.roundedLg,
                border: Border.all(
                  color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder,
                  width: 1,
                ),
                boxShadow: AppDimens.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.privacy_tip_outlined, color: AppColors.primary, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'The Privacy Manifesto',
                        style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'ScanVault was engineered with an absolute commitment to privacy. Unlike other scanning apps that upload your sensitive documents to proprietary cloud servers:\n\n'
                    '• NO subscriptions or paywalls\n'
                    '• NO advertisements or trackers\n'
                    '• NO third-party telemetry\n'
                    '• 100% on-device local storage\n'
                    '• On-device OCR and PDF processing',
                    style: AppTypography.bodyMedium.copyWith(height: 1.45),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Technical Architecture details
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceContainerLowest : AppColors.surfaceContainerLowest,
                borderRadius: AppDimens.roundedLg,
                border: Border.all(
                  color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder,
                  width: 1,
                ),
                boxShadow: AppDimens.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Technology Stack',
                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Built with Flutter, Dart, Material 3, Clean Architecture, and Google Stitch design system.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
