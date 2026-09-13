import 'dart:io';
import 'pdf_models.dart';

/// Abstract contract for local PDF compilation engines.
abstract class PdfEngine {
  Future<PdfGenerationResult> generatePdf({
    required PdfGenerationRequest request,
    required Directory outputDirectory,
    Directory? thumbnailsDirectory,
  });
}
