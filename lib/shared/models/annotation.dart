/// Represents user annotations and markups on documents.
enum AnnotationType { highlight, underline, strikeout, freehand, textNote, stamp }

class Annotation {
  final String id;
  final String pageId;
  final AnnotationType type;
  final int colorValue;
  final double strokeWidth;
  final List<List<double>> points; // For freehand [ [x,y], ... ]
  final String? contentText;
  final DateTime createdAt;

  const Annotation({
    required this.id,
    required this.pageId,
    required this.type,
    required this.colorValue,
    this.strokeWidth = 2.0,
    this.points = const [],
    this.contentText,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'pageId': pageId,
        'type': type.name,
        'colorValue': colorValue,
        'strokeWidth': strokeWidth,
        'points': points,
        'contentText': contentText,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Annotation.fromJson(Map<String, dynamic> json) => Annotation(
        id: json['id'] as String,
        pageId: json['pageId'] as String,
        type: AnnotationType.values.byName(json['type'] as String),
        colorValue: json['colorValue'] as int,
        strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 2.0,
        points: (json['points'] as List<dynamic>?)
                ?.map((list) => (list as List<dynamic>).map((p) => (p as num).toDouble()).toList())
                .toList() ??
            [],
        contentText: json['contentText'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
