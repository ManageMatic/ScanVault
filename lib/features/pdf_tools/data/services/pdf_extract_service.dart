import 'dart:io';
import 'package:flutter/painting.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../domain/entities/pdf_processing_progress.dart';

class PdfExtractService {
  const PdfExtractService();

  Future<File> extractPages({
    required File sourcePdf,
    required File targetFile,
    required List<int> pageIndices, // 0-indexed in extraction order
    ProgressCallback? onProgress,
  }) async {
    if (!await sourcePdf.exists()) {
      throw FileSystemException('Source PDF does not exist', sourcePdf.path);
    }

    if (pageIndices.isEmpty) {
      throw ArgumentError('At least one page must be selected for extraction.');
    }

    onProgress?.call(const PdfProcessingProgress(
      progress: 0.1,
      statusMessage: 'Preparing page extraction...',
    ));

    final bytes = await sourcePdf.readAsBytes();
    final srcDoc = PdfDocument(inputBytes: bytes);
    final outDoc = PdfDocument();

    try {
      final totalSrcPages = srcDoc.pages.count;
      for (var i = 0; i < pageIndices.length; i++) {
        final idx = pageIndices[i];
        if (idx >= 0 && idx < totalSrcPages) {
          final page = srcDoc.pages[idx];
          final template = page.createTemplate();
          final newPage = outDoc.pages.add();
          newPage.graphics.drawPdfTemplate(template, Offset.zero);
        }

        onProgress?.call(PdfProcessingProgress(
          progress: 0.2 + (0.7 * ((i + 1) / pageIndices.length)),
          statusMessage: 'Extracting page ${i + 1} of ${pageIndices.length}...',
          currentPage: i + 1,
          totalPages: pageIndices.length,
        ));
      }

      if (outDoc.pages.count == 0) {
        throw StateError('No valid pages could be extracted.');
      }

      onProgress?.call(const PdfProcessingProgress(
        progress: 0.9,
        statusMessage: 'Saving extracted PDF document...',
      ));

      final outputBytes = await outDoc.save();
      await targetFile.parent.create(recursive: true);
      await targetFile.writeAsBytes(outputBytes, flush: true);
    } finally {
      srcDoc.dispose();
      outDoc.dispose();
    }

    onProgress?.call(const PdfProcessingProgress(
      progress: 1.0,
      statusMessage: 'Extraction complete!',
    ));

    return targetFile;
  }
}
