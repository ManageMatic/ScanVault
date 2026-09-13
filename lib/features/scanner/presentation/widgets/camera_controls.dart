import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/models/scan_session.dart';

/// Bottom camera control bar including shutter button, gallery picker, and page review button.
class CameraControls extends StatelessWidget {
  final ScanMode currentMode;
  final ValueChanged<ScanMode> onModeChanged;
  final VoidCallback onCapture;
  final VoidCallback onGalleryImport;
  final VoidCallback onFinishBatch;
  final int pageCount;
  final bool isCapturing;

  const CameraControls({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
    required this.onCapture,
    required this.onGalleryImport,
    required this.onFinishBatch,
    required this.pageCount,
    this.isCapturing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mode Selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildModeItem(ScanMode.batch, 'Batch Scan'),
                _buildModeItem(ScanMode.single, 'Single Page'),
                _buildModeItem(ScanMode.idCard, 'ID Card'),
                _buildModeItem(ScanMode.book, 'Book 2-Page'),
                _buildModeItem(ScanMode.qrCode, 'QR / Barcode'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Shutter Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Gallery Import
                IconButton(
                  onPressed: onGalleryImport,
                  icon: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white30, width: 1),
                    ),
                    child: const Icon(
                      Icons.photo_library_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),

                // Main Shutter Button
                GestureDetector(
                  onTap: isCapturing ? null : onCapture,
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isCapturing ? AppColors.primaryFixed : AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: isCapturing
                          ? const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                    ),
                  ),
                ),

                // Finish / Page Counter
                GestureDetector(
                  onTap: pageCount > 0 ? onFinishBatch : null,
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: pageCount > 0 ? AppColors.primary : Colors.white.withValues(alpha: 0.15),
                      borderRadius: AppDimens.roundedFull,
                      border: Border.all(
                        color: pageCount > 0 ? Colors.transparent : Colors.white24,
                        width: 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      pageCount > 0 ? 'Done ($pageCount)' : '0 pages',
                      style: AppTypography.labelMedium.copyWith(
                        color: pageCount > 0 ? Colors.white : Colors.white54,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeItem(ScanMode mode, String label) {
    final isSelected = currentMode == mode;
    return GestureDetector(
      onTap: () => onModeChanged(mode),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: AppDimens.roundedFull,
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
