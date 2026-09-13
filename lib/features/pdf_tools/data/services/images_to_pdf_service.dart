import 'dart:io';
import 'package:scanvault/features/pdf_creation/data/local_pdf_engine.dart';
import 'package:scanvault/features/pdf_creation/domain/pdf_engine.dart';
import 'package:scanvault/features/pdf_creation/domain/pdf_models.dart';
import 'package:scanvault/features/pdf_tools/domain/entities/pdf_processing_progress.dart';
import 'package:scanvault/shared/models/document.dart';
import 'package:uuid/uuid.dart';

class ImagesToPdfService {
  final PdfEngine _pdfEngine;

  const ImagesToPdfService({PdfEngine? pdfEngine})
      : _pdfEngine = pdfEngine ?? const LocalPdfEngine();

  Future<PdfGenerationResult> convertImagesToPdf({
    required String userId,
    required List<File> imageFiles,
    required String outputTitle,
    required Directory outputDirectory,
    Directory? thumbnailsDirectory,
    PdfPageSize pageSize = PdfPageSize.a4,
    CompressionPreset preset = CompressionPreset.balanced,
    List<int>? rotations,
    ProgressCallback? onProgress,
  }) async {
    if (imageFiles.isEmpty) {
      return PdfGenerationResult.failure('Cannot convert empty list of images.');
    }

    onProgress?.call(const PdfProcessingProgress(
      progress: 0.1,
      statusMessage: 'Reading selected image files...',
    ));

    final pageInputs = <PdfPageInput>[];
    for (var i = 0; i < imageFiles.length; i++) {
      final file = imageFiles[i];
      if (!await file.exists()) {
        return PdfGenerationResult.failure('Image file missing: ${file.path}');
      }

      onProgress?.call(PdfProcessingProgress(
        progress: 0.1 + (0.3 * ((i + 1) / imageFiles.length)),
        statusMessage: 'Loading image ${i + 1} of ${imageFiles.length}...',
        currentPage: i + 1,
        totalPages: imageFiles.length,
      ));

      final bytes = await file.readAsBytes();
      final rot = (rotations != null && i < rotations.length) ? rotations[i] : 0;

      pageInputs.add(PdfPageInput(
        imageBytes: bytes,
        rotationDegrees: rot,
        pageNumber: i + 1,
      ));
    }

    onProgress?.call(const PdfProcessingProgress(
      progress: 0.5,
      statusMessage: 'Compiling PDF document with image optimization...',
    ));

    final request = PdfGenerationRequest(
      documentId: const Uuid().v4(),
      userId: userId,
      title: outputTitle,
      pages: pageInputs,
      pageSize: pageSize,
      compressionPreset: preset,
    );

    final result = await _pdfEngine.generatePdf(
      request: request,
      outputDirectory: outputDirectory,
      thumbnailsDirectory: thumbnailsDirectory,
    );

    onProgress?.call(const PdfProcessingProgress(
      progress: 1.0,
      statusMessage: 'PDF creation complete!',
    ));

    return result;
  }
}
