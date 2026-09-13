/// Represents a single page inside a scanned document.
class DocumentPage {
  final String id;
  final int pageNumber;
  final String imagePath;
  final String? thumbnailPath;
  final double width;
  final double height;
  final int rotationDegrees;
  final String? ocrText;
  final DateTime createdAt;

  const DocumentPage({
    required this.id,
    required this.pageNumber,
    required this.imagePath,
    this.thumbnailPath,
    this.width = 0.0,
    this.height = 0.0,
    this.rotationDegrees = 0,
    this.ocrText,
    required this.createdAt,
  });

  DocumentPage copyWith({
    String? id,
    int? pageNumber,
    String? imagePath,
    String? thumbnailPath,
    double? width,
    double? height,
    int? rotationDegrees,
    String? ocrText,
    DateTime? createdAt,
  }) {
    return DocumentPage(
      id: id ?? this.id,
      pageNumber: pageNumber ?? this.pageNumber,
      imagePath: imagePath ?? this.imagePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      width: width ?? this.width,
      height: height ?? this.height,
      rotationDegrees: rotationDegrees ?? this.rotationDegrees,
      ocrText: ocrText ?? this.ocrText,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'pageNumber': pageNumber,
        'imagePath': imagePath,
        'thumbnailPath': thumbnailPath,
        'width': width,
        'height': height,
        'rotationDegrees': rotationDegrees,
        'ocrText': ocrText,
        'createdAt': createdAt.toIso8601String(),
      };

  factory DocumentPage.fromJson(Map<String, dynamic> json) => DocumentPage(
        id: json['id'] as String,
        pageNumber: json['pageNumber'] as int,
        imagePath: json['imagePath'] as String,
        thumbnailPath: json['thumbnailPath'] as String?,
        width: (json['width'] as num?)?.toDouble() ?? 0.0,
        height: (json['height'] as num?)?.toDouble() ?? 0.0,
        rotationDegrees: (json['rotationDegrees'] as int?) ?? 0,
        ocrText: json['ocrText'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
