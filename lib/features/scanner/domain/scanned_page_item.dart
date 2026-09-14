import 'dart:math' as math;
import 'dart:typed_data';
import '../../image_processing/domain/image_processor.dart';

const Object _sentinel = Object();

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
  final int imageVersion;

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
    this.imageVersion = 0,
  });

  bool get isCropped => cropTopLeft != null || workingImagePath != null;
  bool get isFiltered => processedImagePath != null || enhancementParams.filterMode != ScanFilterMode.original;

  ScannedPageItem copyWith({
    String? id,
    String? sessionId,
    String? originalImagePath,
    Object? workingImagePath = _sentinel,
    Object? processedImagePath = _sentinel,
    Object? thumbnailPath = _sentinel,
    Object? cachedProcessedBytes = _sentinel,
    ImageEnhancementParams? enhancementParams,
    Object? cropTopLeft = _sentinel,
    Object? cropTopRight = _sentinel,
    Object? cropBottomRight = _sentinel,
    Object? cropBottomLeft = _sentinel,
    Object? displayWidth = _sentinel,
    Object? displayHeight = _sentinel,
    DateTime? capturedAt,
    int? imageVersion,
  }) {
    return ScannedPageItem(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      originalImagePath: originalImagePath ?? this.originalImagePath,
      workingImagePath: identical(workingImagePath, _sentinel)
          ? this.workingImagePath
          : workingImagePath as String?,
      processedImagePath: identical(processedImagePath, _sentinel)
          ? this.processedImagePath
          : processedImagePath as String?,
      thumbnailPath: identical(thumbnailPath, _sentinel)
          ? this.thumbnailPath
          : thumbnailPath as String?,
      cachedProcessedBytes: identical(cachedProcessedBytes, _sentinel)
          ? this.cachedProcessedBytes
          : cachedProcessedBytes as Uint8List?,
      enhancementParams: enhancementParams ?? this.enhancementParams,
      cropTopLeft: identical(cropTopLeft, _sentinel)
          ? this.cropTopLeft
          : cropTopLeft as math.Point<double>?,
      cropTopRight: identical(cropTopRight, _sentinel)
          ? this.cropTopRight
          : cropTopRight as math.Point<double>?,
      cropBottomRight: identical(cropBottomRight, _sentinel)
          ? this.cropBottomRight
          : cropBottomRight as math.Point<double>?,
      cropBottomLeft: identical(cropBottomLeft, _sentinel)
          ? this.cropBottomLeft
          : cropBottomLeft as math.Point<double>?,
      displayWidth: identical(displayWidth, _sentinel)
          ? this.displayWidth
          : displayWidth as double?,
      displayHeight: identical(displayHeight, _sentinel)
          ? this.displayHeight
          : displayHeight as double?,
      capturedAt: capturedAt ?? this.capturedAt,
      imageVersion: imageVersion ?? this.imageVersion,
    );
  }
}
