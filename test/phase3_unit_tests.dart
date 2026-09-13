import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:scanvault/features/image_processing/domain/document_detector.dart';
import 'package:scanvault/features/image_processing/domain/image_processor.dart';
import 'package:scanvault/features/image_processing/domain/perspective_transformer.dart';
import 'package:scanvault/shared/models/document.dart';

void main() {
  group('Phase 3 — Document Detection Tests', () {
    test('Default bounds calculation creates valid inset quadrilateral', () {
      final bounds = DocumentDetectionResult.defaultBounds(1000, 1500);
      expect(bounds.isValid, isTrue);
      expect(bounds.topLeft.x, closeTo(0.05, 0.001));
      expect(bounds.topLeft.y, closeTo(0.05, 0.001));
      expect(bounds.bottomRight.x, closeTo(0.95, 0.001));
      expect(bounds.bottomRight.y, closeTo(0.95, 0.001));

      final scaled = bounds.getScaledCorners(1000, 1500);
      expect(scaled.length, 4);
      expect(scaled[0].x, closeTo(50.0, 0.1));
      expect(scaled[0].y, closeTo(75.0, 0.1));
    });

    test('EdgeDocumentDetector on synthetic document detects valid bounds', () async {
      final sampleBitmap = ImageProcessor.createSampleDocumentBitmap();
      const detector = EdgeDocumentDetector();
      final result = await detector.detectFromBytes(sampleBitmap);

      expect(result.isValid, isTrue);
      expect(result.topLeft.x, greaterThanOrEqualTo(0.0));
      expect(result.bottomRight.x, lessThanOrEqualTo(1.0));
    });
  });

  group('Phase 3 — Perspective Warping Tests', () {
    test('PerspectiveTransformer warps 4-corner quad into proportional rectangle', () {
      final sampleBitmap = ImageProcessor.createSampleDocumentBitmap();
      final warped = PerspectiveTransformer.warpQuadrilateral(
        rawBytes: sampleBitmap,
        topLeft: const math.Point(0.08, 0.08),
        topRight: const math.Point(0.92, 0.10),
        bottomRight: const math.Point(0.90, 0.92),
        bottomLeft: const math.Point(0.10, 0.90),
        isNormalized: true,
        preset: CompressionPreset.balanced,
      );

      expect(warped, isNotNull);
      expect(warped.isNotEmpty, isTrue);
      expect(warped.length, greaterThan(1000));
    });
  });

  group('Phase 3 — Image Processor & Enhancements Tests', () {
    test('Applies all filter modes without errors', () {
      final sampleBitmap = ImageProcessor.createSampleDocumentBitmap();

      for (final filter in ScanFilterMode.values) {
        final processed = ImageProcessor.processImageSync(
          rawBytes: sampleBitmap,
          params: ImageEnhancementParams(filterMode: filter),
        );
        expect(processed.isNotEmpty, isTrue);
      }
    });

    test('Shadow removal operates cleanly', () {
      final sampleBitmap = ImageProcessor.createSampleDocumentBitmap();
      final processed = ImageProcessor.processImageSync(
        rawBytes: sampleBitmap,
        params: const ImageEnhancementParams(
          shadowRemoval: 0.8,
          brightness: 0.1,
          contrast: 1.1,
        ),
      );
      expect(processed.isNotEmpty, isTrue);
    });

    test('ImageEnhancementParams serializes and deserializes accurately', () {
      const original = ImageEnhancementParams(
        brightness: 0.25,
        contrast: 1.2,
        shadowRemoval: 0.75,
        filterMode: ScanFilterMode.magicColor,
        rotationDegrees: 90,
      );

      final json = original.toJson();
      final deserialized = ImageEnhancementParams.fromJson(json);

      expect(deserialized.brightness, 0.25);
      expect(deserialized.contrast, 1.2);
      expect(deserialized.shadowRemoval, 0.75);
      expect(deserialized.filterMode, ScanFilterMode.magicColor);
      expect(deserialized.rotationDegrees, 90);
    });
  });
}
