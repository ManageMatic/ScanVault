import 'dart:math' as math;
import 'dart:typed_data';
import '../../image_processing/domain/image_processor.dart';

/// Represents a single captured page within a scan session.
class ScannedPageItem {
  final String id;
  final String originalImagePath;
  final Uint8List? cachedProcessedBytes;
  final ImageEnhancementParams enhancementParams;
  final math.Point<double>? cropTopLeft;
  final math.Point<double>? cropTopRight;
  final math.Point<double>? cropBottomRight;
  final math.Point<double>? cropBottomLeft;
  final double? displayWidth;
  final double? displayHeight;
  final DateTime capturedAt;

  const ScannedPageItem({
    required this.id,
    required this.originalImagePath,
    this.cachedProcessedBytes,
    this.enhancementParams = const ImageEnhancementParams(),
    this.cropTopLeft,
    this.cropTopRight,
    this.cropBottomRight,
    this.cropBottomLeft,
    this.displayWidth,
    this.displayHeight,
    required this.capturedAt,
  });

  bool get isCropped => cropTopLeft != null;

  ScannedPageItem copyWith({
    String? id,
    String? originalImagePath,
    Uint8List? cachedProcessedBytes,
    ImageEnhancementParams? enhancementParams,
    math.Point<double>? cropTopLeft,
    math.Point<double>? cropTopRight,
    math.Point<double>? cropBottomRight,
    math.Point<double>? cropBottomLeft,
    double? displayWidth,
    double? displayHeight,
    DateTime? capturedAt,
  }) {
    return ScannedPageItem(
      id: id ?? this.id,
      originalImagePath: originalImagePath ?? this.originalImagePath,
      cachedProcessedBytes: cachedProcessedBytes ?? this.cachedProcessedBytes,
      enhancementParams: enhancementParams ?? this.enhancementParams,
      cropTopLeft: cropTopLeft ?? this.cropTopLeft,
      cropTopRight: cropTopRight ?? this.cropTopRight,
      cropBottomRight: cropBottomRight ?? this.cropBottomRight,
      cropBottomLeft: cropBottomLeft ?? this.cropBottomLeft,
      displayWidth: displayWidth ?? this.displayWidth,
      displayHeight: displayHeight ?? this.displayHeight,
      capturedAt: capturedAt ?? this.capturedAt,
    );
  }
}
