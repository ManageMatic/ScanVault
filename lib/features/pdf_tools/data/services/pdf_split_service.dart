import 'dart:io';
import 'package:flutter/painting.dart';
import 'package:path/path.dart' as p;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../domain/entities/pdf_processing_progress.dart';

class PdfSplitService {
  const PdfSplitService();

  List<int> parseRange(String rangeStr, int totalPages) {
    final trimmed = rangeStr.trim();
    if (trimmed.isEmpty) return [];

    if (trimmed.contains('-')) {
      final parts = trimmed.split('-');
      if (parts.length == 2) {
        final start = int.tryParse(parts[0].trim());
        final end = int.tryParse(parts[1].trim());
        if (start != null && end != null) {
          final s = start.clamp(1, totalPages);
          final e = end.clamp(1, totalPages);
          final list = <int>[];
          if (s <= e) {
            for (var i = s; i <= e; i++) {
              list.add(i - 1); // 0-indexed
            }
          } else {
            for (var i = s; i >= e; i--) {
              list.add(i - 1);
            }
          }
          return list;
        }
      }
    }

    final single = int.tryParse(trimmed);
    if (single != null && single >= 1 && single <= totalPages) {
      return [single - 1]; // 0-indexed
    }

    return [];
  }

  Future<List<File>> splitPdf({
    required File sourcePdf,
    required List<String> ranges,
    required Directory outputDirectory,
    required String baseOutputTitle,
    ProgressCallback? onProgress,
  }) async {
    if (!await sourcePdf.exists()) {
      throw FileSystemException('Source PDF does not exist', sourcePdf.path);
    }

    if (ranges.isEmpty) {
      throw ArgumentError('At least one split range must be specified.');
    }

    if (!await outputDirectory.exists()) {
      await outputDirectory.create(recursive: true);
    }

    final bytes = await sourcePdf.readAsBytes();
    final srcDoc = PdfDocument(inputBytes: bytes);
    final totalPages = srcDoc.pages.count;

    final outputFiles = <File>[];

    try {
      for (var r = 0; r < ranges.length; r++) {
        final rangeStr = ranges[r];
        final pageIndices = parseRange(rangeStr, totalPages);
        if (pageIndices.isEmpty) continue;

        onProgress?.call(PdfProcessingProgress(
          progress: (r / ranges.length),
          statusMessage: 'Generating split document ($rangeStr)...',
          currentPage: r + 1,
          totalPages: ranges.length,
        ));

        final splitDoc = PdfDocument();
        for (final idx in pageIndices) {
          if (idx >= 0 && idx < totalPages) {
            final page = srcDoc.pages[idx];
            final template = page.createTemplate();
            final newPage = splitDoc.pages.add();
            newPage.graphics.drawPdfTemplate(template, Offset.zero);
          }
        }

        if (splitDoc.pages.count > 0) {
          final splitBytes = await splitDoc.save();
          final cleanTitle = baseOutputTitle.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
          final safeName = '${cleanTitle}_$rangeStr.pdf'.replaceAll(' ', '_');
          final splitFile = File(p.join(outputDirectory.path, safeName));
          await splitFile.writeAsBytes(splitBytes, flush: true);
          outputFiles.add(splitFile);
        }
        splitDoc.dispose();
      }
    } finally {
      srcDoc.dispose();
    }

    onProgress?.call(const PdfProcessingProgress(
      progress: 1.0,
      statusMessage: 'Split completed successfully!',
    ));

    return outputFiles;
  }
}
