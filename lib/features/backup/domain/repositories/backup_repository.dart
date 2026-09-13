import 'dart:io';

class BackupExportResult {
  final File backupFile;
  final int documentCount;
  final int totalSizeBytes;
  final DateTime exportedAt;

  const BackupExportResult({
    required this.backupFile,
    required this.documentCount,
    required this.totalSizeBytes,
    required this.exportedAt,
  });
}

class BackupRestoreResult {
  final bool success;
  final int documentsRestored;
  final int foldersRestored;
  final String? errorMessage;

  const BackupRestoreResult({
    required this.success,
    this.documentsRestored = 0,
    this.foldersRestored = 0,
    this.errorMessage,
  });
}

abstract class BackupRepository {
  Future<BackupExportResult> exportVaultBackup(String userId);
  Future<BackupRestoreResult> restoreVaultBackup(String userId, File backupFile);
}
