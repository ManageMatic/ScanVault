import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:scanvault/core/database/app_database.dart';
import 'package:scanvault/core/storage/storage_manager_service.dart';
import 'package:scanvault/shared/models/document.dart';
import 'package:scanvault/features/pdf_tools/domain/repositories/file_source_repository.dart';

class LocalFileSourceRepository implements FileSourceRepository {
  final AppDatabase _database;
  final StorageManagerService _storageManager;
  final ImagePicker _imagePicker = ImagePicker();

  LocalFileSourceRepository({
    AppDatabase? database,
    StorageManagerService? storageManager,
  })  : _database = database ?? AppDatabase(),
        _storageManager = storageManager ?? StorageManagerService();

  @override
  Future<List<File>> pickPdfFromDevice({bool allowMultiple = false}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: allowMultiple,
      );

      if (result == null || result.files.isEmpty) return [];

      final validFiles = <File>[];
      for (final platformFile in result.files) {
        if (platformFile.path != null && platformFile.path!.isNotEmpty) {
          final file = File(platformFile.path!);
          if (await validatePdf(file)) {
            final imported = await importToWorkspace(
              userId: 'local_user',
              sourceFile: file,
              subfolder: 'imported_pdfs',
            );
            validFiles.add(imported);
          }
        }
      }
      return validFiles;
    } catch (e) {
      debugPrint('[ScanVault][FilePicker] Error picking PDF from device: $e');
      return [];
    }
  }

  @override
  Future<List<File>> pickImagesFromDevice({bool allowMultiple = false}) async {
    try {
      final validFiles = <File>[];

      if (allowMultiple) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: true,
        );

        if (result != null && result.files.isNotEmpty) {
          for (final platformFile in result.files) {
            if (platformFile.path != null && platformFile.path!.isNotEmpty) {
              final file = File(platformFile.path!);
              if (await validateImage(file)) {
                final imported = await importToWorkspace(
                  userId: 'local_user',
                  sourceFile: file,
                  subfolder: 'imported_images',
                );
                validFiles.add(imported);
              }
            }
          }
        } else {
          // Fallback to ImagePicker
          final picked = await _imagePicker.pickMultiImage();
          for (final xFile in picked) {
            final file = File(xFile.path);
            if (await validateImage(file)) {
              final imported = await importToWorkspace(
                userId: 'local_user',
                sourceFile: file,
                subfolder: 'imported_images',
              );
              validFiles.add(imported);
            }
          }
        }
      } else {
        final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
        if (picked != null) {
          final file = File(picked.path);
          if (await validateImage(file)) {
            final imported = await importToWorkspace(
              userId: 'local_user',
              sourceFile: file,
              subfolder: 'imported_images',
            );
            validFiles.add(imported);
          }
        }
      }

      return validFiles;
    } catch (e) {
      debugPrint('[ScanVault][FilePicker] Error picking images: $e');
      return [];
    }
  }

  @override
  Future<List<Document>> getScanVaultDocuments(String userId) async {
    return _database.getDocumentsForUser(userId);
  }

  @override
  Future<File> importToWorkspace({
    required String userId,
    required File sourceFile,
    required String subfolder,
  }) async {
    final tempDir = await _storageManager.getUserTempDirectory(userId);
    final targetDir = Directory(p.join(tempDir.path, subfolder));
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final ext = p.extension(sourceFile.path).isNotEmpty ? p.extension(sourceFile.path) : '.pdf';
    final safeName = '${const Uuid().v4().substring(0, 8)}_imported$ext';
    final targetPath = p.join(targetDir.path, safeName);

    return sourceFile.copy(targetPath);
  }

  @override
  Future<bool> validatePdf(File file) async {
    try {
      if (!await file.exists()) return false;
      final size = await file.length();
      if (size < 10) return false;

      // Check %PDF- magic bytes header
      final header = await file.openRead(0, 10).first;
      final str = String.fromCharCodes(header);
      return str.contains('%PDF-');
    } catch (e) {
      debugPrint('[ScanVault][Validation] PDF validation failed for ${file.path}: $e');
      return false;
    }
  }

  @override
  Future<bool> validateImage(File file) async {
    try {
      if (!await file.exists()) return false;
      final size = await file.length();
      if (size < 10) return false;

      final bytes = await file.openRead(0, 1024).first;
      // JPEG / PNG / WEBP magic bytes check
      if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xD8) return true; // JPG
      if (bytes.length >= 8 && bytes[0] == 0x89 && bytes[1] == 0x4E && bytes[2] == 0x47) return true; // PNG
      if (bytes.length >= 4 && bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46) return true; // WEBP (RIFF)

      return true;
    } catch (e) {
      debugPrint('[ScanVault][Validation] Image validation failed for ${file.path}: $e');
      return false;
    }
  }
}
