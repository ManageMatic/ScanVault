import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:scanvault/features/image_processing/domain/image_processor.dart';
import 'package:scanvault/features/pdf_tools/domain/entities/pdf_processing_progress.dart';
import 'package:scanvault/shared/models/document.dart';

class PdfCompressResult {
  final File compressedFile;
  final int originalSizeBytes;
  final int compressedSizeBytes;
  final double reductionPercentage;
  final bool isSmaller;

  const PdfCompressResult({
    required this.compressedFile,
    required this.originalSizeBytes,
    required this.compressedSizeBytes,
    required this.reductionPercentage,
    required this.isSmaller,
  });
}

class PdfCompressService {
  const PdfCompressService();

  Future<PdfCompressResult> compressPdf({
    required File sourcePdf,
    required File targetFile,
    required CompressionPreset preset,
    ProgressCallback? onProgress,
  }) async {
    if (!await sourcePdf.exists()) {
      throw FileSystemException('Source PDF does not exist', sourcePdf.path);
    }

    final originalSizeBytes = await sourcePdf.length();
    final pdfBytes = await sourcePdf.readAsBytes();

    onProgress?.call(const PdfProcessingProgress(
      progress: 0.1,
      statusMessage: 'Analyzing PDF content...',
    ));

    double dpi = 160.0;
    switch (preset) {
      case CompressionPreset.small:
        dpi = 120.0;
        break;
      case CompressionPreset.balanced:
        dpi = 160.0;
        break;
      case CompressionPreset.highQuality:
        dpi = 220.0;
        break;
    }

    final pdfDoc = pw.Document();
    var pageCount = 0;

    await for (final raster in Printing.raster(pdfBytes, dpi: dpi)) {
      pageCount++;
      onProgress?.call(PdfProcessingProgress(
        progress: 0.2 + (0.6 * (pageCount / (pageCount + 1))),
        statusMessage: 'Optimizing and compressing page $pageCount...',
        currentPage: pageCount,
      ));

      final pngBytes = await raster.toPng();
      final optimizedBytes = ImageProcessor.processImageSync(
        rawBytes: pngBytes,
        params: const ImageEnhancementParams(),
        preset: preset,
      );

      final pdfImage = pw.MemoryImage(optimizedBytes);
      pdfDoc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(raster.width.toDouble() * (72.0 / dpi), raster.height.toDouble() * (72.0 / dpi)),
          margin: pw.EdgeInsets.zero,
          build: (pw.Context context) {
            return pw.FullPage(
              ignoreMargins: true,
              child: pw.Center(
                child: pw.Image(
                  pdfImage,
                  fit: pw.BoxFit.contain,
                ),
              ),
            );
          },
        ),
      );
    }

    onProgress?.call(const PdfProcessingProgress(
      progress: 0.9,
      statusMessage: 'Finalizing compressed document...',
    ));

    final compressedBytes = await pdfDoc.save();
    await targetFile.parent.create(recursive: true);
    await targetFile.writeAsBytes(compressedBytes, flush: true);

    final compressedSizeBytes = await targetFile.length();
    final isSmaller = compressedSizeBytes < originalSizeBytes;
    final reduction = originalSizeBytes > 0
        ? ((originalSizeBytes - compressedSizeBytes) / originalSizeBytes) * 100.0
        : 0.0;

    onProgress?.call(const PdfProcessingProgress(
      progress: 1.0,
      statusMessage: 'Compression complete!',
    ));

    return PdfCompressResult(
      compressedFile: targetFile,
      originalSizeBytes: originalSizeBytes,
      compressedSizeBytes: compressedSizeBytes,
      reductionPercentage: reduction.clamp(0.0, 100.0),
      isSmaller: isSmaller,
    );
  }
}
