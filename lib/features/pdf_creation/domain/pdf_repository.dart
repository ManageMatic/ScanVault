import 'dart:io';
import '../../../shared/models/document.dart';
import 'pdf_models.dart';

/// Contract for high-level PDF operations and platform sharing/exporting.
abstract class PdfRepository {
  Future<Document> createDocumentPdf({
    required String userId,
    required PdfGenerationRequest request,
  });

  Future<bool> sharePdf({
    required File pdfFile,
    required String title,
  });

  Future<String?> exportPdfToDownloads({
    required File pdfFile,
    required String filename,
  });

  Future<PdfValidationResult> validatePdf(File pdfFile);
}
