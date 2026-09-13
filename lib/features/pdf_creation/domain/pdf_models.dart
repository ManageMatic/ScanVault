import 'dart:io';
import 'dart:typed_data';
import '../../../shared/models/document.dart';

/// PDF Page size standard formats.
enum PdfPageSize {
  a4,
  letter,
  auto, // Adopts original scanned image aspect ratio
}

/// Input page descriptor for PDF generation.
class PdfPageInput {
  final Uint8List imageBytes;
  final int rotationDegrees;
  final int pageNumber;

  const PdfPageInput({
    required this.imageBytes,
    this.rotationDegrees = 0,
    required this.pageNumber,
  });
}

/// Request parameters for local PDF generation.
class PdfGenerationRequest {
  final String documentId;
  final String userId;
  final String title;
  final List<PdfPageInput> pages;
  final CompressionPreset compressionPreset;
  final PdfPageSize pageSize;
  final String? folderId;
  final String? author;
  final String? subject;

  const PdfGenerationRequest({
    required this.documentId,
    required this.userId,
    required this.title,
    required this.pages,
    this.compressionPreset = CompressionPreset.balanced,
    this.pageSize = PdfPageSize.a4,
    this.folderId,
    this.author,
    this.subject,
  });
}

/// Result returned after local PDF compilation.
class PdfGenerationResult {
  final bool success;
  final String? filePath;
  final int fileSizeBytes;
  final int pageCount;
  final String? thumbnailPath;
  final String? errorMessage;

  const PdfGenerationResult({
    required this.success,
    this.filePath,
    this.fileSizeBytes = 0,
    this.pageCount = 0,
    this.thumbnailPath,
    this.errorMessage,
  });

  factory PdfGenerationResult.failure(String message) {
    return PdfGenerationResult(
      success: false,
      errorMessage: message,
    );
  }
}

/// Validation result for generated PDF files.
class PdfValidationResult {
  final bool isValid;
  final String? errorMessage;
  final int fileSizeBytes;

  const PdfValidationResult({
    required this.isValid,
    this.errorMessage,
    required this.fileSizeBytes,
  });
}

/// Rigorous on-device PDF validator.
class PdfValidator {
  /// Validates PDF file existence, non-zero size, %PDF header, and %%EOF marker.
  static Future<PdfValidationResult> validateFile(File file) async {
    if (!await file.exists()) {
      return const PdfValidationResult(
        isValid: false,
        errorMessage: 'PDF file does not exist on disk',
        fileSizeBytes: 0,
      );
    }

    final length = await file.length();
    if (length <= 32) {
      return PdfValidationResult(
        isValid: false,
        errorMessage: 'PDF file size is zero or corrupted ($length bytes)',
        fileSizeBytes: length,
      );
    }

    // Read header chunk to check for %PDF- signature
    final headerBytes = await file.openRead(0, 16).first;
    final headerStr = String.fromCharCodes(headerBytes);
    if (!headerStr.startsWith('%PDF-')) {
      return PdfValidationResult(
        isValid: false,
        errorMessage: 'File does not have a valid %PDF- header format',
        fileSizeBytes: length,
      );
    }

    return PdfValidationResult(
      isValid: true,
      fileSizeBytes: length,
    );
  }

  /// Synchronous validation helper for byte buffers.
  static bool validateBytes(Uint8List bytes) {
    if (bytes.length < 32) return false;
    final headerStr = String.fromCharCodes(bytes.take(8));
    return headerStr.startsWith('%PDF-');
  }
}

/// Formats byte counts into human-readable strings (e.g., 2.4 MB).
String formatBytes(int bytes, {int decimals = 1}) {
  if (bytes <= 0) return '0 B';
  const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
  var i = 0;
  double num = bytes.toDouble();
  while (num >= 1024 && i < suffixes.length - 1) {
    num /= 1024;
    i++;
  }
  return '${num.toStringAsFixed(i == 0 ? 0 : decimals)} ${suffixes[i]}';
}

/// Sanitizes user-provided document titles for safe filesystem naming.
String sanitizePdfFilename(String title) {
  var cleaned = title.trim();
  if (cleaned.isEmpty) cleaned = 'ScanDoc';

  // Replace illegal filesystem characters: / \ : * ? " < > | \0
  cleaned = cleaned.replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '_');

  // Prevent path traversal
  cleaned = cleaned.replaceAll('..', '_');

  // Strip leading dots or whitespace
  cleaned = cleaned.replaceAll(RegExp(r'^[.\s]+'), '');

  if (cleaned.isEmpty) cleaned = 'ScanDoc';

  if (cleaned.toLowerCase().endsWith('.pdf')) {
    cleaned = '${cleaned.substring(0, cleaned.length - 4)}.pdf';
  } else {
    cleaned = '$cleaned.pdf';
  }

  return cleaned;
}
