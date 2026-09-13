import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';

/// Camera Viewfinder overlay with corner alignment brackets and document detection guide.
class CameraViewfinderOverlay extends StatelessWidget {
  final bool isAutoCapture;

  const CameraViewfinderOverlay({
    super.key,
    required this.isAutoCapture,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.maxWidth * 0.84;
        final boxHeight = boxWidth * 1.38; // 3:4 document aspect ratio

        return Stack(
          alignment: Alignment.center,
          children: [
            // Viewfinder Box
            Container(
              width: boxWidth,
              height: boxHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Stack(
                children: [
                  // Top Left Bracket
                  Positioned(
                    top: 0,
                    left: 0,
                    child: _buildCornerBracket(
                      top: true,
                      left: true,
                    ),
                  ),
                  // Top Right Bracket
                  Positioned(
                    top: 0,
                    right: 0,
                    child: _buildCornerBracket(
                      top: true,
                      left: false,
                    ),
                  ),
                  // Bottom Left Bracket
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: _buildCornerBracket(
                      top: false,
                      left: true,
                    ),
                  ),
                  // Bottom Right Bracket
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: _buildCornerBracket(
                      top: false,
                      left: false,
                    ),
                  ),
                ],
              ),
            ),

            // Center Guide Hint
            Positioned(
              bottom: (constraints.maxHeight - boxHeight) / 2 + 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryFixed,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isAutoCapture ? 'Auto: Align document within frame' : 'Manual: Tap shutter to capture',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCornerBracket({required bool top, required bool left}) {
    const size = 28.0;
    const thickness = 3.5;
    const color = AppColors.primaryFixed;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border(
          top: top ? const BorderSide(color: color, width: thickness) : BorderSide.none,
          bottom: !top ? const BorderSide(color: color, width: thickness) : BorderSide.none,
          left: left ? const BorderSide(color: color, width: thickness) : BorderSide.none,
          right: !left ? const BorderSide(color: color, width: thickness) : BorderSide.none,
        ),
      ),
    );
  }
}
