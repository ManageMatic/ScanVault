import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../../features/scanner/domain/scanned_page_item.dart';

enum PageImageSource {
  processed,
  working,
  original,
  memory,
  none,
}

class ResolvedPageImage {
  final String? path;
  final Uint8List? bytes;
  final int width;
  final int height;
  final PageImageSource source;
  final int fileSizeBytes;
  final String? errorMessage;

  const ResolvedPageImage({
    this.path,
    this.bytes,
    required this.width,
    required this.height,
    required this.source,
    required this.fileSizeBytes,
    this.errorMessage,
  });

  bool get isValid => (path != null || (bytes != null && bytes!.isNotEmpty)) && width > 0 && height > 0;

  factory ResolvedPageImage.error(String message) {
    return ResolvedPageImage(
      width: 0,
      height: 0,
      source: PageImageSource.none,
      fileSizeBytes: 0,
      errorMessage: message,
    );
  }
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

  /// Full async decodability validation resolving the best candidate:
  /// processed -> working -> original -> cachedProcessedBytes
  static Future<ResolvedPageImage> resolveCurrentImage(ScannedPageItem page) async {
    // Candidate 1: processedImagePath
    if (page.processedImagePath != null && page.processedImagePath!.isNotEmpty) {
      final res = await _validateFileCandidate(page.processedImagePath!, PageImageSource.processed);
      if (res != null && res.isValid) return res;
    }

    // Candidate 2: workingImagePath
    if (page.workingImagePath != null && page.workingImagePath!.isNotEmpty) {
      final res = await _validateFileCandidate(page.workingImagePath!, PageImageSource.working);
      if (res != null && res.isValid) return res;
    }

    // Candidate 3: originalImagePath
    if (page.originalImagePath.isNotEmpty) {
      final res = await _validateFileCandidate(page.originalImagePath, PageImageSource.original);
      if (res != null && res.isValid) return res;
    }

    // Candidate 4: cachedProcessedBytes
    if (page.cachedProcessedBytes != null && page.cachedProcessedBytes!.isNotEmpty) {
      try {
        final decoded = img.decodeImage(page.cachedProcessedBytes!);
        if (decoded != null && decoded.width > 0 && decoded.height > 0) {
          return ResolvedPageImage(
            bytes: page.cachedProcessedBytes,
            width: decoded.width,
            height: decoded.height,
            source: PageImageSource.memory,
            fileSizeBytes: page.cachedProcessedBytes!.length,
          );
        }
      } catch (e) {
        debugPrint('[ScanVault][ImageResolver] Failed to decode in-memory bytes for page ${page.id}: $e');
      }
    }

    return ResolvedPageImage.error('No valid or decodable image candidate found for page ${page.id}.');
  }

  static Future<ResolvedPageImage?> _validateFileCandidate(String filePath, PageImageSource source) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;
      final size = await file.length();
      if (size <= 0) return null;

      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null || decoded.width <= 0 || decoded.height <= 0) {
        debugPrint('[ScanVault][ImageResolver] Candidate file $filePath was un-decodable.');
        return null;
      }

      return ResolvedPageImage(
        path: filePath,
        bytes: bytes,
        width: decoded.width,
        height: decoded.height,
        source: source,
        fileSizeBytes: size,
      );
    } catch (e) {
      debugPrint('[ScanVault][ImageResolver] Error validating candidate $filePath: $e');
      return null;
    }
  }
}
