import 'document_page.dart';
import 'pdf_metadata.dart';

/// Document type enumeration.
enum DocumentType { scan, pdf, image, importedDoc }

/// Primary document entity in ScanVault.
class Document {
  final String id;
  final String title;
  final DocumentType type;
  final List<DocumentPage> pages;
  final String? pdfPath;
  final String? thumbnailPath;
  final String? folderId;
  final List<String> tags;
  final int fileSize; // In bytes
  final bool isFavorite;
  final bool isEncrypted;
  final bool hasOcr;
  final String? extractedOcrText;
  final PDFMetadata? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Document({
    required this.id,
    required this.title,
    this.type = DocumentType.scan,
    this.pages = const [],
    this.pdfPath,
    this.thumbnailPath,
    this.folderId,
    this.tags = const [],
    this.fileSize = 0,
    this.isFavorite = false,
    this.isEncrypted = false,
    this.hasOcr = false,
    this.extractedOcrText,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  int get pageCount => pages.isNotEmpty ? pages.length : (metadata?.pageCount ?? 1);

  Document copyWith({
    String? id,
    String? title,
    DocumentType? type,
    List<DocumentPage>? pages,
    String? pdfPath,
    String? thumbnailPath,
    String? folderId,
    List<String>? tags,
    int? fileSize,
    bool? isFavorite,
    bool? isEncrypted,
    bool? hasOcr,
    String? extractedOcrText,
    PDFMetadata? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Document(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      pages: pages ?? this.pages,
      pdfPath: pdfPath ?? this.pdfPath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      folderId: folderId ?? this.folderId,
      tags: tags ?? this.tags,
      fileSize: fileSize ?? this.fileSize,
      isFavorite: isFavorite ?? this.isFavorite,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      hasOcr: hasOcr ?? this.hasOcr,
      extractedOcrText: extractedOcrText ?? this.extractedOcrText,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type.name,
        'pages': pages.map((p) => p.toJson()).toList(),
        'pdfPath': pdfPath,
        'thumbnailPath': thumbnailPath,
        'folderId': folderId,
        'tags': tags,
        'fileSize': fileSize,
        'isFavorite': isFavorite,
        'isEncrypted': isEncrypted,
        'hasOcr': hasOcr,
        'extractedOcrText': extractedOcrText,
        'metadata': metadata?.toJson(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Document.fromJson(Map<String, dynamic> json) => Document(
        id: json['id'] as String,
        title: json['title'] as String,
        type: DocumentType.values.byName(json['type'] as String? ?? 'scan'),
        pages: (json['pages'] as List<dynamic>?)
                ?.map((e) => DocumentPage.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        pdfPath: json['pdfPath'] as String?,
        thumbnailPath: json['thumbnailPath'] as String?,
        folderId: json['folderId'] as String?,
        tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        fileSize: (json['fileSize'] as int?) ?? 0,
        isFavorite: (json['isFavorite'] as bool?) ?? false,
        isEncrypted: (json['isEncrypted'] as bool?) ?? false,
        hasOcr: (json['hasOcr'] as bool?) ?? false,
        extractedOcrText: json['extractedOcrText'] as String?,
        metadata: json['metadata'] != null
            ? PDFMetadata.fromJson(json['metadata'] as Map<String, dynamic>)
            : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
