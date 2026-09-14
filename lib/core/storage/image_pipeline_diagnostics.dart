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

    final origFile = File(page.originalImagePath);
    final origExists = origFile.existsSync();
    final origSize = origExists ? origFile.lengthSync() : 0;
    String origDecode = 'N/A';
    if (origExists && origSize > 0) {
      try {
        final decoded = img.decodeImage(await origFile.readAsBytes());
        origDecode = decoded != null ? '${decoded.width}x${decoded.height} (${decoded.numChannels}ch)' : 'FAILED_DECODE';
      } catch (e) {
        origDecode = 'ERROR: $e';
      }
    }

    String workInfo = 'null';
    if (page.workingImagePath != null) {
      final workFile = File(page.workingImagePath!);
      final workExists = workFile.existsSync();
      final workSize = workExists ? workFile.lengthSync() : 0;
      String workDecode = 'N/A';
      if (workExists && workSize > 0) {
        try {
          final decoded = img.decodeImage(await workFile.readAsBytes());
          workDecode = decoded != null ? '${decoded.width}x${decoded.height} (${decoded.numChannels}ch)' : 'FAILED_DECODE';
        } catch (e) {
          workDecode = 'ERROR: $e';
        }
      }
      workInfo = 'exists=$workExists, size=$workSize bytes, decode=$workDecode, path=${page.workingImagePath}';
    }

    String procInfo = 'null';
    if (page.processedImagePath != null) {
      final procFile = File(page.processedImagePath!);
      final procExists = procFile.existsSync();
      final procSize = procExists ? procFile.lengthSync() : 0;
      String procDecode = 'N/A';
      if (procExists && procSize > 0) {
        try {
          final decoded = img.decodeImage(await procFile.readAsBytes());
          procDecode = decoded != null ? '${decoded.width}x${decoded.height} (${decoded.numChannels}ch)' : 'FAILED_DECODE';
        } catch (e) {
          procDecode = 'ERROR: $e';
        }
      }
      procInfo = 'exists=$procExists, size=$procSize bytes, decode=$procDecode, path=${page.processedImagePath}';
    }

    final resolved = PageImageResolver.resolveCurrentImagePath(page);

    debugPrint('''
[SCANVAULT IMAGE DEBUG] ---------------------------------------------
stage=$stage
pageId=${page.id}
sessionId=${page.sessionId}
original: exists=$origExists, size=$origSize bytes, decode=$origDecode, path=${page.originalImagePath}
working:  $workInfo
processed: $procInfo
RESOLVED CANONICAL PATH: $resolved
---------------------------------------------------------------------
''');
  }
}
