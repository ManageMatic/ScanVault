import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'storage_manager_service.dart';

/// Manages isolated filesystem sessions for camera captures, cropping, filtering, and page editing.
///
/// Hierarchy:
/// ScanVault/
///   users/
///     {userId}/
///       sessions/
///         {sessionId}/
///           pages/
///             {pageId}/
///               original.jpg
///               working.jpg
///               processed.jpg
///               thumbnail.jpg
class SessionWorkspaceManager {
  final StorageManagerService _storageManager;

  SessionWorkspaceManager({StorageManagerService? storageManager})
      : _storageManager = storageManager ?? StorageManagerService();

  Future<Directory> getSessionsRootDirectory(String userId) async {
    final userDir = await _storageManager.getUserDirectory(userId);
    final sessionsDir = Directory(p.join(userDir.path, 'sessions'));
    if (!await sessionsDir.exists()) {
      await sessionsDir.create(recursive: true);
    }
    return sessionsDir;
  }

  Future<Directory> getSessionDirectory(String userId, String sessionId) async {
    final sessionsDir = await getSessionsRootDirectory(userId);
    final sessionDir = Directory(p.join(sessionsDir.path, sessionId));
    if (!await sessionDir.exists()) {
      await sessionDir.create(recursive: true);
    }
    return sessionDir;
  }

  Future<Directory> getPageDirectory(String userId, String sessionId, String pageId) async {
    final sessionDir = await getSessionDirectory(userId, sessionId);
    final pageDir = Directory(p.join(sessionDir.path, 'pages', pageId));
    if (!await pageDir.exists()) {
      await pageDir.create(recursive: true);
    }
    return pageDir;
  }

  /// Creates a stable local copy of an image into page workspace and generates a thumbnail.
  Future<Map<String, String>> importSourceImage({
    required String userId,
    required String sessionId,
    required String pageId,
    Uint8List? rawBytes,
    String? sourceFilePath,
  }) async {
    final pageDir = await getPageDirectory(userId, sessionId, pageId);
    final originalPath = p.join(pageDir.path, 'original.jpg');
    final thumbPath = p.join(pageDir.path, 'thumbnail.jpg');

    Uint8List finalBytes;

    if (rawBytes != null && rawBytes.isNotEmpty) {
      finalBytes = rawBytes;
    } else if (sourceFilePath != null && sourceFilePath.isNotEmpty) {
      final srcFile = File(sourceFilePath);
      if (await srcFile.exists()) {
        finalBytes = await srcFile.readAsBytes();
      } else {
        throw Exception('Source image file not found at: $sourceFilePath');
      }
    } else {
      throw Exception('Neither rawBytes nor sourceFilePath was provided for image import.');
    }

    if (finalBytes.isEmpty) {
      throw Exception('Image bytes cannot be empty.');
    }

    // 1. Write original stable copy
    final originalFile = File(originalPath);
    await originalFile.writeAsBytes(finalBytes, flush: true);

    // 2. Generate and save thumbnail (~320px)
    await _generateAndSaveThumbnail(finalBytes, thumbPath);

    return {
      'originalPath': originalPath,
      'thumbnailPath': thumbPath,
    };
  }

  /// Saves cropped / perspective-warped working image
  Future<String> saveWorkingImage({
    required String userId,
    required String sessionId,
    required String pageId,
    required Uint8List bytes,
  }) async {
    final pageDir = await getPageDirectory(userId, sessionId, pageId);
    final workingPath = p.join(pageDir.path, 'working.jpg');
    final thumbPath = p.join(pageDir.path, 'thumbnail.jpg');

    final file = File(workingPath);
    await file.writeAsBytes(bytes, flush: true);

    // Update thumbnail with current working image
    await _generateAndSaveThumbnail(bytes, thumbPath);

    return workingPath;
  }

  /// Saves filtered / enhanced processed image
  Future<String> saveProcessedImage({
    required String userId,
    required String sessionId,
    required String pageId,
    required Uint8List bytes,
  }) async {
    final pageDir = await getPageDirectory(userId, sessionId, pageId);
    final processedPath = p.join(pageDir.path, 'processed.jpg');
    final thumbPath = p.join(pageDir.path, 'thumbnail.jpg');

    final file = File(processedPath);
    await file.writeAsBytes(bytes, flush: true);

    // Update thumbnail with processed image
    await _generateAndSaveThumbnail(bytes, thumbPath);

    return processedPath;
  }

  /// Cleans up an entire session directory upon document save or session discard
  Future<void> cleanupSession(String userId, String sessionId) async {
    try {
      final sessionDir = await getSessionDirectory(userId, sessionId);
      if (await sessionDir.exists()) {
        await sessionDir.delete(recursive: true);
        debugPrint('[ScanVault][Workspace] Cleaned up session: $sessionId');
      }
    } catch (e) {
      debugPrint('[ScanVault][Workspace] Error cleaning up session $sessionId: $e');
    }
  }

  /// Cleans up any orphaned sessions older than 24 hours
  Future<void> cleanupOrphanSessions(String userId) async {
    try {
      final sessionsDir = await getSessionsRootDirectory(userId);
      if (await sessionsDir.exists()) {
        final now = DateTime.now();
        await for (final entity in sessionsDir.list(recursive: false, followLinks: false)) {
          if (entity is Directory) {
            final stat = await entity.stat();
            if (now.difference(stat.modified).inHours > 24) {
              await entity.delete(recursive: true);
              debugPrint('[ScanVault][Workspace] Purged orphan session: ${entity.path}');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[ScanVault][Workspace] Error cleaning up orphan sessions: $e');
    }
  }

  static Future<void> _generateAndSaveThumbnail(Uint8List imageBytes, String targetThumbPath) async {
    try {
      final decoded = img.decodeImage(imageBytes);
      if (decoded != null) {
        final resized = img.copyResize(decoded, width: 320);
        final thumbJpg = img.encodeJpg(resized, quality: 75);
        final file = File(targetThumbPath);
        await file.writeAsBytes(thumbJpg, flush: true);
      } else {
        final file = File(targetThumbPath);
        await file.writeAsBytes(imageBytes, flush: true);
      }
    } catch (e) {
      debugPrint('[ScanVault][Thumbnail] Error generating thumbnail: $e');
      final file = File(targetThumbPath);
      if (!await file.exists()) {
        await file.writeAsBytes(imageBytes, flush: true);
      }
    }
  }
}
