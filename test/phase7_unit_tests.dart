import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart' as pfd;
import 'package:pdf/widgets.dart' as pw;
import 'package:scanvault/features/pdf_creation/domain/pdf_models.dart';
import 'package:scanvault/features/pdf_tools/data/services/images_to_pdf_service.dart';
import 'package:scanvault/features/pdf_tools/data/services/pdf_delete_pages_service.dart';
import 'package:scanvault/features/pdf_tools/data/services/pdf_extract_service.dart';
import 'package:scanvault/features/pdf_tools/data/services/pdf_flatten_service.dart';
import 'package:scanvault/features/pdf_tools/data/services/pdf_merge_service.dart';
import 'package:scanvault/features/pdf_tools/data/services/pdf_metadata_service.dart';
import 'package:scanvault/features/pdf_tools/data/services/pdf_protection_service.dart';
import 'package:scanvault/features/pdf_tools/data/services/pdf_reorder_service.dart';
import 'package:scanvault/features/pdf_tools/data/services/pdf_rotate_service.dart';
import 'package:scanvault/features/pdf_tools/data/services/pdf_split_service.dart';
import 'package:scanvault/features/pdf_tools/data/services/pdf_watermark_service.dart';
import 'package:scanvault/features/pdf_tools/domain/pdf_tools_controller.dart';
import 'package:scanvault/features/pdf_tools/domain/repositories/pdf_tools_repository.dart';
import 'package:scanvault/shared/models/document.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

Future<File> _createSamplePdf(Directory dir, String filename, int pageCount) async {
  final pdfDoc = pw.Document();
  for (var i = 1; i <= pageCount; i++) {
    pdfDoc.addPage(
      pw.Page(
        pageFormat: pfd.PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Text('Page $i of Sample $filename', style: const pw.TextStyle(fontSize: 24)),
          );
        },
      ),
    );
  }
  final bytes = await pdfDoc.save();
  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(bytes, flush: true);
  return file;
}

Uint8List _generateSampleJpegBytes() {
  final image = img.Image(width: 200, height: 200);
  img.fill(image, color: img.ColorRgb8(0, 104, 95));
  return Uint8List.fromList(img.encodeJpg(image, quality: 85));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory testDir;

  setUpAll(() async {
    testDir = await Directory.systemTemp.createTemp('scanvault_phase7_test_');
    SharedPreferences.setMockInitialValues({});

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => testDir.path,
    );
  });

  tearDownAll(() async {
    if (await testDir.exists()) {
      await testDir.delete(recursive: true);
    }
  });

  group('Phase 7: PDF Merge & Split Services', () {
    test('Merge multiple PDFs combining pages in designated order', () async {
      final doc1 = await _createSamplePdf(testDir, 'doc1.pdf', 2);
      final doc2 = await _createSamplePdf(testDir, 'doc2.pdf', 3);

      const mergeService = PdfMergeService();
      final target = File('${testDir.path}/merged_out.pdf');

      final resultFile = await mergeService.mergePdfs(
        sourcePdfs: [doc1, doc2],
        targetFile: target,
      );

      expect(await resultFile.exists(), isTrue);
      final mergedBytes = await resultFile.readAsBytes();
      final sfDoc = sf.PdfDocument(inputBytes: mergedBytes);
      expect(sfDoc.pages.count, equals(5)); // 2 + 3
      sfDoc.dispose();
    });

    test('Split PDF into range chunks correctly', () async {
      final source = await _createSamplePdf(testDir, 'split_source.pdf', 6);
      const splitService = PdfSplitService();
      final outDir = Directory('${testDir.path}/splits');
      await outDir.create(recursive: true);

      final splitFiles = await splitService.splitPdf(
        sourcePdf: source,
        ranges: ['1-3', '4-6'],
        outputDirectory: outDir,
        baseOutputTitle: 'Invoice',
      );

      expect(splitFiles.length, equals(2));

      final chunk1Bytes = await splitFiles[0].readAsBytes();
      final doc1 = sf.PdfDocument(inputBytes: chunk1Bytes);
      expect(doc1.pages.count, equals(3));
      doc1.dispose();

      final chunk2Bytes = await splitFiles[1].readAsBytes();
      final doc2 = sf.PdfDocument(inputBytes: chunk2Bytes);
      expect(doc2.pages.count, equals(3));
      doc2.dispose();
    });
  });

  group('Phase 7: Page Extraction, Deletion & Reordering', () {
    test('Extract selected pages into a new document', () async {
      final source = await _createSamplePdf(testDir, 'extract_src.pdf', 5);
      const extractService = PdfExtractService();
      final target = File('${testDir.path}/extracted_out.pdf');

      final extracted = await extractService.extractPages(
        sourcePdf: source,
        targetFile: target,
        pageIndices: [0, 2, 4], // Pages 1, 3, 5
      );

      expect(await extracted.exists(), isTrue);
      final bytes = await extracted.readAsBytes();
      final doc = sf.PdfDocument(inputBytes: bytes);
      expect(doc.pages.count, equals(3));
      doc.dispose();
    });

    test('Delete specific pages and prevent deleting all pages', () async {
      final source = await _createSamplePdf(testDir, 'del_src.pdf', 4);
      const deleteService = PdfDeletePagesService();
      final target = File('${testDir.path}/deleted_out.pdf');

      final result = await deleteService.deletePages(
        sourcePdf: source,
        targetFile: target,
        pageIndicesToDelete: {1, 3}, // Remove page 2 and 4
      );

      expect(await result.exists(), isTrue);
      final bytes = await result.readAsBytes();
      final doc = sf.PdfDocument(inputBytes: bytes);
      expect(doc.pages.count, equals(2)); // 4 - 2
      doc.dispose();

      // Guard: Attempting to delete all pages should throw
      expect(
        () => deleteService.deletePages(
          sourcePdf: source,
          targetFile: File('${testDir.path}/all_deleted.pdf'),
          pageIndicesToDelete: {0, 1, 2, 3},
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Reorder pages into specified sequence', () async {
      final source = await _createSamplePdf(testDir, 'reorder_src.pdf', 3);
      const reorderService = PdfReorderService();
      final target = File('${testDir.path}/reordered_out.pdf');

      final reordered = await reorderService.reorderPages(
        sourcePdf: source,
        targetFile: target,
        newPageIndexOrder: [2, 0, 1],
      );

      expect(await reordered.exists(), isTrue);
      final bytes = await reordered.readAsBytes();
      final doc = sf.PdfDocument(inputBytes: bytes);
      expect(doc.pages.count, equals(3));
      doc.dispose();
    });
  });

  group('Phase 7: Page Rotation & Watermarking', () {
    test('Rotate selected PDF pages by 90 degrees', () async {
      final source = await _createSamplePdf(testDir, 'rotate_src.pdf', 2);
      const rotateService = PdfRotateService();
      final target = File('${testDir.path}/rotated_out.pdf');

      final rotated = await rotateService.rotatePages(
        sourcePdf: source,
        targetFile: target,
        pageRotations: {0: 90}, // Rotate page 1 only
      );

      expect(await rotated.exists(), isTrue);
      final bytes = await rotated.readAsBytes();
      final doc = sf.PdfDocument(inputBytes: bytes);
      expect(doc.pages[0].rotation, equals(sf.PdfPageRotateAngle.rotateAngle90));
      expect(doc.pages[1].rotation, equals(sf.PdfPageRotateAngle.rotateAngle0));
      doc.dispose();
    });

    test('Apply text watermark stamp to PDF', () async {
      final source = await _createSamplePdf(testDir, 'watermark_src.pdf', 2);
      const watermarkService = PdfWatermarkService();
      final target = File('${testDir.path}/watermarked_out.pdf');

      final watermarked = await watermarkService.addWatermark(
        sourcePdf: source,
        targetFile: target,
        config: const WatermarkConfig(
          text: 'OFFICIAL SCANVAULT',
          fontSize: 32,
          opacity: 0.4,
          position: WatermarkPosition.diagonal,
        ),
      );

      expect(await watermarked.exists(), isTrue);
      final length = await watermarked.length();
      expect(length, greaterThan(0));
    });
  });

  group('Phase 7: Protection, Metadata & Flatten', () {
    test('Encrypt PDF with AES-256 PIN / password', () async {
      final source = await _createSamplePdf(testDir, 'protect_src.pdf', 2);
      const protectService = PdfProtectionService();
      final target = File('${testDir.path}/protected_out.pdf');

      final protected = await protectService.protectPdf(
        sourcePdf: source,
        targetFile: target,
        password: 'SecurePin123!',
      );

      expect(await protected.exists(), isTrue);
      final bytes = await protected.readAsBytes();

      expect(
        () => sf.PdfDocument(inputBytes: bytes),
        throwsA(anything),
      );

      final validDoc = sf.PdfDocument(inputBytes: bytes, password: 'SecurePin123!');
      expect(validDoc.pages.count, equals(2));
      validDoc.dispose();
    });

    test('Read and update PDF metadata', () async {
      final source = await _createSamplePdf(testDir, 'meta_src.pdf', 1);
      const metaService = PdfMetadataService();
      final target = File('${testDir.path}/meta_out.pdf');

      final updated = await metaService.updateMetadata(
        sourcePdf: source,
        targetFile: target,
        metadata: const PdfMetadataEditRequest(
          title: 'Tax Report 2026',
          author: 'Ishan Mahida',
          subject: 'Financial Record',
          keywords: 'tax, invoice, 2026',
          creator: 'ScanVault Studio',
        ),
      );

      expect(await updated.exists(), isTrue);
      final readBack = await metaService.readMetadata(updated);
      expect(readBack.title, equals('Tax Report 2026'));
      expect(readBack.author, equals('Ishan Mahida'));
      expect(readBack.subject, equals('Financial Record'));
      expect(readBack.keywords, equals('tax, invoice, 2026'));
    });

    test('Flatten interactive forms and annotations', () async {
      final source = await _createSamplePdf(testDir, 'flatten_src.pdf', 1);
      const flattenService = PdfFlattenService();
      final target = File('${testDir.path}/flattened_out.pdf');

      final flattened = await flattenService.flattenPdf(
        sourcePdf: source,
        targetFile: target,
      );

      expect(await flattened.exists(), isTrue);
      final bytes = await flattened.readAsBytes();
      final doc = sf.PdfDocument(inputBytes: bytes);
      expect(doc.pages.count, equals(1));
      doc.dispose();
    });
  });

  group('Phase 7: Images → PDF & Controller Registry', () {
    test('Convert images into a valid PDF document', () async {
      final imgFile1 = File('${testDir.path}/img1.jpg');
      await imgFile1.writeAsBytes(_generateSampleJpegBytes());
      final imgFile2 = File('${testDir.path}/img2.jpg');
      await imgFile2.writeAsBytes(_generateSampleJpegBytes());

      final outDir = Directory('${testDir.path}/img_pdf_out');
      await outDir.create(recursive: true);

      const service = ImagesToPdfService();
      final genResult = await service.convertImagesToPdf(
        userId: 'test_user',
        imageFiles: [imgFile1, imgFile2],
        outputTitle: 'My Scans',
        outputDirectory: outDir,
        pageSize: PdfPageSize.a4,
        preset: CompressionPreset.balanced,
      );

      expect(genResult.success, isTrue);
      expect(genResult.pageCount, equals(2));
      expect(genResult.filePath, isNotNull);
      expect(await File(genResult.filePath!).exists(), isTrue);
    });

    test('PdfToolsController filters search queries and records recent tools', () async {
      final controller = PdfToolsController();

      controller.setSearchQuery('merge');
      expect(controller.filteredTools.any((t) => t.type == PdfToolType.merge), isTrue);
      expect(controller.filteredTools.any((t) => t.type == PdfToolType.protectPin), isFalse);

      controller.setSearchQuery('');
      expect(controller.filteredTools.length, equals(13));

      await controller.recordToolUsed('compress');
      expect(controller.recentUsages.any((u) => u.toolId == 'compress'), isTrue);

      await controller.clearRecentTools();
      expect(controller.recentUsages.length, lessThanOrEqualTo(5));
    });
  });
}
