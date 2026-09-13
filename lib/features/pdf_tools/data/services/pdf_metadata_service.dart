import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../domain/entities/pdf_processing_progress.dart';
import '../../domain/repositories/pdf_tools_repository.dart';

class PdfMetadataService {
  const PdfMetadataService();

  Future<PdfMetadataEditRequest> readMetadata(File sourcePdf) async {
    if (!await sourcePdf.exists()) {
      throw FileSystemException('Source PDF does not exist', sourcePdf.path);
    }

    final bytes = await sourcePdf.readAsBytes();
    final document = PdfDocument(inputBytes: bytes);

    try {
      final info = document.documentInformation;
      return PdfMetadataEditRequest(
        title: info.title.isNotEmpty ? info.title : null,
        author: info.author.isNotEmpty ? info.author : null,
        subject: info.subject.isNotEmpty ? info.subject : null,
        keywords: info.keywords.isNotEmpty ? info.keywords : null,
        creator: info.creator.isNotEmpty ? info.creator : null,
      );
    } finally {
      document.dispose();
    }
  }

  Future<File> updateMetadata({
    required File sourcePdf,
    required File targetFile,
    required PdfMetadataEditRequest metadata,
    ProgressCallback? onProgress,
  }) async {
    if (!await sourcePdf.exists()) {
      throw FileSystemException('Source PDF does not exist', sourcePdf.path);
    }

    onProgress?.call(const PdfProcessingProgress(
      progress: 0.1,
      statusMessage: 'Reading PDF document metadata...',
    ));

    final bytes = await sourcePdf.readAsBytes();
    final document = PdfDocument(inputBytes: bytes);

    try {
      onProgress?.call(const PdfProcessingProgress(
        progress: 0.5,
        statusMessage: 'Updating document properties...',
      ));

      final info = document.documentInformation;
      if (metadata.title != null) info.title = metadata.title!;
      if (metadata.author != null) info.author = metadata.author!;
      if (metadata.subject != null) info.subject = metadata.subject!;
      if (metadata.keywords != null) info.keywords = metadata.keywords!;
      if (metadata.creator != null) info.creator = metadata.creator!;

      onProgress?.call(const PdfProcessingProgress(
        progress: 0.8,
        statusMessage: 'Writing updated document to disk...',
      ));

      final outputBytes = await document.save();
      await targetFile.parent.create(recursive: true);
      await targetFile.writeAsBytes(outputBytes, flush: true);
    } finally {
      document.dispose();
    }

    onProgress?.call(const PdfProcessingProgress(
      progress: 1.0,
      statusMessage: 'Metadata updated successfully!',
    ));

    return targetFile;
  }
}
