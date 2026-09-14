import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../features/scanner/domain/scanned_page_item.dart';

class ImageValidationResult {
  final bool isValid;
  final String? resolvedPath;
  final Uint8List? resolvedBytes;
  final int fileSizeBytes;
  final String? errorMessage;

  const ImageValidationResult({
    required this.isValid,
    this.resolvedPath,
    this.resolvedBytes,
    this.fileSizeBytes = 0,
    this.errorMessage,
  });
}

/// Canonical single source of truth for resolving the active display image file or bytes for a page.
class PageImageResolver {
  /// Resolves the current best image file path:
  /// 1. processedImagePath (if exists and > 0 bytes)
  /// 2. workingImagePath (if exists and > 0 bytes)
  /// 3. originalImagePath (if exists and > 0 bytes)
  static String? resolveCurrentImagePath(ScannedPageItem page) {
    if (page.processedImagePath != null && page.processedImagePath!.isNotEmpty) {
      final f = File(page.processedImagePath!);
      if (f.existsSync() && f.lengthSync() > 0) {
        return page.processedImagePath;
      }
    }

    if (page.workingImagePath != null && page.workingImagePath!.isNotEmpty) {
      final f = File(page.workingImagePath!);
      if (f.existsSync() && f.lengthSync() > 0) {
        return page.workingImagePath;
      }
    }

    if (page.originalImagePath.isNotEmpty) {
      final f = File(page.originalImagePath);
      if (f.existsSync() && f.lengthSync() > 0) {
        return page.originalImagePath;
      }
    }

    return null;
  }

  /// Full async validation resolving path or in-memory bytes with sanity checks.
  static Future<ImageValidationResult> validateAndResolve(ScannedPageItem page) async {
    // 1. Try file path resolution
    final bestPath = resolveCurrentImagePath(page);
    if (bestPath != null) {
      try {
        final f = File(bestPath);
        final size = await f.length();
        if (size > 0) {
          if (kDebugMode) {
            debugPrint('[ScanVault][ImagePipeline] Resolved page ${page.id} -> $bestPath ($size bytes)');
          }
          return ImageValidationResult(
            isValid: true,
            resolvedPath: bestPath,
            fileSizeBytes: size,
          );
        }
      } catch (e) {
        debugPrint('[ScanVault][ImagePipeline] Error reading $bestPath: $e');
      }
    }

    // 2. Fallback to cachedProcessedBytes if present in memory
    if (page.cachedProcessedBytes != null && page.cachedProcessedBytes!.isNotEmpty) {
      return ImageValidationResult(
        isValid: true,
        resolvedBytes: page.cachedProcessedBytes,
        fileSizeBytes: page.cachedProcessedBytes!.length,
      );
    }

    return ImageValidationResult(
      isValid: false,
      errorMessage: 'Page image file not found or corrupted at: ${page.originalImagePath}',
    );
  }
}
