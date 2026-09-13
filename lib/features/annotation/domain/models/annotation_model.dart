import 'package:flutter/material.dart';

/// Supported PDF Annotation types.
enum AnnotationType {
  pen,
  highlighter,
  text,
  rectangle,
  circle,
  arrow,
  underline,
  strikethrough,
}

/// Normalized point in PDF page coordinate space (0.0 to 1.0).
class NormalizedPoint {
  final double x;
  final double y;

  const NormalizedPoint(this.x, this.y);

  Map<String, dynamic> toJson() => {'x': x, 'y': y};

  factory NormalizedPoint.fromJson(Map<String, dynamic> json) =>
      NormalizedPoint((json['x'] as num).toDouble(), (json['y'] as num).toDouble());
}

/// Production model representing an annotation positioned on a specific PDF page.
class AnnotationModel {
  final String id;
  final int pageIndex; // 0-indexed
  final AnnotationType type;
  final List<NormalizedPoint> points; // For freehand pen / highlighter / arrow
  final NormalizedPoint? startPoint; // For shapes / lines
  final NormalizedPoint? endPoint;
  final String? text; // For text annotations
  final double fontSize;
  final int colorValue;
  final double opacity;
  final double strokeWidth;
  final DateTime createdAt;

  const AnnotationModel({
    required this.id,
    required this.pageIndex,
    required this.type,
    this.points = const [],
    this.startPoint,
    this.endPoint,
    this.text,
    this.fontSize = 16.0,
    required this.colorValue,
    this.opacity = 1.0,
    this.strokeWidth = 3.0,
    required this.createdAt,
  });

  Color get color => Color(colorValue).withValues(alpha: opacity);

  AnnotationModel copyWith({
    String? id,
    int? pageIndex,
    AnnotationType? type,
    List<NormalizedPoint>? points,
    NormalizedPoint? startPoint,
    NormalizedPoint? endPoint,
    String? text,
    double? fontSize,
    int? colorValue,
    double? opacity,
    double? strokeWidth,
    DateTime? createdAt,
  }) {
    return AnnotationModel(
      id: id ?? this.id,
      pageIndex: pageIndex ?? this.pageIndex,
      type: type ?? this.type,
      points: points ?? this.points,
      startPoint: startPoint ?? this.startPoint,
      endPoint: endPoint ?? this.endPoint,
      text: text ?? this.text,
      fontSize: fontSize ?? this.fontSize,
      colorValue: colorValue ?? this.colorValue,
      opacity: opacity ?? this.opacity,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'pageIndex': pageIndex,
        'type': type.name,
        'points': points.map((p) => p.toJson()).toList(),
        'startPoint': startPoint?.toJson(),
        'endPoint': endPoint?.toJson(),
        'text': text,
        'fontSize': fontSize,
        'colorValue': colorValue,
        'opacity': opacity,
        'strokeWidth': strokeWidth,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AnnotationModel.fromJson(Map<String, dynamic> json) => AnnotationModel(
        id: json['id'] as String,
        pageIndex: json['pageIndex'] as int,
        type: AnnotationType.values.byName(json['type'] as String),
        points: (json['points'] as List<dynamic>?)
                ?.map((p) => NormalizedPoint.fromJson(p as Map<String, dynamic>))
                .toList() ??
            const [],
        startPoint: json['startPoint'] != null
            ? NormalizedPoint.fromJson(json['startPoint'] as Map<String, dynamic>)
            : null,
        endPoint: json['endPoint'] != null
            ? NormalizedPoint.fromJson(json['endPoint'] as Map<String, dynamic>)
            : null,
        text: json['text'] as String?,
        fontSize: (json['fontSize'] as num?)?.toDouble() ?? 16.0,
        colorValue: json['colorValue'] as int,
        opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
        strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 3.0,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
