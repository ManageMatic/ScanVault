import 'dart:io';
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../../core/database/app_database.dart';
import '../../../core/storage/storage_manager_service.dart';
import '../../../shared/models/document.dart';
import '../../../shared/models/pdf_metadata.dart';

class DocumentImportExportService {
  final AppDatabase _db;
  final StorageManagerService _storageService;

  DocumentImportExportService({
    AppDatabase? db,
    StorageManagerService? storageService,
  })  : _db = db ?? AppDatabase(),
        _storageService = storageService ?? StorageManagerService();

  /// Prompts user to pick PDF or Image files from external device storage and imports them directly into Vault.
  Future<List<Document>> pickAndImportDocuments(String userId, {String? targetFolderId}) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
    );

    if (result == null || result.files.isEmpty) {
      return [];
    }

    final importedDocs = <Document>[];
    final userDocsDir = await _storageService.getUserDocumentsDirectory(userId);

    for (final pickedFile in result.files) {
      if (pickedFile.path == null) continue;
      final sourceFile = File(pickedFile.path!);
      if (!await sourceFile.exists()) continue;

      final extension = p.extension(sourceFile.path).toLowerCase();
      final docId = 'doc_${DateTime.now().millisecondsSinceEpoch}_${importedDocs.length}';
      final docFolder = Directory(p.join(userDocsDir.path, docId));
      if (!await docFolder.exists()) {
        await docFolder.create(recursive: true);
      }

      String destinationPdfPath;
      int pageCount = 1;

      if (extension == '.pdf') {
        // Direct PDF copy
        destinationPdfPath = p.join(docFolder.path, '$docId.pdf');
        await sourceFile.copy(destinationPdfPath);

        // Determine actual page count via Syncfusion
        try {
          final pdfBytes = await sourceFile.readAsBytes();
          final loadedDoc = PdfDocument(inputBytes: pdfBytes);
          pageCount = loadedDoc.pages.count;
          loadedDoc.dispose();
        } catch (_) {
          pageCount = 1;
        }
      } else {
        // Image imported -> Wrap in a single-page PDF
        destinationPdfPath = p.join(docFolder.path, '$docId.pdf');
        final pdfDoc = PdfDocument();
        final imgBytes = await sourceFile.readAsBytes();
        final pdfBitmap = PdfBitmap(imgBytes);
        
        final page = pdfDoc.pages.add();
        page.graphics.drawImage(
          pdfBitmap,
          ui.Rect.fromLTWH(0, 0, page.getClientSize().width, page.getClientSize().height),
        );

        final outBytes = await pdfDoc.save();
        pdfDoc.dispose();
        await File(destinationPdfPath).writeAsBytes(outBytes);
        pageCount = 1;
      }

      final stat = await File(destinationPdfPath).stat();
      final now = DateTime.now();
      final baseTitle = p.basenameWithoutExtension(pickedFile.name);

      final document = Document(
        id: docId,
        title: baseTitle.isNotEmpty ? baseTitle : 'Imported Document',
        pdfPath: destinationPdfPath,
        folderId: targetFolderId,
        fileSize: stat.size,
        metadata: PDFMetadata(pageCount: pageCount),
        createdAt: now,
        updatedAt: now,
        isFavorite: false,
        isLocked: false,
        compressionPreset: CompressionPreset.balanced,
        ocrStatus: OcrStatus.none,
      );

      await _db.insertDocument(userId, document);
      importedDocs.add(document);
    }

    return importedDocs;
  }

  /// System share sheet for single document
  Future<void> shareDocument(Document document) async {
    if (document.filePath.isEmpty) return;
    final file = File(document.filePath);
    if (!await file.exists()) return;

    await Share.shareXFiles(
      [XFile(file.path, name: '${document.title}.pdf', mimeType: 'application/pdf')],
      subject: document.title,
    );
  }

  /// Batch system share sheet for multiple documents
  Future<void> shareMultipleDocuments(List<Document> documents) async {
    final xFiles = <XFile>[];
    for (final doc in documents) {
      if (doc.filePath.isNotEmpty) {
        final f = File(doc.filePath);
        if (await f.exists()) {
          xFiles.add(XFile(f.path, name: '${doc.title}.pdf', mimeType: 'application/pdf'));
        }
      }
    }

    if (xFiles.isNotEmpty) {
      await Share.shareXFiles(xFiles, subject: 'ScanVault Export');
    }
  }

  /// Sends document to local Wi-Fi / Bluetooth / Cloud printers via system print spooler
  Future<void> printDocument(Document document) async {
    if (document.filePath.isEmpty) return;
    final file = File(document.filePath);
    if (!await file.exists()) return;

    final bytes = await file.readAsBytes();
    await Printing.layoutPdf(
      name: '${document.title}.pdf',
      onLayout: (format) async => bytes,
    );
  }
}
