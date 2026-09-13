import 'dart:math' as math;
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../../../shared/models/document.dart';

/// High-precision 4-point perspective correction and warping engine.
class PerspectiveTransformer {
  /// Warps a 4-corner quadrilateral from source image into a rectangular document.
  /// Points should be in normalized coordinates (0.0 to 1.0) or denormalized image coordinates.
  static Uint8List warpQuadrilateral({
    required Uint8List rawBytes,
    required math.Point<double> topLeft,
    required math.Point<double> topRight,
    required math.Point<double> bottomRight,
    required math.Point<double> bottomLeft,
    bool isNormalized = true,
    CompressionPreset preset = CompressionPreset.balanced,
    int? customQuality,
  }) {
    final srcImg = img.decodeImage(rawBytes);
    if (srcImg == null) return rawBytes;

    final imgW = srcImg.width.toDouble();
    final imgH = srcImg.height.toDouble();

    // Denormalize points if in 0.0-1.0 space
    final tl = isNormalized ? math.Point(topLeft.x * imgW, topLeft.y * imgH) : topLeft;
    final tr = isNormalized ? math.Point(topRight.x * imgW, topRight.y * imgH) : topRight;
    final br = isNormalized ? math.Point(bottomRight.x * imgW, bottomRight.y * imgH) : bottomRight;
    final bl = isNormalized ? math.Point(bottomLeft.x * imgW, bottomLeft.y * imgH) : bottomLeft;

    // 1. Calculate natural target width and height based on perspective edge distances
    final topWidth = _distance(tl, tr);
    final bottomWidth = _distance(bl, br);
    final leftHeight = _distance(tl, bl);
    final rightHeight = _distance(tr, br);

    final rawTargetWidth = math.max(topWidth, bottomWidth);
    final rawTargetHeight = math.max(leftHeight, rightHeight);

    if (rawTargetWidth < 10 || rawTargetHeight < 10) return rawBytes;

    // 2. Bound output dimensions based on target compression preset (no artificial upscaling)
    final maxAllowedDim = _getMaxDimensionForPreset(preset).toDouble();
    final scale = math.min(1.0, maxAllowedDim / math.max(rawTargetWidth, rawTargetHeight));

    final targetW = (rawTargetWidth * scale).round().clamp(100, 4000);
    final targetH = (rawTargetHeight * scale).round().clamp(100, 4000);

    // 3. Perform Bilinear Inverse Quadrilateral Warping
    final outImg = img.Image(width: targetW, height: targetH, numChannels: srcImg.numChannels);

    for (var y = 0; y < targetH; y++) {
      final v = y / (targetH - 1.0);
      for (var x = 0; x < targetW; x++) {
        final u = x / (targetW - 1.0);

        // Bilinear interpolation between the 4 corners:
        // P(u, v) = (1-u)(1-v)TL + u(1-v)TR + u*v*BR + (1-u)v*BL
        final srcX = (1.0 - u) * (1.0 - v) * tl.x +
            u * (1.0 - v) * tr.x +
            u * v * br.x +
            (1.0 - u) * v * bl.x;

        final srcY = (1.0 - u) * (1.0 - v) * tl.y +
            u * (1.0 - v) * tr.y +
            u * v * br.y +
            (1.0 - u) * v * bl.y;

        final clampedX = srcX.clamp(0.0, (srcImg.width - 1).toDouble());
        final clampedY = srcY.clamp(0.0, (srcImg.height - 1).toDouble());

        final x0 = clampedX.floor();
        final y0 = clampedY.floor();
        final x1 = math.min(x0 + 1, srcImg.width - 1);
        final y1 = math.min(y0 + 1, srcImg.height - 1);

        final fx = clampedX - x0;
        final fy = clampedY - y0;

        final p00 = srcImg.getPixel(x0, y0);
        final p10 = srcImg.getPixel(x1, y0);
        final p01 = srcImg.getPixel(x0, y1);
        final p11 = srcImg.getPixel(x1, y1);

        final r = (p00.r * (1 - fx) * (1 - fy) +
                p10.r * fx * (1 - fy) +
                p01.r * (1 - fx) * fy +
                p11.r * fx * fy)
            .round()
            .clamp(0, 255);

        final g = (p00.g * (1 - fx) * (1 - fy) +
                p10.g * fx * (1 - fy) +
                p01.g * (1 - fx) * fy +
                p11.g * fx * fy)
            .round()
            .clamp(0, 255);

        final b = (p00.b * (1 - fx) * (1 - fy) +
                p10.b * fx * (1 - fy) +
                p01.b * (1 - fx) * fy +
                p11.b * fx * fy)
            .round()
            .clamp(0, 255);

        outImg.setPixelRgb(x, y, r, g, b);
      }
    }

    final quality = customQuality ?? _getJpegQualityForPreset(preset);
    return Uint8List.fromList(img.encodeJpg(outImg, quality: quality));
  }

  static double _distance(math.Point<double> p1, math.Point<double> p2) {
    final dx = p1.x - p2.x;
    final dy = p1.y - p2.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  static int _getMaxDimensionForPreset(CompressionPreset preset) {
    switch (preset) {
      case CompressionPreset.small:
        return 1200; // ~150 DPI
      case CompressionPreset.balanced:
        return 1600; // ~200 DPI
      case CompressionPreset.highQuality:
        return 2400; // ~300 DPI
    }
  }

  static int _getJpegQualityForPreset(CompressionPreset preset) {
    switch (preset) {
      case CompressionPreset.small:
        return 68;
      case CompressionPreset.balanced:
        return 82;
      case CompressionPreset.highQuality:
        return 92;
    }
  }
}
