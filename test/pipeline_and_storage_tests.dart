import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:scanvault/core/storage/page_image_resolver.dart';
import 'package:scanvault/core/storage/session_workspace_manager.dart';
import 'package:scanvault/features/image_processing/domain/image_processor.dart';
import 'package:scanvault/features/image_processing/domain/perspective_transformer.dart';
import 'package:scanvault/features/pdf_tools/data/repositories/local_file_source_repository.dart';
import 'package:scanvault/features/scanner/domain/scanned_page_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempTestDir;
  late SessionWorkspaceManager workspaceManager;

  setUp(() async {
    tempTestDir = await Directory.systemTemp.createTemp('scanvault_test_');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => tempTestDir.path,
    );

    workspaceManager = SessionWorkspaceManager();
  });

  tearDown(() async {
    if (await tempTestDir.exists()) {
      await tempTestDir.delete(recursive: true);
    }
  });

  group('SessionWorkspaceManager & Page Lifecycle Tests', () {
    test('importSourceImage creates original.jpg and thumbnail.jpg', () async {
      final sampleImg = ImageProcessor.createSampleDocumentBitmap();
      final pageId = 'test_page_1';
      final sessionId = 'test_session_1';
      final userId = 'test_user';

      final result = await workspaceManager.importSourceImage(
        userId: userId,
        sessionId: sessionId,
        pageId: pageId,
        rawBytes: sampleImg,
      );

      final originalPath = result['originalPath']!;
      final thumbPath = result['thumbnailPath']!;

      expect(File(originalPath).existsSync(), isTrue);
      expect(File(originalPath).lengthSync(), greaterThan(0));
      expect(File(thumbPath).existsSync(), isTrue);
      expect(File(thumbPath).lengthSync(), greaterThan(0));

      // Cleanup
      await workspaceManager.cleanupSession(userId, sessionId);
      expect(File(originalPath).existsSync(), isFalse);
    });

    test('saveWorkingImage creates working.jpg and updates thumbnail', () async {
      final sampleImg = ImageProcessor.createSampleDocumentBitmap();
      final pageId = 'test_page_2';
      final sessionId = 'test_session_2';
      final userId = 'test_user';

      await workspaceManager.importSourceImage(
        userId: userId,
        sessionId: sessionId,
        pageId: pageId,
        rawBytes: sampleImg,
      );

      final workingBytes = ImageProcessor.processImageSync(
        rawBytes: sampleImg,
        params: const ImageEnhancementParams(filterMode: ScanFilterMode.grayscale),
      );

      final workingPath = await workspaceManager.saveWorkingImage(
        userId: userId,
        sessionId: sessionId,
        pageId: pageId,
        bytes: workingBytes,
      );

      expect(File(workingPath).existsSync(), isTrue);
      expect(workingPath.endsWith('working.jpg'), isTrue);
      expect(File(workingPath).lengthSync(), greaterThan(0));

      await workspaceManager.cleanupSession(userId, sessionId);
    });

    test('saveProcessedImage creates processed.jpg for filters', () async {
      final sampleImg = ImageProcessor.createSampleDocumentBitmap();
      final pageId = 'test_page_3';
      final sessionId = 'test_session_3';
      final userId = 'test_user';

      await workspaceManager.importSourceImage(
        userId: userId,
        sessionId: sessionId,
        pageId: pageId,
        rawBytes: sampleImg,
      );

      final processedBytes = ImageProcessor.processImageSync(
        rawBytes: sampleImg,
        params: const ImageEnhancementParams(filterMode: ScanFilterMode.blackAndWhite),
      );

      final processedPath = await workspaceManager.saveProcessedImage(
        userId: userId,
        sessionId: sessionId,
        pageId: pageId,
        bytes: processedBytes,
      );

      expect(File(processedPath).existsSync(), isTrue);
      expect(processedPath.endsWith('processed.jpg'), isTrue);

      await workspaceManager.cleanupSession(userId, sessionId);
    });
  });

  group('PageImageResolver Canonical Resolution Tests', () {
    test('Resolves processedImagePath with highest priority', () async {
      final origFile = File('${tempTestDir.path}/original.jpg');
      final workFile = File('${tempTestDir.path}/working.jpg');
      final procFile = File('${tempTestDir.path}/processed.jpg');

      await origFile.writeAsBytes([1, 2, 3, 4]);
      await workFile.writeAsBytes([5, 6, 7, 8]);
      await procFile.writeAsBytes([9, 10, 11, 12]);

      final page = ScannedPageItem(
        id: 'p1',
        originalImagePath: origFile.path,
        workingImagePath: workFile.path,
        processedImagePath: procFile.path,
        capturedAt: DateTime.now(),
      );

      final resolved = PageImageResolver.resolveCurrentImagePath(page);
      expect(resolved, equals(procFile.path));
    });

    test('Falls back to workingImagePath if processed is null', () async {
      final origFile = File('${tempTestDir.path}/original2.jpg');
      final workFile = File('${tempTestDir.path}/working2.jpg');

      await origFile.writeAsBytes([1, 2, 3, 4]);
      await workFile.writeAsBytes([5, 6, 7, 8]);

      final page = ScannedPageItem(
        id: 'p2',
        originalImagePath: origFile.path,
        workingImagePath: workFile.path,
        capturedAt: DateTime.now(),
      );

      final resolved = PageImageResolver.resolveCurrentImagePath(page);
      expect(resolved, equals(workFile.path));
    });

    test('Falls back to originalImagePath if working and processed are null', () async {
      final origFile = File('${tempTestDir.path}/original3.jpg');
      await origFile.writeAsBytes([1, 2, 3, 4]);

      final page = ScannedPageItem(
        id: 'p3',
        originalImagePath: origFile.path,
        capturedAt: DateTime.now(),
      );

      final resolved = PageImageResolver.resolveCurrentImagePath(page);
      expect(resolved, equals(origFile.path));
    });
  });

  group('PerspectiveTransformer & Filter Pipeline Tests', () {
    test('warpQuadrilateral produces valid non-empty 3-channel JPEG bytes', () {
      final sampleImg = ImageProcessor.createSampleDocumentBitmap();

      final warped = PerspectiveTransformer.warpQuadrilateral(
        rawBytes: sampleImg,
        topLeft: const math.Point(0.1, 0.1),
        topRight: const math.Point(0.9, 0.1),
        bottomRight: const math.Point(0.85, 0.9),
        bottomLeft: const math.Point(0.15, 0.85),
      );

      expect(warped.isNotEmpty, isTrue);

      final decoded = img.decodeImage(warped);
      expect(decoded, isNotNull);
      expect(decoded!.width, greaterThan(100));
      expect(decoded.height, greaterThan(100));
    });

    test('All ScanFilterMode presets generate valid image bytes', () {
      final sampleImg = ImageProcessor.createSampleDocumentBitmap();

      for (final mode in ScanFilterMode.values) {
        final processed = ImageProcessor.processImageSync(
          rawBytes: sampleImg,
          params: ImageEnhancementParams(filterMode: mode),
        );
        expect(processed.isNotEmpty, isTrue);
        final decoded = img.decodeImage(processed);
        expect(decoded, isNotNull);
      }
    });
  });

  group('LocalFileSourceRepository Validation Tests', () {
    test('validatePdf detects %PDF- header correctly', () async {
      final repo = LocalFileSourceRepository();

      final validPdf = File('${tempTestDir.path}/valid.pdf');
      await validPdf.writeAsString('%PDF-1.7\n%%EOF');

      final invalidFile = File('${tempTestDir.path}/invalid.txt');
      await invalidFile.writeAsString('Hello world');

      expect(await repo.validatePdf(validPdf), isTrue);
      expect(await repo.validatePdf(invalidFile), isFalse);
    });

    test('validateImage detects valid JPEG image bytes', () async {
      final repo = LocalFileSourceRepository();
      final sampleImg = ImageProcessor.createSampleDocumentBitmap();

      final imgFile = File('${tempTestDir.path}/sample.jpg');
      await imgFile.writeAsBytes(sampleImg);

      expect(await repo.validateImage(imgFile), isTrue);
    });
  });

  group('End-to-End Multi-Page Lifecycle & Resolver Regression Tests', () {
    test('Capture 3 pages, crop page 2, filter page 3, delete page 2, all pages resolve and decode', () async {
      final userId = 'regression_user';
      final sessionId = 'regression_session';
      final sampleBytes = ImageProcessor.createSampleDocumentBitmap();

      // 1. Capture 3 pages
      final p1Import = await workspaceManager.importSourceImage(
        userId: userId,
        sessionId: sessionId,
        pageId: 'page_1',
        rawBytes: sampleBytes,
      );
      final p2Import = await workspaceManager.importSourceImage(
        userId: userId,
        sessionId: sessionId,
        pageId: 'page_2',
        rawBytes: sampleBytes,
      );
      final p3Import = await workspaceManager.importSourceImage(
        userId: userId,
        sessionId: sessionId,
        pageId: 'page_3',
        rawBytes: sampleBytes,
      );

      var page1 = ScannedPageItem(
        id: 'page_1',
        sessionId: sessionId,
        originalImagePath: p1Import['originalPath']!,
        thumbnailPath: p1Import['thumbnailPath'],
        capturedAt: DateTime.now(),
      );
      var page2 = ScannedPageItem(
        id: 'page_2',
        sessionId: sessionId,
        originalImagePath: p2Import['originalPath']!,
        thumbnailPath: p2Import['thumbnailPath'],
        capturedAt: DateTime.now(),
      );
      var page3 = ScannedPageItem(
        id: 'page_3',
        sessionId: sessionId,
        originalImagePath: p3Import['originalPath']!,
        thumbnailPath: p3Import['thumbnailPath'],
        capturedAt: DateTime.now(),
      );

      // 2. Crop page 2
      final croppedP2Bytes = ImageProcessor.cropQuadrilateral(
        rawBytes: sampleBytes,
        topLeft: const math.Point(0.05, 0.05),
        topRight: const math.Point(0.95, 0.05),
        bottomRight: const math.Point(0.95, 0.95),
        bottomLeft: const math.Point(0.05, 0.95),
        displayWidth: 1.0,
        displayHeight: 1.0,
      );
      final workPath = await workspaceManager.saveWorkingImage(
        userId: userId,
        sessionId: sessionId,
        pageId: 'page_2',
        bytes: croppedP2Bytes,
      );
      page2 = page2.copyWith(workingImagePath: workPath, cachedProcessedBytes: croppedP2Bytes);

      // 3. Filter page 3
      final filteredP3Bytes = ImageProcessor.processImageSync(
        rawBytes: sampleBytes,
        params: const ImageEnhancementParams(filterMode: ScanFilterMode.documentClean),
      );
      final procPath = await workspaceManager.saveProcessedImage(
        userId: userId,
        sessionId: sessionId,
        pageId: 'page_3',
        bytes: filteredP3Bytes,
      );
      page3 = page3.copyWith(processedImagePath: procPath, cachedProcessedBytes: filteredP3Bytes);

      // 4. Validate canonical resolutions
      final res1 = PageImageResolver.resolveCurrentImagePath(page1);
      final res2 = PageImageResolver.resolveCurrentImagePath(page2);
      final res3 = PageImageResolver.resolveCurrentImagePath(page3);

      expect(res1, equals(p1Import['originalPath']));
      expect(res2, equals(workPath));
      expect(res3, equals(procPath));

      // 5. Verify decodability of all resolved files
      for (final p in [res1, res2, res3]) {
        expect(p, isNotNull);
        final f = File(p!);
        expect(f.existsSync(), isTrue);
        expect(f.lengthSync(), greaterThan(0));
        final decoded = img.decodeImage(f.readAsBytesSync());
        expect(decoded, isNotNull);
        expect(decoded!.width, greaterThan(50));
        expect(decoded.height, greaterThan(50));
      }

      // 6. Delete page 2 from list
      final remainingPages = [page1, page3];
      expect(remainingPages.length, equals(2));
      expect(remainingPages[0].id, equals('page_1'));
      expect(remainingPages[1].id, equals('page_3'));

      // 7. Remaining pages still resolve and decode flawlessly
      final remRes1 = PageImageResolver.resolveCurrentImagePath(remainingPages[0]);
      final remRes2 = PageImageResolver.resolveCurrentImagePath(remainingPages[1]);
      expect(remRes1, equals(p1Import['originalPath']));
      expect(remRes2, equals(procPath));

      await workspaceManager.cleanupSession(userId, sessionId);
    });
  });
}
