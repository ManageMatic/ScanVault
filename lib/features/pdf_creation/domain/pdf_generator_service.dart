import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../../core/storage/storage_manager_service.dart';
import '../../../shared/models/document.dart';
import '../data/local_pdf_repository.dart';
import 'pdf_models.dart';
import 'pdf_repository.dart';

class PdfCreationParams {
  final String title;
  final List<Uint8List> pageImages;
  final List<int>? pageRotations;
  final CompressionPreset compressionPreset;
  final PdfPageSize pageSize;
  final String? folderId;
  final String? author;

  const PdfCreationParams({
    required this.title,
    required this.pageImages,
    this.pageRotations,
    this.compressionPreset = CompressionPreset.balanced,
    this.pageSize = PdfPageSize.a4,
    this.folderId,
    this.author,
  });
}

/// Service coordinating PDF compilation, optimization, and SQLite metadata registration.
class PdfGeneratorService {
  final PdfRepository _repository;

  PdfGeneratorService(AppDatabase database, StorageManagerService storageManager)
      : _repository = LocalPdfRepository(
          database: database,
          storageManager: storageManager,
        );

  Future<Document> createOptimizedPdf({
    required String userId,
    required PdfCreationParams params,
  }) async {
    final docId = const Uuid().v4();

    final pageInputs = <PdfPageInput>[];
    for (var i = 0; i < params.pageImages.length; i++) {
      final rotation = (params.pageRotations != null && i < params.pageRotations!.length)
          ? params.pageRotations![i]
          : 0;

      pageInputs.add(
        PdfPageInput(
          imageBytes: params.pageImages[i],
          rotationDegrees: rotation,
          pageNumber: i + 1,
        ),
      );
    }

    final request = PdfGenerationRequest(
      documentId: docId,
      userId: userId,
      title: params.title.trim().isNotEmpty ? params.title.trim() : 'Scan Document',
      pages: pageInputs,
      compressionPreset: params.compressionPreset,
      pageSize: params.pageSize,
      folderId: params.folderId,
      author: params.author,
    );

    return _repository.createDocumentPdf(userId: userId, request: request);
  }
}
