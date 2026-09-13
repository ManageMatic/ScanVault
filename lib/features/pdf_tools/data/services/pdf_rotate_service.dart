import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../domain/entities/pdf_processing_progress.dart';

class PdfRotateService {
  const PdfRotateService();

  PdfPageRotateAngle _toRotateAngle(int degrees) {
    final normalized = (degrees % 360 + 360) % 360;
    switch (normalized) {
      case 90:
        return PdfPageRotateAngle.rotateAngle90;
      case 180:
        return PdfPageRotateAngle.rotateAngle180;
      case 270:
        return PdfPageRotateAngle.rotateAngle270;
      default:
        return PdfPageRotateAngle.rotateAngle0;
    }
  }

  int _fromRotateAngle(PdfPageRotateAngle angle) {
    switch (angle) {
      case PdfPageRotateAngle.rotateAngle90:
        return 90;
      case PdfPageRotateAngle.rotateAngle180:
        return 180;
      case PdfPageRotateAngle.rotateAngle270:
        return 270;
      case PdfPageRotateAngle.rotateAngle0:
        return 0;
    }
  }

  Future<File> rotatePages({
    required File sourcePdf,
    required File targetFile,
    required Map<int, int> pageRotations, // pageIndex -> rotationDegrees to add
    ProgressCallback? onProgress,
  }) async {
    if (!await sourcePdf.exists()) {
      throw FileSystemException('Source PDF does not exist', sourcePdf.path);
    }

    onProgress?.call(const PdfProcessingProgress(
      progress: 0.1,
      statusMessage: 'Loading PDF pages for rotation...',
    ));

    final bytes = await sourcePdf.readAsBytes();
    final document = PdfDocument(inputBytes: bytes);

    try {
      final totalPages = document.pages.count;
      for (var i = 0; i < totalPages; i++) {
        final addDeg = pageRotations[i];
        if (addDeg != null && addDeg != 0) {
          final page = document.pages[i];
          final currentDeg = _fromRotateAngle(page.rotation);
          final newDeg = (currentDeg + addDeg) % 360;
          page.rotation = _toRotateAngle(newDeg);
        }

        onProgress?.call(PdfProcessingProgress(
          progress: 0.2 + (0.7 * ((i + 1) / totalPages)),
          statusMessage: 'Rotating page ${i + 1} of $totalPages...',
          currentPage: i + 1,
          totalPages: totalPages,
        ));
      }

      onProgress?.call(const PdfProcessingProgress(
        progress: 0.9,
        statusMessage: 'Saving rotated document...',
      ));

      final outputBytes = await document.save();
      await targetFile.parent.create(recursive: true);
      await targetFile.writeAsBytes(outputBytes, flush: true);
    } finally {
      document.dispose();
    }

    onProgress?.call(const PdfProcessingProgress(
      progress: 1.0,
      statusMessage: 'Rotation complete!',
    ));

    return targetFile;
  }
}
