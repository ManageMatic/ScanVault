import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../../core/storage/storage_manager_service.dart';
import '../../../shared/models/document.dart';
import '../../image_processing/domain/image_processor.dart';
import '../../ocr/data/mlkit_ocr_service.dart';

class PdfCreationParams {
  final String title;
  final List<Uint8List> pageImages;
  final CompressionPreset compressionPreset;
  final String? folderId;

  const PdfCreationParams({
    required this.title,
    required this.pageImages,
    this.compressionPreset = CompressionPreset.balanced,
    this.folderId,
  });
}

/// Service generating small, optimized PDF documents from processed pages.
class PdfGeneratorService {
  final AppDatabase _database;
  final StorageManagerService _storageManager;

  PdfGeneratorService(this._database, this._storageManager);

  Future<Document> createOptimizedPdf({
    required String userId,
    required PdfCreationParams params,
  }) async {
    final documentId = const Uuid().v4();
    final docDir = await _storageManager.getDocumentDirectory(userId, documentId);
    final pdfFilePath = p.join(docDir.path, 'final.pdf');
    final pagesDir = Directory(p.join(docDir.path, 'pages'));
    if (!await pagesDir.exists()) await pagesDir.create(recursive: true);

    final pdf = pw.Document(
      title: params.title,
      author: 'ScanVault Offline Engine',
      creator: 'ScanVault',
    );

    Uint8List? firstPageProcessedBytes;

    for (var i = 0; i < params.pageImages.length; i++) {
      final rawPage = params.pageImages[i];
      // Optimize page with selected compression preset
      final processedBytes = ImageProcessor.processImageSync(
        rawBytes: rawPage,
        params: const ImageEnhancementParams(),
        preset: params.compressionPreset,
      );

      if (i == 0) firstPageProcessedBytes = processedBytes;

      // Save individual page image inside doc directory
      final pageFile = File(p.join(pagesDir.path, 'page_${i + 1}.jpg'));
      await pageFile.writeAsBytes(processedBytes);

      final pdfImage = pw.MemoryImage(processedBytes);
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (pw.Context context) {
            return pw.FullPage(
              ignoreMargins: true,
              child: pw.Image(pdfImage, fit: pw.BoxFit.contain),
            );
          },
        ),
      );
    }

    // Save final PDF to disk
    final pdfBytes = await pdf.save();
    final finalPdfFile = File(pdfFilePath);
    await finalPdfFile.writeAsBytes(pdfBytes);

    final realSizeBytes = await finalPdfFile.length();

    // Generate fast thumbnail in user thumbnails directory
    final thumbsDir = await _storageManager.getUserThumbnailsDirectory(userId);
    final thumbPath = p.join(thumbsDir.path, '$documentId.jpg');
    if (firstPageProcessedBytes != null) {
      await ImageProcessor.generateThumbnail(
        imageBytes: firstPageProcessedBytes,
        targetPath: thumbPath,
      );
    }

    // Extract on-device OCR text from pages
    final ocrService = MLKitOcrService();
    final ocrTexts = <String>[];
    for (final pageBytes in params.pageImages) {
      try {
        final res = await ocrService.recognizeTextFromBytes(pageBytes);
        if (res.fullText.isNotEmpty) {
          ocrTexts.add(res.fullText);
        }
      } catch (e) {
        // Continue silently if single page fails OCR
      }
    }
    final combinedOcrText = ocrTexts.join('\n\n').trim();

    final doc = Document(
      id: documentId,
      title: params.title.isNotEmpty ? params.title : 'Scan_${DateTime.now().millisecondsSinceEpoch}',
      pdfPath: pdfFilePath,
      thumbnailPath: thumbPath,
      folderId: params.folderId,
      fileSize: realSizeBytes,
      compressionPreset: params.compressionPreset,
      extractedOcrText: combinedOcrText.isNotEmpty ? combinedOcrText : null,
      ocrStatus: combinedOcrText.isNotEmpty ? OcrStatus.completed : OcrStatus.none,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Save metadata to SQLite
    await _database.insertDocument(userId, doc);

    // Cleanup user temporary files
    await _storageManager.cleanupTempDirectory(userId);

    return doc;
  }
}
