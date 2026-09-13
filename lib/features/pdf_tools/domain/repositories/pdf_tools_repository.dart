import 'dart:io';
import 'package:scanvault/features/pdf_creation/domain/pdf_models.dart';
import 'package:scanvault/shared/models/document.dart';
import '../entities/pdf_page_info.dart';
import '../entities/pdf_processing_progress.dart';
import '../entities/pdf_tool_result.dart';

enum WatermarkPosition {
  center,
  diagonal,
  top,
  bottom,
}

class WatermarkConfig {
  final String text;
  final double fontSize;
  final double opacity; // 0.1 to 1.0
  final double rotationDegrees;
  final WatermarkPosition position;
  final List<int>? targetPageIndices; // null means all pages

  const WatermarkConfig({
    required this.text,
    this.fontSize = 36.0,
    this.opacity = 0.35,
    this.rotationDegrees = 45.0,
    this.position = WatermarkPosition.diagonal,
    this.targetPageIndices,
  });
}

class PdfMetadataEditRequest {
  final String? title;
  final String? author;
  final String? subject;
  final String? keywords;
  final String? creator;

  const PdfMetadataEditRequest({
    this.title,
    this.author,
    this.subject,
    this.keywords,
    this.creator,
  });
}

abstract class PdfToolsRepository {
  /// Fetches lightweight page information and rasterized thumbnails
  Future<List<PdfPageInfo>> getPdfPages({
    required File pdfFile,
    bool generateThumbnails = true,
  });

  /// 1. Merge multiple PDFs into a single file
  Future<PdfToolResult> mergePdfs({
    required String userId,
    required List<File> sourcePdfs,
    required String outputTitle,
    String? folderId,
    ProgressCallback? onProgress,
  });

  /// 2. Split PDF by pages or ranges (e.g. '1-3', '4-7')
  Future<PdfToolResult> splitPdf({
    required String userId,
    required File sourcePdf,
    required List<String> ranges, // e.g. ['1-3', '4-7'] or ['1', '2', '3']
    required String baseOutputTitle,
    String? folderId,
    ProgressCallback? onProgress,
  });

  /// 3. Compress PDF with preset
  Future<PdfToolResult> compressPdf({
    required String userId,
    required File sourcePdf,
    required CompressionPreset preset,
    String? outputTitle,
    String? folderId,
    ProgressCallback? onProgress,
  });

  /// 4. Rotate selected PDF pages (90, 180, 270)
  Future<PdfToolResult> rotatePages({
    required String userId,
    required File sourcePdf,
    required Map<int, int> pageRotations, // pageIndex -> rotationDegrees (90, 180, 270)
    String? outputTitle,
    String? folderId,
    ProgressCallback? onProgress,
  });

  /// 5. Extract selected pages into a new PDF
  Future<PdfToolResult> extractPages({
    required String userId,
    required File sourcePdf,
    required List<int> pageIndices, // 0-indexed in extraction order
    required String outputTitle,
    String? folderId,
    ProgressCallback? onProgress,
  });

  /// 6. Delete selected pages from a PDF
  Future<PdfToolResult> deletePages({
    required String userId,
    required File sourcePdf,
    required Set<int> pageIndicesToDelete,
    String? outputTitle,
    String? folderId,
    ProgressCallback? onProgress,
  });

  /// 7. Reorder PDF pages
  Future<PdfToolResult> reorderPages({
    required String userId,
    required File sourcePdf,
    required List<int> newPageIndexOrder, // e.g. [2, 0, 1, 3]
    String? outputTitle,
    String? folderId,
    ProgressCallback? onProgress,
  });

  /// 8. Convert multiple images to PDF
  Future<PdfToolResult> imagesToPdf({
    required String userId,
    required List<File> imageFiles,
    required String outputTitle,
    PdfPageSize pageSize = PdfPageSize.a4,
    CompressionPreset preset = CompressionPreset.balanced,
    String? folderId,
    ProgressCallback? onProgress,
  });

  /// 9. Convert PDF pages to JPG or PNG images
  Future<PdfToolResult> pdfToImages({
    required String userId,
    required File sourcePdf,
    required List<int> pageIndices,
    bool isPng = false, // false = jpg, true = png
    int dpi = 200,
    ProgressCallback? onProgress,
  });

  /// 10. Protect PDF with AES-256 PIN / Password
  Future<PdfToolResult> protectPdf({
    required String userId,
    required File sourcePdf,
    required String password,
    String? outputTitle,
    String? folderId,
    ProgressCallback? onProgress,
  });

  /// 11. Add Watermark to PDF
  Future<PdfToolResult> watermarkPdf({
    required String userId,
    required File sourcePdf,
    required WatermarkConfig config,
    String? outputTitle,
    String? folderId,
    ProgressCallback? onProgress,
  });

  /// 12. Read and Update PDF Metadata
  Future<PdfMetadataEditRequest> readPdfMetadata(File sourcePdf);

  Future<PdfToolResult> updatePdfMetadata({
    required String userId,
    required File sourcePdf,
    required PdfMetadataEditRequest metadata,
    String? outputTitle,
    String? folderId,
    ProgressCallback? onProgress,
  });

  /// 13. Flatten form fields and annotations
  Future<PdfToolResult> flattenPdf({
    required String userId,
    required File sourcePdf,
    String? outputTitle,
    String? folderId,
    ProgressCallback? onProgress,
  });
}
