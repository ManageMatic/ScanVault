import 'package:scanvault/shared/models/document.dart';

class PdfToolResult {
  final bool success;
  final String? errorMessage;
  final Document? document;
  final List<String> generatedFilePaths;
  final int? originalSizeBytes;
  final int? outputSizeBytes;
  final int pageCount;
  final String? summaryMessage;

  const PdfToolResult({
    required this.success,
    this.errorMessage,
    this.document,
    this.generatedFilePaths = const [],
    this.originalSizeBytes,
    this.outputSizeBytes,
    this.pageCount = 0,
    this.summaryMessage,
  });

  factory PdfToolResult.failure(String message) {
    return PdfToolResult(
      success: false,
      errorMessage: message,
    );
  }

  factory PdfToolResult.success({
    Document? document,
    List<String> generatedFilePaths = const [],
    int? originalSizeBytes,
    int? outputSizeBytes,
    int pageCount = 0,
    String? summaryMessage,
  }) {
    return PdfToolResult(
      success: true,
      document: document,
      generatedFilePaths: generatedFilePaths,
      originalSizeBytes: originalSizeBytes,
      outputSizeBytes: outputSizeBytes,
      pageCount: pageCount,
      summaryMessage: summaryMessage,
    );
  }

  double? get sizeSavedPercentage {
    if (originalSizeBytes != null &&
        outputSizeBytes != null &&
        originalSizeBytes! > 0 &&
        outputSizeBytes! < originalSizeBytes!) {
      return ((originalSizeBytes! - outputSizeBytes!) / originalSizeBytes!) * 100.0;
    }
    return null;
  }

  int? get bytesSaved {
    if (originalSizeBytes != null &&
        outputSizeBytes != null &&
        originalSizeBytes! > outputSizeBytes!) {
      return originalSizeBytes! - outputSizeBytes!;
    }
    return null;
  }
}
