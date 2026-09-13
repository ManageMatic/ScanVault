import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import 'package:uuid/uuid.dart';
import 'package:scanvault/core/database/app_database.dart';
import 'package:scanvault/core/storage/storage_manager_service.dart';
import 'package:scanvault/features/image_processing/domain/image_processor.dart';
import 'package:scanvault/features/ocr/data/mlkit_ocr_service.dart';
import 'package:scanvault/features/pdf_creation/domain/pdf_models.dart';
import 'package:scanvault/features/pdf_tools/data/services/images_to_pdf_service.dart';
import 'package:scanvault/features/pdf_tools/data/services/pdf_compress_service.dart';
import 'package:scanvault/features/pdf_tools/data/services/pdf_delete_pages_service.dart';
import 'package:scanvault/features/pdf_tools/data/services/pdf_extract_service.dart';
import 'package:scanvault/features/pdf_tools/data/services/pdf_flatten_service.dart';
import 'package:scanvault/features/pdf_tools/data/services/pdf_merge_service.dart';
import 'package:scanvault/features/pdf_tools/data/services/pdf_metadata_service.dart';
import 'package:scanvault/features/pdf_tools/data/services/pdf_protection_service.dart';
import 'package:scanvault/features/pdf_tools/data/services/pdf_reorder_service.dart';
import 'package:scanvault/features/pdf_tools/data/services/pdf_rotate_service.dart';
import 'package:scanvault/features/pdf_tools/data/services/pdf_split_service.dart';
import 'package:scanvault/features/pdf_tools/data/services/pdf_to_images_service.dart';
import 'package:scanvault/features/pdf_tools/data/services/pdf_watermark_service.dart';
import 'package:scanvault/features/pdf_tools/domain/entities/pdf_page_info.dart';
import 'package:scanvault/features/pdf_tools/domain/entities/pdf_processing_progress.dart';
import 'package:scanvault/features/pdf_tools/domain/entities/pdf_tool_result.dart';
import 'package:scanvault/features/pdf_tools/domain/repositories/pdf_tools_repository.dart';
import 'package:scanvault/shared/models/document.dart';
import 'package:scanvault/shared/models/pdf_metadata.dart';

class LocalPdfToolsRepository implements PdfToolsRepository {
  final AppDatabase _database;
  final StorageManagerService _storageManager;
  final PdfMergeService _mergeService;
  final PdfSplitService _splitService;
  final PdfCompressService _compressService;
  final PdfRotateService _rotateService;
  final PdfExtractService _extractService;
  final PdfDeletePagesService _deletePagesService;
  final PdfReorderService _reorderService;
  final ImagesToPdfService _imagesToPdfService;
  final PdfToImagesService _pdfToImagesService;
  final PdfProtectionService _protectionService;
  final PdfWatermarkService _watermarkService;
  final PdfMetadataService _metadataService;
  final PdfFlattenService _flattenService;

  LocalPdfToolsRepository({
    AppDatabase? database,
    StorageManagerService? storageManager,
    PdfMergeService? mergeService,
    PdfSplitService? splitService,
    PdfCompressService? compressService,
    PdfRotateService? rotateService,
    PdfExtractService? extractService,
    PdfDeletePagesService? deletePagesService,
    PdfReorderService? reorderService,
    ImagesToPdfService? imagesToPdfService,
    PdfToImagesService? pdfToImagesService,
    PdfProtectionService? protectionService,
    PdfWatermarkService? watermarkService,
    PdfMetadataService? metadataService,
    PdfFlattenService? flattenService,
  })  : _database = database ?? AppDatabase(),
        _storageManager = storageManager ?? StorageManagerService(),
        _mergeService = mergeService ?? const PdfMergeService(),
        _splitService = splitService ?? const PdfSplitService(),
        _compressService = compressService ?? const PdfCompressService(),
        _rotateService = rotateService ?? const PdfRotateService(),
        _extractService = extractService ?? const PdfExtractService(),
        _deletePagesService = deletePagesService ?? const PdfDeletePagesService(),
        _reorderService = reorderService ?? const PdfReorderService(),
        _imagesToPdfService = imagesToPdfService ?? const ImagesToPdfService(),
        _pdfToImagesService = pdfToImagesService ?? const PdfToImagesService(),
        _protectionService = protectionService ?? const PdfProtectionService(),
        _watermarkService = watermarkService ?? const PdfWatermarkService(),
        _metadataService = metadataService ?? const PdfMetadataService(),
        _flattenService = flattenService ?? const PdfFlattenService();

  @override
  Future<List<PdfPageInfo>> getPdfPages({
    required File pdfFile,
    bool generateThumbnails = true,
  }) async {
    if (!await pdfFile.exists()) return [];

    try {
      final bytes = await pdfFile.readAsBytes();
      final doc = sf.PdfDocument(inputBytes: bytes);
      final count = doc.pages.count;
      final pages = <PdfPageInfo>[];

      for (var i = 0; i < count; i++) {
        final page = doc.pages[i];
        final sz = page.getClientSize();
        int rotDeg = 0;
        switch (page.rotation) {
          case sf.PdfPageRotateAngle.rotateAngle90:
            rotDeg = 90;
            break;
          case sf.PdfPageRotateAngle.rotateAngle180:
            rotDeg = 180;
            break;
          case sf.PdfPageRotateAngle.rotateAngle270:
            rotDeg = 270;
            break;
          default:
            rotDeg = 0;
        }

        pages.add(PdfPageInfo(
          pageIndex: i,
          pageNumber: i + 1,
          width: sz.width,
          height: sz.height,
          rotationDegrees: rotDeg,
        ));
      }
      doc.dispose();

      if (generateThumbnails && count > 0) {
        try {
          var idx = 0;
          await for (final raster in Printing.raster(bytes, dpi: 72.0)) {
            if (idx < pages.length) {
              final pngBytes = await raster.toPng();
              pages[idx] = pages[idx].copyWith(thumbnailBytes: pngBytes);
            }
            idx++;
          }
        } catch (_) {}
      }

      return pages;
    } catch (e) {
      debugPrint('Error getting PDF pages: $e');
      return [];
    }
  }

  Future<Document> _savePdfAsDocument({
    required String userId,
    required File tempPdfFile,
    required String title,
    String? folderId,
    CompressionPreset preset = CompressionPreset.balanced,
  }) async {
    final validation = await PdfValidator.validateFile(tempPdfFile);
    if (!validation.isValid) {
      if (await tempPdfFile.exists()) await tempPdfFile.delete();
      throw Exception('PDF Validation Error: ${validation.errorMessage}');
    }

    final docId = const Uuid().v4();
    final docDir = await _storageManager.getDocumentDirectory(userId, docId);
    final finalPdfPath = p.join(docDir.path, 'final.pdf');
    final finalFile = File(finalPdfPath);

    if (await finalFile.exists()) await finalFile.delete();
    await tempPdfFile.rename(finalPdfPath);

    // Read page count
    final finalBytes = await finalFile.readAsBytes();
    final doc = sf.PdfDocument(inputBytes: finalBytes);
    final pageCount = doc.pages.count;
    doc.dispose();

    // Generate thumbnail
    final thumbsDir = await _storageManager.getUserThumbnailsDirectory(userId);
    final thumbPath = p.join(thumbsDir.path, '$docId.jpg');
    try {
      await for (final raster in Printing.raster(finalBytes, pages: [0], dpi: 100.0)) {
        final png = await raster.toPng();
        await ImageProcessor.generateThumbnail(
          imageBytes: png,
          targetPath: thumbPath,
        );
        break;
      }
    } catch (e) {
      debugPrint('Thumbnail creation skipped: $e');
    }

    final fileSize = await finalFile.length();
    final document = Document(
      id: docId,
      title: title.trim().isNotEmpty ? title.trim() : 'PDF Document',
      pdfPath: finalPdfPath,
      thumbnailPath: await File(thumbPath).exists() ? thumbPath : null,
      folderId: folderId,
      fileSize: fileSize,
      metadata: PDFMetadata(pageCount: pageCount),
      compressionPreset: preset,
      ocrStatus: OcrStatus.none,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _database.insertDocument(userId, document);
    await _storageManager.cleanupTempDirectory(userId);
    return document;
  }

  @override
  Future<PdfToolResult> mergePdfs({
    required String userId,
    required List<File> sourcePdfs,
    required String outputTitle,
    String? folderId,
    ProgressCallback? onProgress,
  }) async {
    final tempDir = await _storageManager.getUserTempDirectory(userId);
    final tempFile = File(p.join(tempDir.path, 'merged_${const Uuid().v4().substring(0, 8)}.pdf'));

    try {
      await _mergeService.mergePdfs(
        sourcePdfs: sourcePdfs,
        targetFile: tempFile,
        onProgress: onProgress,
      );

      final doc = await _savePdfAsDocument(
        userId: userId,
        tempPdfFile: tempFile,
        title: outputTitle,
        folderId: folderId,
      );

      return PdfToolResult.success(
        document: doc,
        pageCount: doc.pageCount,
        outputSizeBytes: doc.fileSize,
        summaryMessage: 'Successfully merged ${sourcePdfs.length} PDFs into 1 document.',
      );
    } catch (e) {
      if (await tempFile.exists()) await tempFile.delete();
      return PdfToolResult.failure(e.toString());
    }
  }

  @override
  Future<PdfToolResult> splitPdf({
    required String userId,
    required File sourcePdf,
    required List<String> ranges,
    required String baseOutputTitle,
    String? folderId,
    ProgressCallback? onProgress,
  }) async {
    final tempDir = await _storageManager.getUserTempDirectory(userId);
    final splitTempDir = Directory(p.join(tempDir.path, 'split_${const Uuid().v4().substring(0, 8)}'));
    await splitTempDir.create(recursive: true);

    try {
      final splitFiles = await _splitService.splitPdf(
        sourcePdf: sourcePdf,
        ranges: ranges,
        outputDirectory: splitTempDir,
        baseOutputTitle: baseOutputTitle,
        onProgress: onProgress,
      );

      if (splitFiles.isEmpty) {
        return PdfToolResult.failure('No split files were generated from the given ranges.');
      }

      Document? lastDoc;
      final generatedPaths = <String>[];
      for (var i = 0; i < splitFiles.length; i++) {
        final f = splitFiles[i];
        final rangeTitle = p.basenameWithoutExtension(f.path);
        final doc = await _savePdfAsDocument(
          userId: userId,
          tempPdfFile: f,
          title: rangeTitle,
          folderId: folderId,
        );
        generatedPaths.add(doc.filePath);
        lastDoc = doc;
      }

      return PdfToolResult.success(
        document: lastDoc,
        generatedFilePaths: generatedPaths,
        summaryMessage: 'Successfully split into ${splitFiles.length} separate documents.',
      );
    } catch (e) {
      if (await splitTempDir.exists()) await splitTempDir.delete(recursive: true);
      return PdfToolResult.failure(e.toString());
    }
  }

  @override
  Future<PdfToolResult> compressPdf({
    required String userId,
    required File sourcePdf,
    required CompressionPreset preset,
    String? outputTitle,
    String? folderId,
    ProgressCallback? onProgress,
  }) async {
    final tempDir = await _storageManager.getUserTempDirectory(userId);
    final tempFile = File(p.join(tempDir.path, 'compressed_${const Uuid().v4().substring(0, 8)}.pdf'));

    try {
      final compressResult = await _compressService.compressPdf(
        sourcePdf: sourcePdf,
        targetFile: tempFile,
        preset: preset,
        onProgress: onProgress,
      );

      final title = outputTitle ?? '${p.basenameWithoutExtension(sourcePdf.path)} (Compressed)';
      final doc = await _savePdfAsDocument(
        userId: userId,
        tempPdfFile: compressResult.compressedFile,
        title: title,
        folderId: folderId,
        preset: preset,
      );

      return PdfToolResult.success(
        document: doc,
        originalSizeBytes: compressResult.originalSizeBytes,
        outputSizeBytes: compressResult.compressedSizeBytes,
        pageCount: doc.pageCount,
        summaryMessage: compressResult.isSmaller
            ? 'Compressed from ${formatBytes(compressResult.originalSizeBytes)} to ${formatBytes(compressResult.compressedSizeBytes)} (${compressResult.reductionPercentage.toStringAsFixed(1)}% smaller)'
            : 'Compression completed (${formatBytes(compressResult.compressedSizeBytes)})',
      );
    } catch (e) {
      if (await tempFile.exists()) await tempFile.delete();
      return PdfToolResult.failure(e.toString());
    }
  }

  @override
  Future<PdfToolResult> rotatePages({
    required String userId,
    required File sourcePdf,
    required Map<int, int> pageRotations,
    String? outputTitle,
    String? folderId,
    ProgressCallback? onProgress,
  }) async {
    final tempDir = await _storageManager.getUserTempDirectory(userId);
    final tempFile = File(p.join(tempDir.path, 'rotated_${const Uuid().v4().substring(0, 8)}.pdf'));

    try {
      await _rotateService.rotatePages(
        sourcePdf: sourcePdf,
        targetFile: tempFile,
        pageRotations: pageRotations,
        onProgress: onProgress,
      );

      final title = outputTitle ?? p.basenameWithoutExtension(sourcePdf.path);
      final doc = await _savePdfAsDocument(
        userId: userId,
        tempPdfFile: tempFile,
        title: title,
        folderId: folderId,
      );

      return PdfToolResult.success(
        document: doc,
        pageCount: doc.pageCount,
        outputSizeBytes: doc.fileSize,
        summaryMessage: 'Successfully rotated ${pageRotations.length} page(s).',
      );
    } catch (e) {
      if (await tempFile.exists()) await tempFile.delete();
      return PdfToolResult.failure(e.toString());
    }
  }

  @override
  Future<PdfToolResult> extractPages({
    required String userId,
    required File sourcePdf,
    required List<int> pageIndices,
    required String outputTitle,
    String? folderId,
    ProgressCallback? onProgress,
  }) async {
    final tempDir = await _storageManager.getUserTempDirectory(userId);
    final tempFile = File(p.join(tempDir.path, 'extracted_${const Uuid().v4().substring(0, 8)}.pdf'));

    try {
      await _extractService.extractPages(
        sourcePdf: sourcePdf,
        targetFile: tempFile,
        pageIndices: pageIndices,
        onProgress: onProgress,
      );

      final doc = await _savePdfAsDocument(
        userId: userId,
        tempPdfFile: tempFile,
        title: outputTitle,
        folderId: folderId,
      );

      return PdfToolResult.success(
        document: doc,
        pageCount: doc.pageCount,
        outputSizeBytes: doc.fileSize,
        summaryMessage: 'Extracted ${pageIndices.length} pages into a new document.',
      );
    } catch (e) {
      if (await tempFile.exists()) await tempFile.delete();
      return PdfToolResult.failure(e.toString());
    }
  }

  @override
  Future<PdfToolResult> deletePages({
    required String userId,
    required File sourcePdf,
    required Set<int> pageIndicesToDelete,
    String? outputTitle,
    String? folderId,
    ProgressCallback? onProgress,
  }) async {
    final tempDir = await _storageManager.getUserTempDirectory(userId);
    final tempFile = File(p.join(tempDir.path, 'deleted_pages_${const Uuid().v4().substring(0, 8)}.pdf'));

    try {
      await _deletePagesService.deletePages(
        sourcePdf: sourcePdf,
        targetFile: tempFile,
        pageIndicesToDelete: pageIndicesToDelete,
        onProgress: onProgress,
      );

      final title = outputTitle ?? p.basenameWithoutExtension(sourcePdf.path);
      final doc = await _savePdfAsDocument(
        userId: userId,
        tempPdfFile: tempFile,
        title: title,
        folderId: folderId,
      );

      return PdfToolResult.success(
        document: doc,
        pageCount: doc.pageCount,
        outputSizeBytes: doc.fileSize,
        summaryMessage: 'Successfully removed ${pageIndicesToDelete.length} page(s).',
      );
    } catch (e) {
      if (await tempFile.exists()) await tempFile.delete();
      return PdfToolResult.failure(e.toString());
    }
  }

  @override
  Future<PdfToolResult> reorderPages({
    required String userId,
    required File sourcePdf,
    required List<int> newPageIndexOrder,
    String? outputTitle,
    String? folderId,
    ProgressCallback? onProgress,
  }) async {
    final tempDir = await _storageManager.getUserTempDirectory(userId);
    final tempFile = File(p.join(tempDir.path, 'reordered_${const Uuid().v4().substring(0, 8)}.pdf'));

    try {
      await _reorderService.reorderPages(
        sourcePdf: sourcePdf,
        targetFile: tempFile,
        newPageIndexOrder: newPageIndexOrder,
        onProgress: onProgress,
      );

      final title = outputTitle ?? p.basenameWithoutExtension(sourcePdf.path);
      final doc = await _savePdfAsDocument(
        userId: userId,
        tempPdfFile: tempFile,
        title: title,
        folderId: folderId,
      );

      return PdfToolResult.success(
        document: doc,
        pageCount: doc.pageCount,
        outputSizeBytes: doc.fileSize,
        summaryMessage: 'Pages reordered successfully.',
      );
    } catch (e) {
      if (await tempFile.exists()) await tempFile.delete();
      return PdfToolResult.failure(e.toString());
    }
  }

  @override
  Future<PdfToolResult> imagesToPdf({
    required String userId,
    required List<File> imageFiles,
    required String outputTitle,
    PdfPageSize pageSize = PdfPageSize.a4,
    CompressionPreset preset = CompressionPreset.balanced,
    String? folderId,
    ProgressCallback? onProgress,
  }) async {
    final docId = const Uuid().v4();
    final docDir = await _storageManager.getDocumentDirectory(userId, docId);
    final thumbsDir = await _storageManager.getUserThumbnailsDirectory(userId);

    try {
      final genResult = await _imagesToPdfService.convertImagesToPdf(
        userId: userId,
        imageFiles: imageFiles,
        outputTitle: outputTitle,
        outputDirectory: docDir,
        thumbnailsDirectory: thumbsDir,
        pageSize: pageSize,
        preset: preset,
        onProgress: onProgress,
      );

      if (!genResult.success || genResult.filePath == null) {
        return PdfToolResult.failure(genResult.errorMessage ?? 'Failed to convert images to PDF.');
      }

      // OCR Extraction
      final ocrService = MLKitOcrService();
      final ocrTexts = <String>[];
      for (final imgFile in imageFiles) {
        try {
          final res = await ocrService.recognizeTextFromImage(imgFile);
          if (res.fullText.trim().isNotEmpty) {
            ocrTexts.add(res.fullText.trim());
          }
        } catch (_) {}
      }
      final combinedOcr = ocrTexts.join('\n\n').trim();

      final document = Document(
        id: docId,
        title: outputTitle.trim().isNotEmpty ? outputTitle.trim() : 'Images Document',
        pdfPath: genResult.filePath!,
        thumbnailPath: genResult.thumbnailPath,
        folderId: folderId,
        fileSize: genResult.fileSizeBytes,
        metadata: PDFMetadata(pageCount: genResult.pageCount),
        compressionPreset: preset,
        extractedOcrText: combinedOcr.isNotEmpty ? combinedOcr : null,
        ocrStatus: combinedOcr.isNotEmpty ? OcrStatus.completed : OcrStatus.none,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _database.insertDocument(userId, document);
      await _storageManager.cleanupTempDirectory(userId);

      return PdfToolResult.success(
        document: document,
        pageCount: genResult.pageCount,
        outputSizeBytes: genResult.fileSizeBytes,
        summaryMessage: 'Created PDF with ${imageFiles.length} image pages.',
      );
    } catch (e) {
      await _storageManager.deleteDocumentDirectory(userId, docId);
      return PdfToolResult.failure(e.toString());
    }
  }

  @override
  Future<PdfToolResult> pdfToImages({
    required String userId,
    required File sourcePdf,
    required List<int> pageIndices,
    bool isPng = false,
    int dpi = 200,
    ProgressCallback? onProgress,
  }) async {
    final userDir = await _storageManager.getUserDirectory(userId);
    final exportsDir = Directory(p.join(userDir.path, 'exports', 'images_${const Uuid().v4().substring(0, 8)}'));
    await exportsDir.create(recursive: true);

    try {
      final imageFiles = await _pdfToImagesService.convertPdfToImages(
        sourcePdf: sourcePdf,
        outputDirectory: exportsDir,
        pageIndices: pageIndices,
        isPng: isPng,
        dpi: dpi,
        onProgress: onProgress,
      );

      final paths = imageFiles.map((f) => f.path).toList();
      return PdfToolResult.success(
        generatedFilePaths: paths,
        pageCount: paths.length,
        summaryMessage: 'Exported ${paths.length} page image(s) to ${isPng ? 'PNG' : 'JPG'}.',
      );
    } catch (e) {
      return PdfToolResult.failure(e.toString());
    }
  }

  @override
  Future<PdfToolResult> protectPdf({
    required String userId,
    required File sourcePdf,
    required String password,
    String? outputTitle,
    String? folderId,
    ProgressCallback? onProgress,
  }) async {
    final tempDir = await _storageManager.getUserTempDirectory(userId);
    final tempFile = File(p.join(tempDir.path, 'protected_${const Uuid().v4().substring(0, 8)}.pdf'));

    try {
      await _protectionService.protectPdf(
        sourcePdf: sourcePdf,
        targetFile: tempFile,
        password: password,
        onProgress: onProgress,
      );

      final title = outputTitle ?? '${p.basenameWithoutExtension(sourcePdf.path)} (Protected)';
      final doc = await _savePdfAsDocument(
        userId: userId,
        tempPdfFile: tempFile,
        title: title,
        folderId: folderId,
      );

      return PdfToolResult.success(
        document: doc,
        pageCount: doc.pageCount,
        outputSizeBytes: doc.fileSize,
        summaryMessage: 'Document encrypted with AES-256 password protection.',
      );
    } catch (e) {
      if (await tempFile.exists()) await tempFile.delete();
      return PdfToolResult.failure(e.toString());
    }
  }

  @override
  Future<PdfToolResult> watermarkPdf({
    required String userId,
    required File sourcePdf,
    required WatermarkConfig config,
    String? outputTitle,
    String? folderId,
    ProgressCallback? onProgress,
  }) async {
    final tempDir = await _storageManager.getUserTempDirectory(userId);
    final tempFile = File(p.join(tempDir.path, 'watermarked_${const Uuid().v4().substring(0, 8)}.pdf'));

    try {
      await _watermarkService.addWatermark(
        sourcePdf: sourcePdf,
        targetFile: tempFile,
        config: config,
        onProgress: onProgress,
      );

      final title = outputTitle ?? '${p.basenameWithoutExtension(sourcePdf.path)} (Watermarked)';
      final doc = await _savePdfAsDocument(
        userId: userId,
        tempPdfFile: tempFile,
        title: title,
        folderId: folderId,
      );

      return PdfToolResult.success(
        document: doc,
        pageCount: doc.pageCount,
        outputSizeBytes: doc.fileSize,
        summaryMessage: 'Watermark applied successfully.',
      );
    } catch (e) {
      if (await tempFile.exists()) await tempFile.delete();
      return PdfToolResult.failure(e.toString());
    }
  }

  @override
  Future<PdfMetadataEditRequest> readPdfMetadata(File sourcePdf) async {
    return _metadataService.readMetadata(sourcePdf);
  }

  @override
  Future<PdfToolResult> updatePdfMetadata({
    required String userId,
    required File sourcePdf,
    required PdfMetadataEditRequest metadata,
    String? outputTitle,
    String? folderId,
    ProgressCallback? onProgress,
  }) async {
    final tempDir = await _storageManager.getUserTempDirectory(userId);
    final tempFile = File(p.join(tempDir.path, 'metadata_${const Uuid().v4().substring(0, 8)}.pdf'));

    try {
      await _metadataService.updateMetadata(
        sourcePdf: sourcePdf,
        targetFile: tempFile,
        metadata: metadata,
        onProgress: onProgress,
      );

      final title = metadata.title?.isNotEmpty == true
          ? metadata.title!
          : (outputTitle ?? p.basenameWithoutExtension(sourcePdf.path));

      final doc = await _savePdfAsDocument(
        userId: userId,
        tempPdfFile: tempFile,
        title: title,
        folderId: folderId,
      );

      return PdfToolResult.success(
        document: doc,
        pageCount: doc.pageCount,
        outputSizeBytes: doc.fileSize,
        summaryMessage: 'Document metadata updated successfully.',
      );
    } catch (e) {
      if (await tempFile.exists()) await tempFile.delete();
      return PdfToolResult.failure(e.toString());
    }
  }

  @override
  Future<PdfToolResult> flattenPdf({
    required String userId,
    required File sourcePdf,
    String? outputTitle,
    String? folderId,
    ProgressCallback? onProgress,
  }) async {
    final tempDir = await _storageManager.getUserTempDirectory(userId);
    final tempFile = File(p.join(tempDir.path, 'flattened_${const Uuid().v4().substring(0, 8)}.pdf'));

    try {
      await _flattenService.flattenPdf(
        sourcePdf: sourcePdf,
        targetFile: tempFile,
        onProgress: onProgress,
      );

      final title = outputTitle ?? '${p.basenameWithoutExtension(sourcePdf.path)} (Flattened)';
      final doc = await _savePdfAsDocument(
        userId: userId,
        tempPdfFile: tempFile,
        title: title,
        folderId: folderId,
      );

      return PdfToolResult.success(
        document: doc,
        pageCount: doc.pageCount,
        outputSizeBytes: doc.fileSize,
        summaryMessage: 'Interactive elements and annotations flattened.',
      );
    } catch (e) {
      if (await tempFile.exists()) await tempFile.delete();
      return PdfToolResult.failure(e.toString());
    }
  }
}
