import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class UserStorageMetrics {
  final int totalDocumentBytes;
  final int totalThumbnailBytes;
  final int totalTempBytes;
  final int documentCount;
  final int largestDocumentBytes;

  const UserStorageMetrics({
    required this.totalDocumentBytes,
    required this.totalThumbnailBytes,
    required this.totalTempBytes,
    required this.documentCount,
    required this.largestDocumentBytes,
  });

  int get totalUsedBytes => totalDocumentBytes + totalThumbnailBytes + totalTempBytes;
}

/// Service managing user-isolated filesystem paths, files, and disk metrics.
class StorageManagerService {
  Future<Directory> getAppRootDirectory() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final appDir = Directory(p.join(docsDir.path, 'ScanVault'));
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }
    return appDir;
  }

  Future<Directory> getUserDirectory(String userId) async {
    final appDir = await getAppRootDirectory();
    final userDir = Directory(p.join(appDir.path, 'users', userId));
    if (!await userDir.exists()) {
      await userDir.create(recursive: true);
    }
    return userDir;
  }

  Future<Directory> getUserDocumentsDirectory(String userId) async {
    final userDir = await getUserDirectory(userId);
    final docsDir = Directory(p.join(userDir.path, 'documents'));
    if (!await docsDir.exists()) {
      await docsDir.create(recursive: true);
    }
    return docsDir;
  }

  Future<Directory> getUserThumbnailsDirectory(String userId) async {
    final userDir = await getUserDirectory(userId);
    final thumbsDir = Directory(p.join(userDir.path, 'thumbnails'));
    if (!await thumbsDir.exists()) {
      await thumbsDir.create(recursive: true);
    }
    return thumbsDir;
  }

  Future<Directory> getUserTempDirectory(String userId) async {
    final userDir = await getUserDirectory(userId);
    final tempDir = Directory(p.join(userDir.path, 'temp'));
    if (!await tempDir.exists()) {
      await tempDir.create(recursive: true);
    }
    return tempDir;
  }

  Future<Directory> getDocumentDirectory(String userId, String documentId) async {
    final docsDir = await getUserDocumentsDirectory(userId);
    final docDir = Directory(p.join(docsDir.path, documentId));
    if (!await docDir.exists()) {
      await docDir.create(recursive: true);
    }
    return docDir;
  }

  Future<void> deleteDocumentDirectory(String userId, String documentId) async {
    final docDir = await getDocumentDirectory(userId, documentId);
    if (await docDir.exists()) {
      await docDir.delete(recursive: true);
    }

    final thumbsDir = await getUserThumbnailsDirectory(userId);
    final thumbFile = File(p.join(thumbsDir.path, '$documentId.jpg'));
    if (await thumbFile.exists()) {
      await thumbFile.delete();
    }
  }

  Future<int> cleanupTempDirectory(String userId) async {
    final tempDir = await getUserTempDirectory(userId);
    var bytesFreed = 0;
    if (await tempDir.exists()) {
      await for (final entity in tempDir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          bytesFreed += await entity.length();
          try {
            await entity.delete();
          } catch (_) {}
        }
      }
    }
    return bytesFreed;
  }

  Future<UserStorageMetrics> calculateStorageMetrics(String userId) async {
    var docBytes = 0;
    var thumbBytes = 0;
    var tempBytes = 0;
    var count = 0;
    var largestBytes = 0;

    final docsDir = await getUserDocumentsDirectory(userId);
    if (await docsDir.exists()) {
      await for (final entity in docsDir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final len = await entity.length();
          docBytes += len;
          if (entity.path.endsWith('.pdf')) {
            count++;
            if (len > largestBytes) largestBytes = len;
          }
        }
      }
    }

    final thumbsDir = await getUserThumbnailsDirectory(userId);
    if (await thumbsDir.exists()) {
      await for (final entity in thumbsDir.list(recursive: false, followLinks: false)) {
        if (entity is File) {
          thumbBytes += await entity.length();
        }
      }
    }

    final tempDir = await getUserTempDirectory(userId);
    if (await tempDir.exists()) {
      await for (final entity in tempDir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          tempBytes += await entity.length();
        }
      }
    }

    return UserStorageMetrics(
      totalDocumentBytes: docBytes,
      totalThumbnailBytes: thumbBytes,
      totalTempBytes: tempBytes,
      documentCount: count,
      largestDocumentBytes: largestBytes,
    );
  }
}
