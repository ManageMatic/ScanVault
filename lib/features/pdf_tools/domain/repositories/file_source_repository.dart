import 'dart:io';
import 'package:scanvault/shared/models/document.dart';

class LocalFile {
  final File file;
  final String displayName;
  final int sizeBytes;
  final String? mimeType;

  const LocalFile({
    required this.file,
    required this.displayName,
    required this.sizeBytes,
    this.mimeType,
  });

  String get path => file.path;
}

enum FileSourceType {
  scanVault,
  deviceStorage,
}

abstract class FileSourceRepository {
  /// Pick one or multiple PDFs from device storage (SAF)
  Future<List<File>> pickPdfFromDevice({
    String userId = 'local_user',
    bool allowMultiple = false,
  });

  /// Pick one or multiple images from device storage / gallery
  Future<List<File>> pickImagesFromDevice({
    String userId = 'local_user',
    bool allowMultiple = false,
  });

  /// Get documents from ScanVault SQLite vault
  Future<List<Document>> getScanVaultDocuments(String userId);

  /// Safe import of external file into app temporary workspace with validation
  Future<File> importToWorkspace({
    required String userId,
    required File sourceFile,
    required String subfolder,
  });

  /// Validates if a file is a valid PDF document (checks header %PDF- and parses)
  Future<bool> validatePdf(File file);

  /// Validates if a file is a valid decodable image
  Future<bool> validateImage(File file);
}
