import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../image_processing/domain/image_processor.dart';
import '../domain/pdf_engine.dart';
import '../domain/pdf_models.dart';

/// 100% Offline, on-device production PDF compilation engine.
class LocalPdfEngine implements PdfEngine {
  const LocalPdfEngine();

  @override
  Future<PdfGenerationResult> generatePdf({
    required PdfGenerationRequest request,
    required Directory outputDirectory,
    Directory? thumbnailsDirectory,
  }) async {
    if (request.pages.isEmpty) {
      return PdfGenerationResult.failure('Cannot generate PDF: No pages provided.');
    }

    if (!await outputDirectory.exists()) {
      await outputDirectory.create(recursive: true);
    }

    final pagesDir = Directory(p.join(outputDirectory.path, 'pages'));
    if (!await pagesDir.exists()) {
      await pagesDir.create(recursive: true);
    }

    final tempPdfPath = p.join(outputDirectory.path, 'temp_${request.documentId}.pdf');
    final finalPdfPath = p.join(outputDirectory.path, 'final.pdf');

    try {
      final pdfDoc = pw.Document(
        title: request.title,
        author: request.author ?? 'ScanVault Offline Engine',
        subject: request.subject ?? 'ScanVault Document',
        creator: 'ScanVault',
      );

      Uint8List? firstPageOptimizedBytes;

      // Sequential page processing preserving exact user order and rotations
      for (var i = 0; i < request.pages.length; i++) {
        final pageInput = request.pages[i];

        // Apply Phase 3 image processing and target compression preset
        final processedBytes = ImageProcessor.processImageSync(
          rawBytes: pageInput.imageBytes,
          params: ImageEnhancementParams(
            rotationDegrees: pageInput.rotationDegrees,
          ),
          preset: request.compressionPreset,
        );

        if (i == 0) {
          firstPageOptimizedBytes = processedBytes;
        }

        // Persist individual page image
        final pageFile = File(p.join(pagesDir.path, 'page_${i + 1}.jpg'));
        await pageFile.writeAsBytes(processedBytes, flush: true);

        // Page Format / Dimension Strategy
        final pageFormat = _resolvePageFormat(processedBytes, request.pageSize);

        final pdfImage = pw.MemoryImage(processedBytes);
        pdfDoc.addPage(
          pw.Page(
            pageFormat: pageFormat,
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

      // 1. Atomic Write to Temporary File
      final pdfBytes = await pdfDoc.save();
      final tempFile = File(tempPdfPath);
      await tempFile.writeAsBytes(pdfBytes, flush: true);

      // 2. Strict PDF Validation
      final validation = await PdfValidator.validateFile(tempFile);
      if (!validation.isValid) {
        if (await tempFile.exists()) await tempFile.delete();
        return PdfGenerationResult.failure(
          'PDF validation failed: ${validation.errorMessage}',
        );
      }

      // 3. Atomic Move to Final Location
      final finalFile = File(finalPdfPath);
      if (await finalFile.exists()) {
        await finalFile.delete();
      }
      await tempFile.rename(finalPdfPath);

      final realSize = await finalFile.length();

      // 4. Generate High-Performance Thumbnail
      String? thumbnailPath;
      if (thumbnailsDirectory != null && firstPageOptimizedBytes != null) {
        if (!await thumbnailsDirectory.exists()) {
          await thumbnailsDirectory.create(recursive: true);
        }
        thumbnailPath = p.join(thumbnailsDirectory.path, '${request.documentId}.jpg');
        await ImageProcessor.generateThumbnail(
          imageBytes: firstPageOptimizedBytes,
          targetPath: thumbnailPath,
        );
      }

      return PdfGenerationResult(
        success: true,
        filePath: finalPdfPath,
        fileSizeBytes: realSize,
        pageCount: request.pages.length,
        thumbnailPath: thumbnailPath,
      );
    } catch (e) {
      // Clean up temporary file on failure to prevent corrupted artifacts
      final tempFile = File(tempPdfPath);
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      return PdfGenerationResult.failure('Failed to generate PDF: $e');
    }
  }

  PdfPageFormat _resolvePageFormat(Uint8List imageBytes, PdfPageSize pageSize) {
    switch (pageSize) {
      case PdfPageSize.a4:
        return PdfPageFormat.a4;
      case PdfPageSize.letter:
        return PdfPageFormat.letter;
      case PdfPageSize.auto:
        final decoded = img.decodeImage(imageBytes);
        if (decoded != null && decoded.width > 0 && decoded.height > 0) {
          // Standard 72 DPI PDF point scaling based on image aspect ratio
          const baseWidth = 595.0; // A4 standard width in points
          final computedHeight = baseWidth * (decoded.height / decoded.width);
          return PdfPageFormat(baseWidth, computedHeight);
        }
        return PdfPageFormat.a4;
    }
  }
}
