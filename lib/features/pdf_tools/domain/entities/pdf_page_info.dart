import 'dart:typed_data';

class PdfPageInfo {
  final int pageIndex; // 0-indexed
  final int pageNumber; // 1-indexed
  final double width;
  final double height;
  final int rotationDegrees;
  final Uint8List? thumbnailBytes;
  final bool isSelected;

  const PdfPageInfo({
    required this.pageIndex,
    required this.pageNumber,
    this.width = 595.0,
    this.height = 842.0,
    this.rotationDegrees = 0,
    this.thumbnailBytes,
    this.isSelected = false,
  });

  PdfPageInfo copyWith({
    int? pageIndex,
    int? pageNumber,
    double? width,
    double? height,
    int? rotationDegrees,
    Uint8List? thumbnailBytes,
    bool? isSelected,
  }) {
    return PdfPageInfo(
      pageIndex: pageIndex ?? this.pageIndex,
      pageNumber: pageNumber ?? this.pageNumber,
      width: width ?? this.width,
      height: height ?? this.height,
      rotationDegrees: rotationDegrees ?? this.rotationDegrees,
      thumbnailBytes: thumbnailBytes ?? this.thumbnailBytes,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
