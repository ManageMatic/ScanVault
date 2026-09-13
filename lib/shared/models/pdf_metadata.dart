/// Metadata describing a PDF document.
class PDFMetadata {
  final String? title;
  final String? author;
  final String? subject;
  final List<String> keywords;
  final String creator;
  final String producer;
  final DateTime? creationDate;
  final DateTime? modificationDate;
  final bool isEncrypted;
  final int pageCount;
  final int fileSize;

  const PDFMetadata({
    this.title,
    this.author,
    this.subject,
    this.keywords = const [],
    this.creator = 'ScanVault',
    this.producer = 'ScanVault PDF Engine',
    this.creationDate,
    this.modificationDate,
    this.isEncrypted = false,
    this.pageCount = 0,
    this.fileSize = 0,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'author': author,
        'subject': subject,
        'keywords': keywords,
        'creator': creator,
        'producer': producer,
        'creationDate': creationDate?.toIso8601String(),
        'modificationDate': modificationDate?.toIso8601String(),
        'isEncrypted': isEncrypted,
        'pageCount': pageCount,
        'fileSize': fileSize,
      };

  factory PDFMetadata.fromJson(Map<String, dynamic> json) => PDFMetadata(
        title: json['title'] as String?,
        author: json['author'] as String?,
        subject: json['subject'] as String?,
        keywords: (json['keywords'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        creator: json['creator'] as String? ?? 'ScanVault',
        producer: json['producer'] as String? ?? 'ScanVault PDF Engine',
        creationDate: json['creationDate'] != null ? DateTime.parse(json['creationDate'] as String) : null,
        modificationDate: json['modificationDate'] != null ? DateTime.parse(json['modificationDate'] as String) : null,
        isEncrypted: json['isEncrypted'] as bool? ?? false,
        pageCount: json['pageCount'] as int? ?? 0,
        fileSize: json['fileSize'] as int? ?? 0,
      );
}
