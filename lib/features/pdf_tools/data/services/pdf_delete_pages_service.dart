import 'dart:io';
import 'package:flutter/painting.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../domain/entities/pdf_processing_progress.dart';

class PdfDeletePagesService {
  const PdfDeletePagesService();

  Future<File> deletePages({
    required File sourcePdf,
    required File targetFile,
    required Set<int> pageIndicesToDelete, // 0-indexed
    ProgressCallback? onProgress,
  }) async {
    if (!await sourcePdf.exists()) {
      throw FileSystemException('Source PDF does not exist', sourcePdf.path);
    }

    if (pageIndicesToDelete.isEmpty) {
      throw ArgumentError('No pages selected for deletion.');
    }

    onProgress?.call(const PdfProcessingProgress(
      progress: 0.1,
      statusMessage: 'Loading document pages...',
    ));

    final bytes = await sourcePdf.readAsBytes();
    final srcDoc = PdfDocument(inputBytes: bytes);
    final totalPages = srcDoc.pages.count;

    if (pageIndicesToDelete.length >= totalPages) {
      srcDoc.dispose();
      throw ArgumentError('Cannot delete all pages from a document. At least 1 page must remain.');
    }

    final outDoc = PdfDocument();

    try {
      var copiedCount = 0;
      for (var i = 0; i < totalPages; i++) {
        if (!pageIndicesToDelete.contains(i)) {
          final page = srcDoc.pages[i];
          final template = page.createTemplate();
          final newPage = outDoc.pages.add();
          newPage.graphics.drawPdfTemplate(template, Offset.zero);
          copiedCount++;
        }

        onProgress?.call(PdfProcessingProgress(
          progress: 0.2 + (0.7 * ((i + 1) / totalPages)),
          statusMessage: 'Processing page ${i + 1} of $totalPages...',
          currentPage: i + 1,
          totalPages: totalPages,
        ));
      }

      if (copiedCount == 0) {
        throw StateError('Cannot create an empty PDF document.');
      }

      onProgress?.call(const PdfProcessingProgress(
        progress: 0.9,
        statusMessage: 'Saving document...',
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
      statusMessage: 'Pages deleted successfully!',
    ));

    return targetFile;
  }
}
