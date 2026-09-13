import 'package:flutter/material.dart';

/// Pixel-perfect vector scanner icon matching Stitch & user reference:
/// 4 outer corner brackets framing an inner document with horizontal text lines.
class StitchScannerIcon extends StatelessWidget {
  final double size;
  final Color color;

  const StitchScannerIcon({
    super.key,
    this.size = 28,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _StitchScannerPainter(color: color),
      ),
    );
  }
}

class _StitchScannerPainter extends CustomPainter {
  final Color color;

  _StitchScannerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.085;
    final cornerLen = size.width * 0.22;
    final pad = size.width * 0.06;

    final bracketPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Top-Left corner bracket
    final tlPath = Path()
      ..moveTo(pad, pad + cornerLen)
      ..lineTo(pad, pad)
      ..lineTo(pad + cornerLen, pad);
    canvas.drawPath(tlPath, bracketPaint);

    // Top-Right corner bracket
    final trPath = Path()
      ..moveTo(w - pad - cornerLen, pad)
      ..lineTo(w - pad, pad)
      ..lineTo(w - pad, pad + cornerLen);
    canvas.drawPath(trPath, bracketPaint);

    // Bottom-Left corner bracket
    final blPath = Path()
      ..moveTo(pad, h - pad - cornerLen)
      ..lineTo(pad, h - pad)
      ..lineTo(pad + cornerLen, h - pad);
    canvas.drawPath(blPath, bracketPaint);

    // Bottom-Right corner bracket
    final brPath = Path()
      ..moveTo(w - pad - cornerLen, h - pad)
      ..lineTo(w - pad, h - pad)
      ..lineTo(w - pad, h - pad - cornerLen);
    canvas.drawPath(brPath, bracketPaint);

    // Inner Document Box Outline
    final docRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w / 2, h / 2),
        width: size.width * 0.44,
        height: size.height * 0.48,
      ),
      Radius.circular(size.width * 0.05),
    );
    final docOutlinePaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth * 0.8
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(docRect, docOutlinePaint);

    // 3 Horizontal lines inside document
    final lineW = size.width * 0.24;
    final lineH = size.height * 0.04;
    final lineR = Radius.circular(lineH / 2);
    final centerY = h / 2;
    final spacing = size.height * 0.09;

    // Top line
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w / 2, centerY - spacing), width: lineW, height: lineH),
        lineR,
      ),
      fillPaint,
    );

    // Center line
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w / 2, centerY), width: lineW, height: lineH),
        lineR,
      ),
      fillPaint,
    );

    // Bottom line
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w / 2, centerY + spacing), width: lineW * 0.7, height: lineH),
        lineR,
      ),
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _StitchScannerPainter oldDelegate) => oldDelegate.color != color;
}
