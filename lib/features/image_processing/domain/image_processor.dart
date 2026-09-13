import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../../../shared/models/document.dart';
import 'perspective_transformer.dart';

enum ScanFilterMode {
  original,
  auto,
  documentClean,
  magicColor,
  grayscale,
  blackAndWhite,
}

class ImageEnhancementParams {
  final double brightness;      // -1.0 to 1.0 (default 0.0)
  final double contrast;        // 0.0 to 2.0 (default 1.0)
  final double shadowRemoval;   // 0.0 to 1.0 (default 0.0)
  final ScanFilterMode filterMode;
  final int rotationDegrees;    // 0, 90, 180, 270

  const ImageEnhancementParams({
    this.brightness = 0.0,
    this.contrast = 1.0,
    this.shadowRemoval = 0.0,
    this.filterMode = ScanFilterMode.documentClean,
    this.rotationDegrees = 0,
  });

  ImageEnhancementParams copyWith({
    double? brightness,
    double? contrast,
    double? shadowRemoval,
    ScanFilterMode? filterMode,
    int? rotationDegrees,
  }) {
    return ImageEnhancementParams(
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      shadowRemoval: shadowRemoval ?? this.shadowRemoval,
      filterMode: filterMode ?? this.filterMode,
      rotationDegrees: rotationDegrees ?? this.rotationDegrees,
    );
  }

  Map<String, dynamic> toJson() => {
    'brightness': brightness,
    'contrast': contrast,
    'shadowRemoval': shadowRemoval,
    'filterMode': filterMode.name,
    'rotationDegrees': rotationDegrees,
  };

  factory ImageEnhancementParams.fromJson(Map<String, dynamic> json) {
    return ImageEnhancementParams(
      brightness: (json['brightness'] as num?)?.toDouble() ?? 0.0,
      contrast: (json['contrast'] as num?)?.toDouble() ?? 1.0,
      shadowRemoval: (json['shadowRemoval'] as num?)?.toDouble() ?? 0.0,
      filterMode: ScanFilterMode.values.firstWhere(
        (e) => e.name == json['filterMode'],
        orElse: () => ScanFilterMode.documentClean,
      ),
      rotationDegrees: (json['rotationDegrees'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Comprehensive client-side image processing, enhancement, and perspective pipeline.
class ImageProcessor {
  /// Applies rotation, filters, shadow removal, brightness/contrast, and outputs JPEG bytes.
  static Uint8List processImageSync({
    required Uint8List rawBytes,
    required ImageEnhancementParams params,
    CompressionPreset preset = CompressionPreset.balanced,
    int? customMaxDimension,
  }) {
    img.Image? image = img.decodeImage(rawBytes);
    if (image == null) return rawBytes;

    // 1. Rotation Normalization
    if (params.rotationDegrees != 0) {
      image = img.copyRotate(image, angle: params.rotationDegrees);
    }

    // 2. Intelligent Downscaling for Target Resolution / Preview
    final maxDim = customMaxDimension ?? _getMaxDimensionForPreset(preset);
    if (image.width > maxDim || image.height > maxDim) {
      if (image.width >= image.height) {
        image = img.copyResize(image, width: maxDim);
      } else {
        image = img.copyResize(image, height: maxDim);
      }
    }

    // 3. Shadow Removal & Background Illumination Normalization
    if (params.shadowRemoval > 0.05) {
      image = _applyShadowRemoval(image, params.shadowRemoval);
    }

    // 4. Document Filter Presets
    switch (params.filterMode) {
      case ScanFilterMode.original:
        break;

      case ScanFilterMode.auto:
        // Automatic Dynamic Range Contrast Stretch + Paper Balancing
        image = _applyAutoDocumentEnhance(image);
        break;

      case ScanFilterMode.grayscale:
        image = img.grayscale(image);
        break;

      case ScanFilterMode.blackAndWhite:
        // Adaptive Document Binarization for crisp text strokes
        image = _applyAdaptiveBinarization(image);
        break;

      case ScanFilterMode.magicColor:
        // Boost vibrancy, color clarity, and crispness
        image = img.adjustColor(image, saturation: 1.30, brightness: 1.05);
        image = img.contrast(image, contrast: 118);
        break;

      case ScanFilterMode.documentClean:
        // Clear background gray, brighten white paper, sharpen text
        image = img.adjustColor(image, brightness: 1.08, gamma: 0.95);
        image = img.contrast(image, contrast: 122);
        break;
    }

    // 5. Brightness & Contrast Adjustments
    if (params.brightness != 0.0) {
      final brightOffset = (params.brightness * 100).toInt();
      image = img.adjustColor(image, brightness: 1.0 + (brightOffset / 100));
    }
    if (params.contrast != 1.0) {
      final contrastPercent = (params.contrast * 100).toInt();
      image = img.contrast(image, contrast: contrastPercent);
    }

    // 6. Output Compressed JPEG
    final quality = _getJpegQualityForPreset(preset);
    return Uint8List.fromList(img.encodeJpg(image, quality: quality));
  }

  /// Real 4-point quadrilateral perspective crop using bilinear homography.
  static Uint8List cropQuadrilateral({
    required Uint8List rawBytes,
    required math.Point<double> topLeft,
    required math.Point<double> topRight,
    required math.Point<double> bottomRight,
    required math.Point<double> bottomLeft,
    required double displayWidth,
    required double displayHeight,
    CompressionPreset preset = CompressionPreset.balanced,
  }) {
    return PerspectiveTransformer.warpQuadrilateral(
      rawBytes: rawBytes,
      topLeft: math.Point(topLeft.x / displayWidth, topLeft.y / displayHeight),
      topRight: math.Point(topRight.x / displayWidth, topRight.y / displayHeight),
      bottomRight: math.Point(bottomRight.x / displayWidth, bottomRight.y / displayHeight),
      bottomLeft: math.Point(bottomLeft.x / displayWidth, bottomLeft.y / displayHeight),
      isNormalized: true,
      preset: preset,
    );
  }

  /// Shadow removal using background illumination estimation.
  static img.Image _applyShadowRemoval(img.Image src, double strength) {
    // 1. Create downscaled grayscale copy to estimate background lighting field
    final downscaled = img.copyResize(src, width: 160);
    final blurred = img.gaussianBlur(downscaled, radius: 16);
    final bgMap = img.copyResize(blurred, width: src.width, height: src.height);

    final out = img.Image(width: src.width, height: src.height, numChannels: src.numChannels);
    final blend = strength.clamp(0.0, 1.0);

    for (var y = 0; y < src.height; y++) {
      for (var x = 0; x < src.width; x++) {
        final origPixel = src.getPixel(x, y);
        final bgLum = math.max(15, bgMap.getPixel(x, y).luminance.toInt());

        // Normalize pixel relative to estimated background light level
        final normR = (origPixel.r * 220 / bgLum).clamp(0, 255).round();
        final normG = (origPixel.g * 220 / bgLum).clamp(0, 255).round();
        final normB = (origPixel.b * 220 / bgLum).clamp(0, 255).round();

        final finalR = (origPixel.r * (1 - blend) + normR * blend).round();
        final finalG = (origPixel.g * (1 - blend) + normG * blend).round();
        final finalB = (origPixel.b * (1 - blend) + normB * blend).round();

        out.setPixel(x, y, src.getColor(finalR, finalG, finalB));
      }
    }
    return out;
  }

  /// Adaptive Document Binarization (Sauvola-style local thresholding).
  static img.Image _applyAdaptiveBinarization(img.Image src) {
    final gray = img.grayscale(src);
    final downscaled = img.copyResize(gray, width: 140);
    final blurredBg = img.gaussianBlur(downscaled, radius: 10);
    final localMean = img.copyResize(blurredBg, width: gray.width, height: gray.height);

    final out = img.Image(width: gray.width, height: gray.height);

    for (var y = 0; y < gray.height; y++) {
      for (var x = 0; x < gray.width; x++) {
        final p = gray.getPixel(x, y).r;
        final mean = localMean.getPixel(x, y).r;
        // Threshold with 10% bias below local mean
        final threshold = (mean * 0.90).clamp(30, 230);
        final val = p < threshold ? 0 : 255;
        out.setPixel(x, y, out.getColor(val, val, val));
      }
    }
    return out;
  }

  /// Automatic Dynamic Range Contrast Stretch + White Balance.
  static img.Image _applyAutoDocumentEnhance(img.Image src) {
    var minLum = 255;
    var maxLum = 0;

    // Scan luminance sample
    for (var y = 0; y < src.height; y += 4) {
      for (var x = 0; x < src.width; x += 4) {
        final lum = src.getPixel(x, y).luminance.toInt();
        if (lum < minLum) minLum = lum;
        if (lum > maxLum) maxLum = lum;
      }
    }

    final range = math.max(20, maxLum - minLum);
    final out = img.Image(width: src.width, height: src.height, numChannels: src.numChannels);

    for (var y = 0; y < src.height; y++) {
      for (var x = 0; x < src.width; x++) {
        final p = src.getPixel(x, y);
        final r = ((p.r - minLum) * 255 / range).clamp(0, 255).round();
        final g = ((p.g - minLum) * 255 / range).clamp(0, 255).round();
        final b = ((p.b - minLum) * 255 / range).clamp(0, 255).round();
        out.setPixel(x, y, src.getColor(r, g, b));
      }
    }

    return img.contrast(out, contrast: 115);
  }

  /// Generates a fast 320px thumbnail file.
  static Future<File> generateThumbnail({
    required Uint8List imageBytes,
    required String targetPath,
  }) async {
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      final f = File(targetPath);
      await f.writeAsBytes(imageBytes, flush: true);
      return f;
    }

    final thumb = img.copyResize(image, width: 320);
    final thumbBytes = img.encodeJpg(thumb, quality: 75);
    final f = File(targetPath);
    await f.writeAsBytes(thumbBytes, flush: true);
    return f;
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

  /// Generates a clean valid sample document JPEG bitmap.
  static Uint8List createSampleDocumentBitmap() {
    final image = img.Image(width: 800, height: 1100);
    img.fill(image, color: img.ColorRgb8(248, 250, 252));
    img.drawRect(image, x1: 40, y1: 40, x2: 760, y2: 1060, color: img.ColorRgb8(200, 215, 225));
    img.drawRect(image, x1: 80, y1: 120, x2: 450, y2: 150, color: img.ColorRgb8(100, 120, 140));
    img.drawRect(image, x1: 80, y1: 180, x2: 720, y2: 195, color: img.ColorRgb8(180, 195, 210));
    img.drawRect(image, x1: 80, y1: 215, x2: 680, y2: 230, color: img.ColorRgb8(180, 195, 210));
    img.drawRect(image, x1: 80, y1: 250, x2: 700, y2: 265, color: img.ColorRgb8(180, 195, 210));
    return Uint8List.fromList(img.encodeJpg(image, quality: 85));
  }
}
