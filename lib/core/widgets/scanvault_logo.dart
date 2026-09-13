import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

/// Reusable brand logo header for ScanVault.
class ScanVaultLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool isCompact;

  const ScanVaultLogo({
    super.key,
    this.size = 48,
    this.showText = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // App Icon Symbol with corner scan lines
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(size * 0.28),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: size * 0.25,
                offset: Offset(0, size * 0.1),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.document_scanner_rounded,
                size: size * 0.58,
                color: Colors.white,
              ),
              // Corner accent brackets
              Positioned(
                top: size * 0.12,
                left: size * 0.12,
                child: Container(
                  width: size * 0.18,
                  height: size * 0.18,
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppColors.primaryFixed, width: 1.5),
                      left: BorderSide(color: AppColors.primaryFixed, width: 1.5),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: size * 0.12,
                right: size * 0.12,
                child: Container(
                  width: size * 0.18,
                  height: size * 0.18,
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.primaryFixed, width: 1.5),
                      right: BorderSide(color: AppColors.primaryFixed, width: 1.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Scan',
                      style: (isCompact ? AppTypography.titleLarge : AppTypography.headlineMedium).copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(
                      text: 'Vault',
                      style: (isCompact ? AppTypography.titleLarge : AppTypography.headlineMedium).copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isCompact)
                Text(
                  'Offline • Private • Vault',
                  style: AppTypography.labelSmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
