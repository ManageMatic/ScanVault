import 'dart:io';
import 'package:flutter/painting.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../domain/entities/pdf_processing_progress.dart';

class PdfMergeService {
  const PdfMergeService();

  Future<File> mergePdfs({
    required List<File> sourcePdfs,
    required File targetFile,
    ProgressCallback? onProgress,
  }) async {
    if (sourcePdfs.length < 2) {
      throw ArgumentError('At least 2 PDF files are required to merge.');
    }

    onProgress?.call(const PdfProcessingProgress(
      progress: 0.1,
      statusMessage: 'Preparing PDF documents...',
    ));

    final outputDoc = PdfDocument();

    for (var i = 0; i < sourcePdfs.length; i++) {
      final file = sourcePdfs[i];
      if (!await file.exists()) {
        throw FileSystemException('Source PDF file does not exist', file.path);
      }

      onProgress?.call(PdfProcessingProgress(
        progress: 0.1 + (0.7 * (i / sourcePdfs.length)),
        statusMessage: 'Merging ${file.path.split(Platform.pathSeparator).last}...',
        currentPage: i + 1,
        totalPages: sourcePdfs.length,
      ));

      final bytes = await file.readAsBytes();
      final srcDoc = PdfDocument(inputBytes: bytes);

      try {
        for (var p = 0; p < srcDoc.pages.count; p++) {
          final page = srcDoc.pages[p];
          final template = page.createTemplate();
          final newPage = outputDoc.pages.add();
          newPage.graphics.drawPdfTemplate(template, Offset.zero);
        }
      } finally {
        srcDoc.dispose();
      }
    }

    onProgress?.call(const PdfProcessingProgress(
      progress: 0.9,
      statusMessage: 'Saving merged PDF document...',
    ));

    final mergedBytes = await outputDoc.save();
    outputDoc.dispose();

    await targetFile.parent.create(recursive: true);
    await targetFile.writeAsBytes(mergedBytes, flush: true);

    onProgress?.call(const PdfProcessingProgress(
      progress: 1.0,
      statusMessage: 'Merge complete!',
    ));

    return targetFile;
  }
}
