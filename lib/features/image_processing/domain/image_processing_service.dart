import 'dart:io';

/// Image filter enhancements.
enum ImageFilterType {
  original,
  enhancedColor,
  blackAndWhite,
  grayscale,
  magicColor,
  shadowRemoval,
}

/// Perspective crop points in normalized coordinates (0.0 to 1.0).
class CropQuad {
  final List<double> topLeft;
  final List<double> topRight;
  final List<double> bottomRight;
  final List<double> bottomLeft;

  const CropQuad({
    required this.topLeft,
    required this.topRight,
    required this.bottomRight,
    required this.bottomLeft,
  });
}

/// Image processing interface abstraction to decouple UI from native CV processing.
abstract class ImageProcessingService {
  Future<File> applyPerspectiveCorrection(File sourceImage, CropQuad quad);
  Future<File> rotateImage(File sourceImage, int angleDegrees);
  Future<File> applyFilter(File sourceImage, ImageFilterType filter);
  Future<File> adjustImage(File sourceImage, {double brightness = 0.0, double contrast = 1.0, double sharpness = 0.0});
  Future<CropQuad?> detectDocumentEdges(File sourceImage);
}
