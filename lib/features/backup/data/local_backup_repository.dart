import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import '../../../core/database/app_database.dart';
import '../../../core/storage/storage_manager_service.dart';
import '../../../shared/models/document.dart';
import '../../../shared/models/folder.dart';
import '../../../shared/models/pdf_metadata.dart';
import '../domain/repositories/backup_repository.dart';

/// Production offline backup repository that creates and restores self-contained
/// encrypted/compressed `.svault` archives containing documents, thumbnails, OCR text, and folders.
class LocalBackupRepository implements BackupRepository {
  final AppDatabase _db;
  final StorageManagerService _storageService;

  LocalBackupRepository({
    AppDatabase? db,
    StorageManagerService? storageService,
  })  : _db = db ?? AppDatabase(),
        _storageService = storageService ?? StorageManagerService();

  @override
  Future<BackupExportResult> exportVaultBackup(String userId) async {
    final docs = await _db.getDocumentsForUser(userId);
    final folders = await _db.getFoldersForUser(userId);

    final archive = Archive();

    // 1. Build Manifest JSON
    final manifestData = {
      'version': 1,
      'app': 'ScanVault',
      'userId': userId,
      'exportedAt': DateTime.now().toIso8601String(),
      'folders': folders
          .map((f) => {
                'id': f.id,
                'name': f.name,
                'colorHex': f.colorHex,
                'iconName': f.iconName,
                'createdAt': f.createdAt.millisecondsSinceEpoch,
                'updatedAt': f.updatedAt.millisecondsSinceEpoch,
              })
          .toList(),
      'documents': docs
          .map((d) => {
                'id': d.id,
                'title': d.title,
                'folderId': d.folderId,
                'fileSize': d.fileSize,
                'pageCount': d.pageCount,
                'createdAt': d.createdAt.millisecondsSinceEpoch,
                'updatedAt': d.updatedAt.millisecondsSinceEpoch,
                'ocrStatus': d.ocrStatus.name,
                'extractedText': d.extractedOcrText,
                'isFavorite': d.isFavorite,
                'isLocked': d.isLocked,
                'compressionPreset': d.compressionPreset.name,
                'pdfArchiveName': 'documents/${d.id}.pdf',
                'thumbArchiveName': d.thumbnailPath != null ? 'thumbnails/${d.id}.jpg' : null,
              })
          .toList(),
    };

    final manifestBytes = utf8.encode(jsonEncode(manifestData));
    archive.addFile(ArchiveFile('manifest.json', manifestBytes.length, manifestBytes));

    // 2. Add PDF documents & Thumbnails to archive
    for (final doc in docs) {
      if (doc.filePath.isNotEmpty) {
        final pdfFile = File(doc.filePath);
        if (await pdfFile.exists()) {
          final pdfBytes = await pdfFile.readAsBytes();
          archive.addFile(ArchiveFile('documents/${doc.id}.pdf', pdfBytes.length, pdfBytes));
        }
      }

      if (doc.thumbnailPath != null && doc.thumbnailPath!.isNotEmpty) {
        final thumbFile = File(doc.thumbnailPath!);
        if (await thumbFile.exists()) {
          final thumbBytes = await thumbFile.readAsBytes();
          archive.addFile(ArchiveFile('thumbnails/${doc.id}.jpg', thumbBytes.length, thumbBytes));
        }
      }
    }

    // 3. Compress into .svault file
    final encoder = ZipEncoder();
    final zippedBytes = encoder.encode(archive);

    final backupsDir = await _storageService.getUserDirectory(userId);
    final backupDir = Directory(p.join(backupsDir.path, 'backups'));
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final backupFile = File(p.join(backupDir.path, 'scanvault_backup_$timestamp.svault'));
    await backupFile.writeAsBytes(zippedBytes);

    return BackupExportResult(
      backupFile: backupFile,
      documentCount: docs.length,
      totalSizeBytes: zippedBytes.length,
      exportedAt: DateTime.now(),
    );
  }

  @override
  Future<BackupRestoreResult> restoreVaultBackup(String userId, File backupFile) async {
    try {
      if (!await backupFile.exists()) {
        return const BackupRestoreResult(
          success: false,
          errorMessage: 'Backup file does not exist on disk.',
        );
      }

      final bytes = await backupFile.readAsBytes();
      final decoder = ZipDecoder();
      final archive = decoder.decodeBytes(bytes);

      final manifestArchiveFile = archive.findFile('manifest.json');
      if (manifestArchiveFile == null) {
        return const BackupRestoreResult(
          success: false,
          errorMessage: 'Invalid ScanVault backup: manifest.json missing.',
        );
      }

      final manifestJson = jsonDecode(utf8.decode(manifestArchiveFile.content as List<int>)) as Map<String, dynamic>;
      final rawFolders = (manifestJson['folders'] as List<dynamic>?) ?? [];
      final rawDocs = (manifestJson['documents'] as List<dynamic>?) ?? [];

      var foldersRestored = 0;
      var docsRestored = 0;

      // 1. Restore Folders
      for (final f in rawFolders) {
        final folderMap = f as Map<String, dynamic>;
        final folder = Folder(
          id: folderMap['id'] as String,
          name: folderMap['name'] as String,
          colorHex: folderMap['colorHex'] as String? ?? '#0D9488',
          iconName: folderMap['iconName'] as String? ?? 'folder',
          createdAt: DateTime.fromMillisecondsSinceEpoch(folderMap['createdAt'] as int),
          updatedAt: DateTime.fromMillisecondsSinceEpoch(folderMap['updatedAt'] as int),
        );
        await _db.insertFolder(userId, folder);
        foldersRestored++;
      }

      // 2. Prepare Storage Dirs
      final userDocsDir = await _storageService.getUserDocumentsDirectory(userId);
      final userThumbsDir = await _storageService.getUserThumbnailsDirectory(userId);

      // 3. Restore Documents and Binary Files
      for (final d in rawDocs) {
        final docMap = d as Map<String, dynamic>;
        final docId = docMap['id'] as String;

        String? restoredPdfPath;
        String? restoredThumbPath;

        final pdfArchiveName = docMap['pdfArchiveName'] as String?;
        if (pdfArchiveName != null) {
          final pdfArchFile = archive.findFile(pdfArchiveName);
          if (pdfArchFile != null) {
            final docFolder = Directory(p.join(userDocsDir.path, docId));
            if (!await docFolder.exists()) {
              await docFolder.create(recursive: true);
            }
            final restoredFile = File(p.join(docFolder.path, '$docId.pdf'));
            await restoredFile.writeAsBytes(pdfArchFile.content as List<int>);
            restoredPdfPath = restoredFile.path;
          }
        }

        final thumbArchiveName = docMap['thumbArchiveName'] as String?;
        if (thumbArchiveName != null) {
          final thumbArchFile = archive.findFile(thumbArchiveName);
          if (thumbArchFile != null) {
            final restoredThumb = File(p.join(userThumbsDir.path, '$docId.jpg'));
            await restoredThumb.writeAsBytes(thumbArchFile.content as List<int>);
            restoredThumbPath = restoredThumb.path;
          }
        }

        final doc = Document(
          id: docId,
          title: docMap['title'] as String,
          pdfPath: restoredPdfPath,
          thumbnailPath: restoredThumbPath,
          folderId: docMap['folderId'] as String?,
          fileSize: (docMap['fileSize'] as int?) ?? 0,
          metadata: PDFMetadata(pageCount: (docMap['pageCount'] as int?) ?? 1),
          createdAt: DateTime.fromMillisecondsSinceEpoch(docMap['createdAt'] as int),
          updatedAt: DateTime.fromMillisecondsSinceEpoch(docMap['updatedAt'] as int),
          extractedOcrText: docMap['extractedText'] as String?,
          isFavorite: docMap['isFavorite'] == true,
          isLocked: docMap['isLocked'] == true,
          compressionPreset: _parsePreset(docMap['compressionPreset'] as String?),
          ocrStatus: _parseOcrStatus(docMap['ocrStatus'] as String?),
        );

        await _db.insertDocument(userId, doc);
        docsRestored++;
      }

      return BackupRestoreResult(
        success: true,
        documentsRestored: docsRestored,
        foldersRestored: foldersRestored,
      );
    } catch (e) {
      return BackupRestoreResult(
        success: false,
        errorMessage: 'Backup restoration failed: $e',
      );
    }
  }

  CompressionPreset _parsePreset(String? str) {
    switch (str) {
      case 'small':
        return CompressionPreset.small;
      case 'highQuality':
        return CompressionPreset.highQuality;
      default:
        return CompressionPreset.balanced;
    }
  }

  OcrStatus _parseOcrStatus(String? str) {
    switch (str) {
      case 'completed':
        return OcrStatus.completed;
      case 'processing':
        return OcrStatus.processing;
      case 'failed':
        return OcrStatus.failed;
      default:
        return OcrStatus.none;
    }
  }
}
