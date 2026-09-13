import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../domain/entities/pdf_processing_progress.dart';

class PdfProtectionService {
  const PdfProtectionService();

  Future<File> protectPdf({
    required File sourcePdf,
    required File targetFile,
    required String password,
    String? ownerPassword,
    ProgressCallback? onProgress,
  }) async {
    if (!await sourcePdf.exists()) {
      throw FileSystemException('Source PDF does not exist', sourcePdf.path);
    }

    if (password.trim().isEmpty) {
      throw ArgumentError('Password cannot be empty.');
    }

    onProgress?.call(const PdfProcessingProgress(
      progress: 0.1,
      statusMessage: 'Loading PDF document for encryption...',
    ));

    final bytes = await sourcePdf.readAsBytes();
    final document = PdfDocument(inputBytes: bytes);

    try {
      onProgress?.call(const PdfProcessingProgress(
        progress: 0.4,
        statusMessage: 'Configuring AES-256 cryptographic security...',
      ));

      final security = document.security;
      security.userPassword = password;
      security.ownerPassword = ownerPassword ?? '${password}_admin';
      security.algorithm = PdfEncryptionAlgorithm.aesx256Bit;
      security.permissions.addAll([
        PdfPermissionsFlags.print,
        PdfPermissionsFlags.copyContent,
      ]);

      onProgress?.call(const PdfProcessingProgress(
        progress: 0.8,
        statusMessage: 'Writing encrypted document to disk...',
      ));

      final protectedBytes = await document.save();
      await targetFile.parent.create(recursive: true);
      await targetFile.writeAsBytes(protectedBytes, flush: true);
    } finally {
      document.dispose();
    }

    onProgress?.call(const PdfProcessingProgress(
      progress: 1.0,
      statusMessage: 'Document encryption complete!',
    ));

    return targetFile;
  }
}
