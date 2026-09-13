import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../domain/entities/pdf_processing_progress.dart';

class PdfFlattenService {
  const PdfFlattenService();

  Future<File> flattenPdf({
    required File sourcePdf,
    required File targetFile,
    ProgressCallback? onProgress,
  }) async {
    if (!await sourcePdf.exists()) {
      throw FileSystemException('Source PDF does not exist', sourcePdf.path);
    }

    onProgress?.call(const PdfProcessingProgress(
      progress: 0.1,
      statusMessage: 'Loading PDF document for flattening...',
    ));

    final bytes = await sourcePdf.readAsBytes();
    final document = PdfDocument(inputBytes: bytes);

    try {
      onProgress?.call(const PdfProcessingProgress(
        progress: 0.4,
        statusMessage: 'Flattening interactive form fields...',
      ));

      if (document.form.fields.count > 0) {
        document.form.flattenAllFields();
      }

      onProgress?.call(const PdfProcessingProgress(
        progress: 0.7,
        statusMessage: 'Flattening annotations & overlays...',
      ));

      for (var i = 0; i < document.pages.count; i++) {
        final page = document.pages[i];
        if (page.annotations.count > 0) {
          page.annotations.flattenAllAnnotations();
        }
      }

      onProgress?.call(const PdfProcessingProgress(
        progress: 0.9,
        statusMessage: 'Saving flattened document...',
      ));

      final outputBytes = await document.save();
      await targetFile.parent.create(recursive: true);
      await targetFile.writeAsBytes(outputBytes, flush: true);
    } finally {
      document.dispose();
    }

    onProgress?.call(const PdfProcessingProgress(
      progress: 1.0,
      statusMessage: 'Flattening complete!',
    ));

    return targetFile;
  }
}
