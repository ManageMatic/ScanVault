import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../../../shared/models/document.dart';

enum ScanFilterMode {
  original,
  documentClean,
  magicColor,
  grayscale,
  blackAndWhite,
}

class ImageEnhancementParams {
  final double brightness; // -1.0 to 1.0 (default 0.0)
  final double contrast;   // 0.0 to 2.0 (default 1.0)
  final ScanFilterMode filterMode;
  final int rotationDegrees; // 0, 90, 180, 270

  const ImageEnhancementParams({
    this.brightness = 0.0,
    this.contrast = 1.0,
    this.filterMode = ScanFilterMode.documentClean,
    this.rotationDegrees = 0,
  });

  ImageEnhancementParams copyWith({
    double? brightness,
    double? contrast,
    ScanFilterMode? filterMode,
    int? rotationDegrees,
  }) {
    return ImageEnhancementParams(
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      filterMode: filterMode ?? this.filterMode,
      rotationDegrees: rotationDegrees ?? this.rotationDegrees,
    );
  }
}

/// High-performance client-side image processing and compression pipeline.
class ImageProcessor {
  /// Applies rotation, filters, brightness/contrast, and exports JPEG bytes.
  static Uint8List processImageSync({
    required Uint8List rawBytes,
    required ImageEnhancementParams params,
    CompressionPreset preset = CompressionPreset.balanced,
  }) {
    img.Image? image = img.decodeImage(rawBytes);
    if (image == null) return rawBytes;

    // 1. Rotation
    if (params.rotationDegrees != 0) {
      image = img.copyRotate(image, angle: params.rotationDegrees);
    }

    // 2. Intelligent Downscaling for Small File Size
    final maxDim = _getMaxDimensionForPreset(preset);
    if (image.width > maxDim || image.height > maxDim) {
      if (image.width >= image.height) {
        image = img.copyResize(image, width: maxDim);
      } else {
        image = img.copyResize(image, height: maxDim);
      }
    }

    // 3. Filters
    switch (params.filterMode) {
      case ScanFilterMode.original:
        break;
      case ScanFilterMode.grayscale:
        image = img.grayscale(image);
        break;
      case ScanFilterMode.blackAndWhite:
        image = img.grayscale(image);
        // Adaptive document binarization / high contrast threshold
        image = img.contrast(image, contrast: 150);
        break;
      case ScanFilterMode.magicColor:
        // Boost vibrancy and local contrast
        image = img.adjustColor(image, saturation: 1.25, brightness: 1.05);
        image = img.contrast(image, contrast: 115);
        break;
      case ScanFilterMode.documentClean:
        // Clear background gray, whiten paper, sharpen text
        image = img.adjustColor(image, brightness: 1.08, gamma: 0.95);
        image = img.contrast(image, contrast: 120);
        break;
    }

    // 4. Custom Sliders Brightness & Contrast
    if (params.brightness != 0.0) {
      final brightOffset = (params.brightness * 100).toInt();
      image = img.adjustColor(image, brightness: 1.0 + (brightOffset / 100));
    }
    if (params.contrast != 1.0) {
      final contrastPercent = (params.contrast * 100).toInt();
      image = img.contrast(image, contrast: contrastPercent);
    }

    // 5. Compressed JPEG Output
    final quality = _getJpegQualityForPreset(preset);
    return Uint8List.fromList(img.encodeJpg(image, quality: quality));
  }

  /// Perspective Warp / 4-Corner Quadrilateral Crop
  static Uint8List cropQuadrilateral({
    required Uint8List rawBytes,
    required math.Point<double> topLeft,
    required math.Point<double> topRight,
    required math.Point<double> bottomRight,
    required math.Point<double> bottomLeft,
    required double displayWidth,
    required double displayHeight,
  }) {
    final original = img.decodeImage(rawBytes);
    if (original == null) return rawBytes;

    final scaleX = original.width / displayWidth;
    final scaleY = original.height / displayHeight;

    final minX = [topLeft.x, bottomLeft.x].reduce(math.min) * scaleX;
    final maxX = [topRight.x, bottomRight.x].reduce(math.max) * scaleX;
    final minY = [topLeft.y, topRight.y].reduce(math.min) * scaleY;
    final maxY = [bottomLeft.y, bottomRight.y].reduce(math.max) * scaleY;

    final x = math.max(0, minX.toInt());
    final y = math.max(0, minY.toInt());
    final w = math.min(original.width - x, (maxX - minX).toInt());
    final h = math.min(original.height - y, (maxY - minY).toInt());

    if (w <= 0 || h <= 0) return rawBytes;

    final cropped = img.copyCrop(original, x: x, y: y, width: w, height: h);
    return Uint8List.fromList(img.encodeJpg(cropped, quality: 85));
  }

  /// Generates a fast 300px thumbnail file.
  static Future<File> generateThumbnail({
    required Uint8List imageBytes,
    required String targetPath,
  }) async {
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      final f = File(targetPath);
      await f.writeAsBytes(imageBytes);
      return f;
    }

    final thumb = img.copyResize(image, width: 320);
    final thumbBytes = img.encodeJpg(thumb, quality: 75);
    final f = File(targetPath);
    await f.writeAsBytes(thumbBytes);
    return f;
  }

  static int _getMaxDimensionForPreset(CompressionPreset preset) {
    switch (preset) {
      case CompressionPreset.small:
        return 1200; // ~150 DPI
      case CompressionPreset.highQuality:
        return 2400; // ~300 DPI
      case CompressionPreset.balanced:
        return 1600; // ~200 DPI
    }
  }

  static int _getJpegQualityForPreset(CompressionPreset preset) {
    switch (preset) {
      case CompressionPreset.small:
        return 65;
      case CompressionPreset.highQuality:
        return 90;
      case CompressionPreset.balanced:
        return 80;
    }
  }
}
