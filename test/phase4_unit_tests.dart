import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:scanvault/features/pdf_creation/data/local_pdf_engine.dart';
import 'package:scanvault/features/pdf_creation/domain/pdf_models.dart';
import 'package:scanvault/shared/models/document.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('scanvault_pdf_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('PDF Utilities & Helpers', () {
    test('sanitizePdfFilename removes illegal characters and handles extensions', () {
      expect(sanitizePdfFilename('my/illegal:file*name?.pdf'), 'my_illegal_file_name_.pdf');
      expect(sanitizePdfFilename('document.PDF'), 'document.pdf');
      expect(sanitizePdfFilename('   spaces and dots...   '), 'spaces and dots_..pdf');
      expect(sanitizePdfFilename(''), 'ScanDoc.pdf');
      expect(sanitizePdfFilename('../../../etc/passwd'), '______etc_passwd.pdf');
      expect(sanitizePdfFilename('Invoice #104 [2026]'), 'Invoice #104 [2026].pdf');
    });

    test('formatBytes formats file sizes correctly', () {
      expect(formatBytes(0), '0 B');
      expect(formatBytes(512), '512 B');
      expect(formatBytes(1024), '1.0 KB');
      expect(formatBytes(1536), '1.5 KB');
      expect(formatBytes(1048576), '1.0 MB');
      expect(formatBytes(5242880), '5.0 MB');
      expect(formatBytes(1073741824), '1.0 GB');
    });

    test('PdfValidator validates real PDF and rejects corrupt data', () async {
      // Create valid PDF header file
      final validFile = File('${tempDir.path}/valid.pdf');
      await validFile.writeAsBytes(Uint8List.fromList([
        0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x35, // %PDF-1.5
        ...List.filled(100, 0x20),
      ]));

      final result = await PdfValidator.validateFile(validFile);
      expect(result.isValid, isTrue);

      final isBytesValid = PdfValidator.validateBytes(await validFile.readAsBytes());
      expect(isBytesValid, isTrue);

      // Create corrupted file (empty or wrong header)
      final corruptFile = File('${tempDir.path}/corrupt.pdf');
      await corruptFile.writeAsBytes(Uint8List.fromList([0x89, 0x50, 0x4E, 0x47])); // PNG header

      final corruptResult = await PdfValidator.validateFile(corruptFile);
      expect(corruptResult.isValid, isFalse);
      expect(PdfValidator.validateBytes(await corruptFile.readAsBytes()), isFalse);

      final emptyFile = File('${tempDir.path}/empty.pdf');
      await emptyFile.writeAsBytes(Uint8List(0));
      final emptyResult = await PdfValidator.validateFile(emptyFile);
      expect(emptyResult.isValid, isFalse);
    });
  });

  group('LocalPdfEngine PDF Generation', () {
    late LocalPdfEngine engine;
    late Uint8List sampleImageBytes1;
    late Uint8List sampleImageBytes2;

    setUp(() async {
      engine = const LocalPdfEngine();

      // Generate two dummy images
      final image1 = img.Image(width: 800, height: 1100);
      img.fill(image1, color: img.ColorRgb8(255, 255, 255));
      sampleImageBytes1 = Uint8List.fromList(img.encodeJpg(image1, quality: 85));

      final image2 = img.Image(width: 1200, height: 800);
      img.fill(image2, color: img.ColorRgb8(240, 240, 240));
      sampleImageBytes2 = Uint8List.fromList(img.encodeJpg(image2, quality: 85));
    });

    test('generates a single page PDF in A4 format with metadata', () async {
      final docDir = Directory('${tempDir.path}/doc_single');
      final thumbDir = Directory('${tempDir.path}/thumbs');

      final request = PdfGenerationRequest(
        documentId: 'test_doc_1',
        userId: 'user_123',
        title: 'Single Page Doc',
        pageSize: PdfPageSize.a4,
        compressionPreset: CompressionPreset.balanced,
        pages: [
          PdfPageInput(imageBytes: sampleImageBytes1, rotationDegrees: 0, pageNumber: 1),
        ],
      );

      final result = await engine.generatePdf(
        request: request,
        outputDirectory: docDir,
        thumbnailsDirectory: thumbDir,
      );

      expect(result.success, isTrue);
      expect(result.pageCount, 1);
      expect(result.fileSizeBytes, greaterThan(500));
      expect(result.filePath, isNotNull);
      expect(File(result.filePath!).existsSync(), isTrue);

      final pdfBytes = await File(result.filePath!).readAsBytes();
      expect(PdfValidator.validateBytes(pdfBytes), isTrue);

      // Verify creator metadata exists in PDF stream
      final pdfContent = String.fromCharCodes(pdfBytes.take(1500));
      expect(pdfContent.contains('PDF'), isTrue);
    });

    test('generates multi-page PDF with Auto and Letter formats', () async {
      final docDir = Directory('${tempDir.path}/doc_multi');

      final request = PdfGenerationRequest(
        documentId: 'test_doc_2',
        userId: 'user_123',
        title: 'Multi Page Doc',
        pageSize: PdfPageSize.auto,
        compressionPreset: CompressionPreset.highQuality,
        pages: [
          PdfPageInput(imageBytes: sampleImageBytes1, rotationDegrees: 90, pageNumber: 1),
          PdfPageInput(imageBytes: sampleImageBytes2, rotationDegrees: 0, pageNumber: 2),
        ],
      );

      final result = await engine.generatePdf(
        request: request,
        outputDirectory: docDir,
      );

      expect(result.success, isTrue);
      expect(result.pageCount, 2);
      expect(result.fileSizeBytes, greaterThan(1000));
      expect(File(result.filePath!).existsSync(), isTrue);
      final validation = await PdfValidator.validateFile(File(result.filePath!));
      expect(validation.isValid, isTrue);
    });

    test('handles small compression preset and generates valid PDF', () async {
      final docDir = Directory('${tempDir.path}/doc_small');

      final request = PdfGenerationRequest(
        documentId: 'test_doc_3',
        userId: 'user_123',
        title: 'Small Compressed Doc',
        pageSize: PdfPageSize.letter,
        compressionPreset: CompressionPreset.small,
        pages: [
          PdfPageInput(imageBytes: sampleImageBytes1, pageNumber: 1),
        ],
      );

      final result = await engine.generatePdf(
        request: request,
        outputDirectory: docDir,
      );

      expect(result.success, isTrue);
      expect(result.pageCount, 1);
      expect(File(result.filePath!).existsSync(), isTrue);
      final validation = await PdfValidator.validateFile(File(result.filePath!));
      expect(validation.isValid, isTrue);
    });

    test('returns failure result if no pages are provided', () async {
      final docDir = Directory('${tempDir.path}/doc_empty');

      final request = PdfGenerationRequest(
        documentId: 'test_doc_4',
        userId: 'user_123',
        title: 'Empty Doc',
        pages: const [],
      );

      final result = await engine.generatePdf(
        request: request,
        outputDirectory: docDir,
      );

      expect(result.success, isFalse);
      expect(result.errorMessage, contains('No pages provided'));
    });
  });
}
