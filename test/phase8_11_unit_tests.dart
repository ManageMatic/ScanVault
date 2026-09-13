import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scanvault/features/annotation/domain/models/annotation_model.dart';
import 'package:scanvault/features/annotation/domain/models/digital_signature_model.dart';
import 'package:scanvault/core/storage/storage_manager_service.dart';

void main() {
  group('Phase 8 — Annotation & Signature Models', () {
    test('Pen Annotation normalized coordinates and serialization check', () {
      final points = [
        const NormalizedPoint(0.1, 0.1),
        const NormalizedPoint(0.2, 0.2),
        const NormalizedPoint(0.3, 0.3),
      ];

      final annotation = AnnotationModel(
        id: 'pen_1',
        pageIndex: 0,
        type: AnnotationType.pen,
        colorValue: 0xFF00685F,
        strokeWidth: 3.0,
        points: points,
        createdAt: DateTime.now(),
      );

      expect(annotation.type, AnnotationType.pen);
      expect(annotation.points.length, 3);
      expect(annotation.pageIndex, 0);

      // Verify coordinate transformation to A4 points (595.28 x 841.89)
      final p1 = annotation.points.first;
      expect(p1.x * 595.28, closeTo(59.528, 0.01));
      expect(p1.y * 841.89, closeTo(84.189, 0.01));

      final json = annotation.toJson();
      final restored = AnnotationModel.fromJson(json);
      expect(restored.id, annotation.id);
      expect(restored.points.length, 3);
      expect(restored.colorValue, 0xFF00685F);
    });

    test('Highlighter annotation semi-transparent opacity preservation', () {
      final annotation = AnnotationModel(
        id: 'hl_1',
        pageIndex: 1,
        type: AnnotationType.highlighter,
        colorValue: 0xFFFFEB3B,
        opacity: 0.4,
        strokeWidth: 15.0,
        points: const [NormalizedPoint(0.1, 0.5), NormalizedPoint(0.8, 0.5)],
        createdAt: DateTime.now(),
      );

      expect(annotation.type, AnnotationType.highlighter);
      expect(annotation.strokeWidth, 15.0);
      expect(annotation.opacity, 0.4);
    });

    test('Shape Annotation (Rectangle, Circle, Arrow) start/end points', () {
      final rectAnnotation = AnnotationModel(
        id: 'rect_1',
        pageIndex: 0,
        type: AnnotationType.rectangle,
        colorValue: 0xFFE53935,
        startPoint: const NormalizedPoint(0.2, 0.3),
        endPoint: const NormalizedPoint(0.6, 0.5),
        createdAt: DateTime.now(),
      );

      expect(rectAnnotation.startPoint, isNotNull);
      expect(rectAnnotation.startPoint!.x, 0.2);
      expect(rectAnnotation.startPoint!.y, 0.3);
      expect(rectAnnotation.endPoint!.x, 0.6);
      expect(rectAnnotation.endPoint!.y, 0.5);
    });

    test('Digital Signature Model serialization and roundtrip', () {
      final now = DateTime.now();
      final sig = DigitalSignature(
        id: 'sig_101',
        title: 'Primary Executive Signature',
        imagePath: '/data/user/0/com.scanvault/files/signatures/sig_101.png',
        createdAt: now,
      );

      final json = sig.toJson();
      expect(json['id'], 'sig_101');
      expect(json['title'], 'Primary Executive Signature');
      expect(json['imagePath'], contains('sig_101.png'));

      final restored = DigitalSignature.fromJson(json);
      expect(restored.id, sig.id);
      expect(restored.title, sig.title);
      expect(restored.imagePath, equals(sig.imagePath));
      expect(restored.createdAt.millisecondsSinceEpoch, sig.createdAt.millisecondsSinceEpoch);
    });
  });

  group('Phase 10 — Vault Archive & Backup Packaging', () {
    test('Offline .svault (ZIP) manifest serialization and decoding', () {
      final manifest = {
        'version': 1,
        'app': 'ScanVault',
        'userId': 'usr_test_99',
        'exportedAt': DateTime.now().toIso8601String(),
        'folders': [
          {
            'id': 'folder_work',
            'name': 'Work & Taxes',
            'colorHex': '#F59E0B',
            'iconName': 'work',
            'createdAt': 1700000000000,
            'updatedAt': 1700000000000,
          }
        ],
        'documents': [
          {
            'id': 'doc_001',
            'title': 'W2_Form_2025',
            'folderId': 'folder_work',
            'fileSize': 10240,
            'pageCount': 2,
            'createdAt': 1700000000000,
            'updatedAt': 1700000000000,
            'ocrStatus': 'completed',
            'extractedText': 'W-2 Wage and Tax Statement 2025',
            'isFavorite': true,
            'isLocked': false,
            'compressionPreset': 'balanced',
            'pdfArchiveName': 'documents/doc_001.pdf',
          }
        ]
      };

      final manifestBytes = utf8.encode(jsonEncode(manifest));
      final archive = Archive();
      archive.addFile(ArchiveFile('manifest.json', manifestBytes.length, manifestBytes));

      // Add dummy PDF content
      final dummyPdfBytes = utf8.encode('%PDF-1.4 Mock Encrypted Document Body');
      archive.addFile(ArchiveFile('documents/doc_001.pdf', dummyPdfBytes.length, dummyPdfBytes));

      final encoder = ZipEncoder();
      final zipped = encoder.encode(archive);
      expect(zipped.length, greaterThan(0));

      // Decode and verify
      final decoder = ZipDecoder();
      final decodedArchive = decoder.decodeBytes(zipped);
      final decodedManifestFile = decodedArchive.findFile('manifest.json');
      expect(decodedManifestFile, isNotNull);

      final decodedJson = jsonDecode(utf8.decode(decodedManifestFile!.content as List<int>)) as Map<String, dynamic>;
      expect(decodedJson['app'], 'ScanVault');
      expect(decodedJson['userId'], 'usr_test_99');

      final docs = decodedJson['documents'] as List<dynamic>;
      expect(docs.length, 1);
      expect(docs.first['title'], 'W2_Form_2025');
      expect(docs.first['extractedText'], 'W-2 Wage and Tax Statement 2025');

      final decodedPdfFile = decodedArchive.findFile('documents/doc_001.pdf');
      expect(decodedPdfFile, isNotNull);
      expect(utf8.decode(decodedPdfFile!.content as List<int>), contains('%PDF-1.4'));
    });
  });

  group('Phase 11 — Storage Manager Metrics Calculation', () {
    test('UserStorageMetrics totals calculation', () {
      const metrics = UserStorageMetrics(
        totalDocumentBytes: 5000000, // 5 MB
        totalThumbnailBytes: 200000, // 200 KB
        totalTempBytes: 300000,     // 300 KB
        totalSignatureBytes: 50000, // 50 KB
        totalBackupBytes: 2000000,  // 2 MB
        documentCount: 15,
        largestDocumentBytes: 1500000,
      );

      expect(metrics.totalUsedBytes, equals(7550000));
      expect(metrics.documentCount, 15);
      expect(metrics.largestDocumentBytes, 1500000);
    });
  });
}
