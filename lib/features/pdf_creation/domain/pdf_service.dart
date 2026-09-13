import 'dart:io';
import '../../../shared/models/document_page.dart';
import '../../../shared/models/pdf_metadata.dart';

/// PDF operations abstraction.
abstract class PdfService {
  Future<File> generatePdfFromPages({
    required List<DocumentPage> pages,
    required String outputPath,
    PDFMetadata? metadata,
    int imageQuality = 85,
  });

  Future<File> mergePdfs({
    required List<File> sourcePdfs,
    required String outputPath,
  });

  Future<List<File>> splitPdf({
    required File sourcePdf,
    required List<List<int>> pageRanges,
    required String outputDir,
  });

  Future<File> compressPdf({
    required File sourcePdf,
    required String outputPath,
    int targetQuality = 75,
  });

  Future<File> rotatePdfPages({
    required File sourcePdf,
    required String outputPath,
    required Map<int, int> pageRotations,
  });

  Future<PDFMetadata> extractPdfMetadata(File pdfFile);
}
