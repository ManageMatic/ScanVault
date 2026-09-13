import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../../../shared/models/document.dart';
import '../domain/document_detector.dart';
import '../domain/image_processor.dart';
import '../domain/perspective_transformer.dart';

class _ProcessImageMessage {
  final Uint8List rawBytes;
  final ImageEnhancementParams params;
  final CompressionPreset preset;
  final int? customMaxDimension;

  _ProcessImageMessage({
    required this.rawBytes,
    required this.params,
    required this.preset,
    this.customMaxDimension,
  });
}

class _WarpPerspectiveMessage {
  final Uint8List rawBytes;
  final math.Point<double> tl;
  final math.Point<double> tr;
  final math.Point<double> br;
  final math.Point<double> bl;
  final CompressionPreset preset;
  final bool isNormalized;

  _WarpPerspectiveMessage({
    required this.rawBytes,
    required this.tl,
    required this.tr,
    required this.br,
    required this.bl,
    required this.preset,
    required this.isNormalized,
  });
}

/// Service executing CPU-heavy image processing in background Flutter Isolates.
class PipelineIsolateService {
  const PipelineIsolateService();

  /// Background Isolate execution for image enhancements and filter pipeline.
  Future<Uint8List> processImageAsync({
    required Uint8List rawBytes,
    required ImageEnhancementParams params,
    CompressionPreset preset = CompressionPreset.balanced,
    int? customMaxDimension,
  }) async {
    return compute(
      _isolateProcessImage,
      _ProcessImageMessage(
        rawBytes: rawBytes,
        params: params,
        preset: preset,
        customMaxDimension: customMaxDimension,
      ),
    );
  }

  /// Background Isolate execution for 4-corner perspective warping.
  Future<Uint8List> warpPerspectiveAsync({
    required Uint8List rawBytes,
    required math.Point<double> topLeft,
    required math.Point<double> topRight,
    required math.Point<double> bottomRight,
    required math.Point<double> bottomLeft,
    CompressionPreset preset = CompressionPreset.balanced,
    bool isNormalized = true,
  }) async {
    return compute(
      _isolateWarpPerspective,
      _WarpPerspectiveMessage(
        rawBytes: rawBytes,
        tl: topLeft,
        tr: topRight,
        br: bottomRight,
        bl: bottomLeft,
        preset: preset,
        isNormalized: isNormalized,
      ),
    );
  }

  /// Background Isolate execution for automatic document edge detection.
  Future<DocumentDetectionResult> detectDocumentAsync(Uint8List rawBytes) async {
    return compute(_isolateDetectDocument, rawBytes);
  }

  // Static top-level isolate handlers
  static Uint8List _isolateProcessImage(_ProcessImageMessage msg) {
    return ImageProcessor.processImageSync(
      rawBytes: msg.rawBytes,
      params: msg.params,
      preset: msg.preset,
      customMaxDimension: msg.customMaxDimension,
    );
  }

  static Uint8List _isolateWarpPerspective(_WarpPerspectiveMessage msg) {
    return PerspectiveTransformer.warpQuadrilateral(
      rawBytes: msg.rawBytes,
      topLeft: msg.tl,
      topRight: msg.tr,
      bottomRight: msg.br,
      bottomLeft: msg.bl,
      isNormalized: msg.isNormalized,
      preset: msg.preset,
    );
  }

  static Future<DocumentDetectionResult> _isolateDetectDocument(Uint8List rawBytes) async {
    const detector = EdgeDocumentDetector();
    return detector.detectFromBytes(rawBytes);
  }
}
