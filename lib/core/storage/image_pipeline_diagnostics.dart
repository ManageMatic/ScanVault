import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../../features/scanner/domain/scanned_page_item.dart';
import 'page_image_resolver.dart';

/// Diagnostic logger and verifier for ScanVault image file pipeline lifecycle.
class ImagePipelineDiagnostics {
  /// Inspect and log forensic details of a page at any pipeline stage.
  static Future<void> logStage({
    required String stage,
    required ScannedPageItem page,
  }) async {
    if (kReleaseMode) return;

    final resolvedPath = PageImageResolver.resolveCurrentImagePath(page);
    final file = resolvedPath != null ? File(resolvedPath) : null;
    final exists = file?.existsSync() ?? false;
    final fileSize = exists ? file!.lengthSync() : 0;
    bool decodeSuccess = false;
    int width = 0;
    int height = 0;

    if (exists && fileSize > 0) {
      try {
        final bytes = await file!.readAsBytes();
        final decoded = img.decodeImage(bytes);
        if (decoded != null && decoded.width > 0 && decoded.height > 0) {
          decodeSuccess = true;
          width = decoded.width;
          height = decoded.height;
        }
      } catch (e) {
        debugPrint('[ScanVault][Diagnostic] Decode check error: $e');
      }
    } else if (page.cachedProcessedBytes != null && page.cachedProcessedBytes!.isNotEmpty) {
      try {
        final decoded = img.decodeImage(page.cachedProcessedBytes!);
        if (decoded != null && decoded.width > 0 && decoded.height > 0) {
          decodeSuccess = true;
          width = decoded.width;
          height = decoded.height;
        }
      } catch (e) {
        debugPrint('[ScanVault][Diagnostic] In-memory decode error: $e');
      }
    }

    debugPrint('''
[SCANVAULT PIPELINE] =====================================
stage=$stage
pageId=${page.id}
version=${page.imageVersion}
path=${resolvedPath ?? 'none'}
exists=$exists
fileSize=$fileSize
decodeSuccess=$decodeSuccess
width=$width
height=$height
==========================================================''');
  }
}
