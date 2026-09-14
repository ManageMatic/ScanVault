import 'dart:math' as math;
import 'dart:typed_data';
import '../../image_processing/domain/image_processor.dart';

/// Represents a single captured page within a persistent scan session.
class ScannedPageItem {
  final String id;
  final String sessionId;
  final String originalImagePath;
  final String? workingImagePath;
  final String? processedImagePath;
  final String? thumbnailPath;
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
    this.sessionId = 'default_session',
    required this.originalImagePath,
    this.workingImagePath,
    this.processedImagePath,
    this.thumbnailPath,
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

  bool get isCropped => cropTopLeft != null || workingImagePath != null;
  bool get isFiltered => processedImagePath != null || enhancementParams.filterMode != ScanFilterMode.original;

  ScannedPageItem copyWith({
    String? id,
    String? sessionId,
    String? originalImagePath,
    String? workingImagePath,
    String? processedImagePath,
    String? thumbnailPath,
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
      sessionId: sessionId ?? this.sessionId,
      originalImagePath: originalImagePath ?? this.originalImagePath,
      workingImagePath: workingImagePath ?? this.workingImagePath,
      processedImagePath: processedImagePath ?? this.processedImagePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
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
