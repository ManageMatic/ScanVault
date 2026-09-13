import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:printing/printing.dart';
import '../../domain/entities/pdf_processing_progress.dart';

class PdfToImagesService {
  const PdfToImagesService();

  Future<List<File>> convertPdfToImages({
    required File sourcePdf,
    required Directory outputDirectory,
    required List<int> pageIndices, // 0-indexed
    bool isPng = false,
    int dpi = 200,
    ProgressCallback? onProgress,
  }) async {
    if (!await sourcePdf.exists()) {
      throw FileSystemException('Source PDF does not exist', sourcePdf.path);
    }

    if (!await outputDirectory.exists()) {
      await outputDirectory.create(recursive: true);
    }

    onProgress?.call(const PdfProcessingProgress(
      progress: 0.1,
      statusMessage: 'Reading PDF for rendering...',
    ));

    final pdfBytes = await sourcePdf.readAsBytes();
    final outputFiles = <File>[];
    final targetPageSet = pageIndices.toSet();

    var pageCounter = 0;
    var processedCount = 0;
    final totalToProcess = pageIndices.isEmpty ? 1 : pageIndices.length;

    // Stream pages via Printing.raster to prevent high memory spikes
    await for (final raster in Printing.raster(pdfBytes, dpi: dpi.toDouble())) {
      final currentIdx = pageCounter;
      pageCounter++;

      if (targetPageSet.isNotEmpty && !targetPageSet.contains(currentIdx)) {
        continue;
      }

      processedCount++;
      onProgress?.call(PdfProcessingProgress(
        progress: 0.1 + (0.8 * (processedCount / totalToProcess)),
        statusMessage: 'Rendering page ${currentIdx + 1}...',
        currentPage: processedCount,
        totalPages: totalToProcess,
      ));

      final baseName = p.basenameWithoutExtension(sourcePdf.path);
      final ext = isPng ? 'png' : 'jpg';
      final fileName = '${baseName}_page_${currentIdx + 1}.$ext';
      final targetFile = File(p.join(outputDirectory.path, fileName));

      if (isPng) {
        final pngBytes = await raster.toPng();
        await targetFile.writeAsBytes(pngBytes, flush: true);
      } else {
        // Convert to JPG via image library
        final pngBytes = await raster.toPng();
        final decoded = img.decodeImage(pngBytes);
        if (decoded != null) {
          final jpgBytes = Uint8List.fromList(img.encodeJpg(decoded, quality: 90));
          await targetFile.writeAsBytes(jpgBytes, flush: true);
        } else {
          await targetFile.writeAsBytes(pngBytes, flush: true);
        }
      }

      outputFiles.add(targetFile);
    }

    onProgress?.call(const PdfProcessingProgress(
      progress: 1.0,
      statusMessage: 'Export complete!',
    ));

    return outputFiles;
  }
}
