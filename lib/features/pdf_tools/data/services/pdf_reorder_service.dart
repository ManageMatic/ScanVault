import 'dart:io';
import 'package:flutter/painting.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../domain/entities/pdf_processing_progress.dart';

class PdfReorderService {
  const PdfReorderService();

  Future<File> reorderPages({
    required File sourcePdf,
    required File targetFile,
    required List<int> newPageIndexOrder, // 0-indexed in target order
    ProgressCallback? onProgress,
  }) async {
    if (!await sourcePdf.exists()) {
      throw FileSystemException('Source PDF does not exist', sourcePdf.path);
    }

    if (newPageIndexOrder.isEmpty) {
      throw ArgumentError('New page order cannot be empty.');
    }

    onProgress?.call(const PdfProcessingProgress(
      progress: 0.1,
      statusMessage: 'Preparing page reordering...',
    ));

    final bytes = await sourcePdf.readAsBytes();
    final srcDoc = PdfDocument(inputBytes: bytes);
    final outDoc = PdfDocument();

    try {
      final totalSrcPages = srcDoc.pages.count;
      for (var i = 0; i < newPageIndexOrder.length; i++) {
        final idx = newPageIndexOrder[i];
        if (idx >= 0 && idx < totalSrcPages) {
          final page = srcDoc.pages[idx];
          final template = page.createTemplate();
          final newPage = outDoc.pages.add();
          newPage.graphics.drawPdfTemplate(template, Offset.zero);
        }

        onProgress?.call(PdfProcessingProgress(
          progress: 0.2 + (0.7 * ((i + 1) / newPageIndexOrder.length)),
          statusMessage: 'Placing page ${i + 1} of ${newPageIndexOrder.length}...',
          currentPage: i + 1,
          totalPages: newPageIndexOrder.length,
        ));
      }

      onProgress?.call(const PdfProcessingProgress(
        progress: 0.9,
        statusMessage: 'Saving reordered document...',
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
      statusMessage: 'Reordering complete!',
    ));

    return targetFile;
  }
}
