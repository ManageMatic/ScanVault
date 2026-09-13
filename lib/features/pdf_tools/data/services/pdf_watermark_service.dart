import 'dart:io';
import 'package:flutter/painting.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../domain/entities/pdf_processing_progress.dart';
import '../../domain/repositories/pdf_tools_repository.dart';

class PdfWatermarkService {
  const PdfWatermarkService();

  Future<File> addWatermark({
    required File sourcePdf,
    required File targetFile,
    required WatermarkConfig config,
    ProgressCallback? onProgress,
  }) async {
    if (!await sourcePdf.exists()) {
      throw FileSystemException('Source PDF does not exist', sourcePdf.path);
    }

    if (config.text.trim().isEmpty) {
      throw ArgumentError('Watermark text cannot be empty.');
    }

    onProgress?.call(const PdfProcessingProgress(
      progress: 0.1,
      statusMessage: 'Loading PDF document for stamping...',
    ));

    final bytes = await sourcePdf.readAsBytes();
    final document = PdfDocument(inputBytes: bytes);

    try {
      final totalPages = document.pages.count;
      final targetIndices = config.targetPageIndices?.toSet() ??
          List.generate(totalPages, (i) => i).toSet();

      final font = PdfStandardFont(
        PdfFontFamily.helvetica,
        config.fontSize,
        style: PdfFontStyle.bold,
      );
      final brush = PdfSolidBrush(PdfColor(100, 100, 100));

      for (var i = 0; i < totalPages; i++) {
        if (targetIndices.contains(i)) {
          final page = document.pages[i];
          final graphics = page.graphics;
          final pageSize = page.getClientSize();

          graphics.save();
          graphics.setTransparency(config.opacity.clamp(0.05, 1.0));

          final textSize = font.measureString(config.text);

          switch (config.position) {
            case WatermarkPosition.center:
              final x = (pageSize.width - textSize.width) / 2;
              final y = (pageSize.height - textSize.height) / 2;
              graphics.drawString(
                config.text,
                font,
                brush: brush,
                bounds: Rect.fromLTWH(x, y, textSize.width, textSize.height),
              );
              break;

            case WatermarkPosition.diagonal:
              graphics.translateTransform(pageSize.width / 2, pageSize.height / 2);
              graphics.rotateTransform(-config.rotationDegrees);
              graphics.drawString(
                config.text,
                font,
                brush: brush,
                bounds: Rect.fromLTWH(-textSize.width / 2, -textSize.height / 2, textSize.width, textSize.height),
              );
              break;

            case WatermarkPosition.top:
              final x = (pageSize.width - textSize.width) / 2;
              const y = 40.0;
              graphics.drawString(
                config.text,
                font,
                brush: brush,
                bounds: Rect.fromLTWH(x, y, textSize.width, textSize.height),
              );
              break;

            case WatermarkPosition.bottom:
              final x = (pageSize.width - textSize.width) / 2;
              final y = pageSize.height - textSize.height - 40.0;
              graphics.drawString(
                config.text,
                font,
                brush: brush,
                bounds: Rect.fromLTWH(x, y, textSize.width, textSize.height),
              );
              break;
          }

          graphics.restore();
        }

        onProgress?.call(PdfProcessingProgress(
          progress: 0.2 + (0.7 * ((i + 1) / totalPages)),
          statusMessage: 'Applying watermark to page ${i + 1} of $totalPages...',
          currentPage: i + 1,
          totalPages: totalPages,
        ));
      }

      onProgress?.call(const PdfProcessingProgress(
        progress: 0.9,
        statusMessage: 'Saving watermarked document...',
      ));

      final outputBytes = await document.save();
      await targetFile.parent.create(recursive: true);
      await targetFile.writeAsBytes(outputBytes, flush: true);
    } finally {
      document.dispose();
    }

    onProgress?.call(const PdfProcessingProgress(
      progress: 1.0,
      statusMessage: 'Watermarking complete!',
    ));

    return targetFile;
  }
}
