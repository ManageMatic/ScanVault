import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimens.dart';
import '../constants/app_typography.dart';

/// Extended or Icon-only Floating Action Button for Scan triggers.
class ScanFAB extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isExtended;
  final String label;

  const ScanFAB({
    super.key,
    required this.onPressed,
    this.isExtended = true,
    this.label = 'Scan Doc',
  });

  @override
  Widget build(BuildContext context) {
    if (!isExtended) {
      return FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: const Icon(Icons.document_scanner_rounded, size: 26),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        boxShadow: AppDimens.fabShadow,
        borderRadius: AppDimens.roundedFull,
      ),
      child: FloatingActionButton.extended(
        onPressed: onPressed,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        highlightElevation: 2,
        shape: const RoundedRectangleBorder(borderRadius: AppDimens.roundedFull),
        icon: const Icon(Icons.document_scanner_rounded, size: 22),
        label: Text(
          label,
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.onPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
