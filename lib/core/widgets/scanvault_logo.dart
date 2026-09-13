import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

/// Pixel-perfect vector brand logo for ScanVault conforming to Stitch brand logo specs:
/// - Teal gradient rounded squircle
/// - White document sheet with clean document line bars
/// - Laser scan beam across document
/// - Vault lock / shield mark at bottom corner
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
        // Custom Brand Emblem
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _ScanVaultBrandLogoPainter(),
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 10),
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

class _ScanVaultBrandLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final scale = w / 120.0;

    // 1. Background gradient squircle
    final rect = Rect.fromLTWH(8 * scale, 8 * scale, 104 * scale, 104 * scale);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(28 * scale));
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);
    canvas.drawRRect(rrect, bgPaint);

    // 2. White Document sheet
    final docRect = Rect.fromLTWH(34 * scale, 28 * scale, 52 * scale, 64 * scale);
    final docRRect = RRect.fromRectAndRadius(docRect, Radius.circular(8 * scale));
    final docPaint = Paint()..color = Colors.white.withValues(alpha: 0.96);
    canvas.drawRRect(docRRect, docPaint);

    // 3. Document Lines
    final tealLinePaint = Paint()..color = const Color(0xFF0D9488).withValues(alpha: 0.85);
    final grayLinePaint = Paint()..color = const Color(0xFFCBD5E1);

    // Header teal line
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(42 * scale, 38 * scale, 26 * scale, 4 * scale),
        Radius.circular(2 * scale),
      ),
      tealLinePaint,
    );
    // Gray line 1
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(42 * scale, 48 * scale, 36 * scale, 4 * scale),
        Radius.circular(2 * scale),
      ),
      grayLinePaint,
    );
    // Gray line 2
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(42 * scale, 58 * scale, 30 * scale, 4 * scale),
        Radius.circular(2 * scale),
      ),
      grayLinePaint,
    );

    // 4. Laser Scan Beam
    final beamPaint = Paint()
      ..color = const Color(0xFF14B8A6)
      ..strokeWidth = 3 * scale
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(26 * scale, 62 * scale),
      Offset(94 * scale, 62 * scale),
      beamPaint,
    );

    // 5. Vault Lock Mark at bottom right corner
    final lockBgPaint = Paint()..color = const Color(0xFF0D9488);
    canvas.drawCircle(Offset(68 * scale, 74 * scale), 12 * scale, lockBgPaint);

    // Lock Shackle
    final shacklePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2 * scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final shacklePath = Path()
      ..moveTo(64 * scale, 73 * scale)
      ..lineTo(64 * scale, 71 * scale)
      ..arcToPoint(
        Offset(72 * scale, 71 * scale),
        radius: Radius.circular(4 * scale),
      )
      ..lineTo(72 * scale, 73 * scale);
    canvas.drawPath(shacklePath, shacklePaint);

    // Lock Body
    final lockBodyPaint = Paint()..color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(63 * scale, 73 * scale, 10 * scale, 8 * scale),
        Radius.circular(2 * scale),
      ),
      lockBodyPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
