import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/database/app_database.dart';
import '../../../core/storage/storage_manager_service.dart';
import '../../../shared/models/document.dart';
import '../../../shared/models/pdf_metadata.dart';
import '../../ocr/data/mlkit_ocr_service.dart';
import '../domain/pdf_engine.dart';
import '../domain/pdf_models.dart';
import '../domain/pdf_repository.dart';
import 'local_pdf_engine.dart';

/// Concrete PDF repository implementing atomic persistence, sharing, and export.
class LocalPdfRepository implements PdfRepository {
  final AppDatabase _database;
  final StorageManagerService _storageManager;
  final PdfEngine _pdfEngine;

  LocalPdfRepository({
    AppDatabase? database,
    StorageManagerService? storageManager,
    PdfEngine? pdfEngine,
  })  : _database = database ?? AppDatabase(),
        _storageManager = storageManager ?? StorageManagerService(),
        _pdfEngine = pdfEngine ?? const LocalPdfEngine();

  @override
  Future<Document> createDocumentPdf({
    required String userId,
    required PdfGenerationRequest request,
  }) async {
    final docDir = await _storageManager.getDocumentDirectory(userId, request.documentId);
    final thumbsDir = await _storageManager.getUserThumbnailsDirectory(userId);

    // 1. Generate & Validate PDF via Engine
    final result = await _pdfEngine.generatePdf(
      request: request,
      outputDirectory: docDir,
      thumbnailsDirectory: thumbsDir,
    );

    if (!result.success || result.filePath == null) {
      throw Exception(result.errorMessage ?? 'Failed to compile PDF document.');
    }

    // 2. Perform on-device OCR extraction across pages
    final ocrService = MLKitOcrService();
    final ocrTexts = <String>[];
    for (final page in request.pages) {
      try {
        final res = await ocrService.recognizeTextFromBytes(page.imageBytes);
        if (res.fullText.trim().isNotEmpty) {
          ocrTexts.add(res.fullText.trim());
        }
      } catch (e) {
        debugPrint('OCR extraction skipped for page: $e');
      }
    }
    final combinedOcrText = ocrTexts.join('\n\n').trim();

    // 3. Create Document Metadata Record
    final doc = Document(
      id: request.documentId,
      title: request.title.trim().isNotEmpty ? request.title.trim() : 'Scan Document',
      pdfPath: result.filePath!,
      thumbnailPath: result.thumbnailPath,
      folderId: request.folderId,
      fileSize: result.fileSizeBytes,
      metadata: PDFMetadata(pageCount: result.pageCount),
      compressionPreset: request.compressionPreset,
      extractedOcrText: combinedOcrText.isNotEmpty ? combinedOcrText : null,
      ocrStatus: combinedOcrText.isNotEmpty ? OcrStatus.completed : OcrStatus.none,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // 4. Save metadata to SQLite
    await _database.insertDocument(userId, doc);

    // 5. Cleanup transient temporary files
    await _storageManager.cleanupTempDirectory(userId);

    return doc;
  }

  @override
  Future<bool> sharePdf({
    required File pdfFile,
    required String title,
  }) async {
    try {
      if (!await pdfFile.exists()) return false;
      final xFile = XFile(pdfFile.path, mimeType: 'application/pdf', name: sanitizePdfFilename(title));
      final result = await Share.shareXFiles([xFile], text: title);
      return result.status == ShareResultStatus.success;
    } catch (e) {
      debugPrint('Error sharing PDF: $e');
      return false;
    }
  }

  @override
  Future<String?> exportPdfToDownloads({
    required File pdfFile,
    required String filename,
  }) async {
    try {
      if (!await pdfFile.exists()) return null;

      Directory? targetDir;
      if (Platform.isAndroid) {
        targetDir = Directory('/storage/emulated/0/Download');
        if (!await targetDir.exists()) {
          targetDir = await getExternalStorageDirectory();
        }
      } else {
        targetDir = await getApplicationDocumentsDirectory();
      }

      if (targetDir == null || !await targetDir.exists()) {
        targetDir = await getApplicationDocumentsDirectory();
      }

      final safeName = sanitizePdfFilename(filename);
      final exportPath = p.join(targetDir.path, safeName);
      final exportedFile = await pdfFile.copy(exportPath);

      return exportedFile.path;
    } catch (e) {
      debugPrint('Error exporting PDF: $e');
      return null;
    }
  }

  @override
  Future<PdfValidationResult> validatePdf(File pdfFile) async {
    return PdfValidator.validateFile(pdfFile);
  }
}
