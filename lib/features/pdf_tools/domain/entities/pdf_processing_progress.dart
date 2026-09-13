class PdfProcessingProgress {
  final double progress; // 0.0 to 1.0
  final String statusMessage;
  final int? currentPage;
  final int? totalPages;
  final bool isCancelable;

  const PdfProcessingProgress({
    required this.progress,
    required this.statusMessage,
    this.currentPage,
    this.totalPages,
    this.isCancelable = true,
  });

  String get formattedProgress {
    if (currentPage != null && totalPages != null && totalPages! > 0) {
      return 'Processing page $currentPage of $totalPages (${(progress * 100).toInt()}%)';
    }
    return '${(progress * 100).toInt()}%';
  }
}

typedef ProgressCallback = void Function(PdfProcessingProgress progress);
