/// Represents on-device OCR recognition results.
class OCRBlock {
  final String text;
  final double confidence;
  final List<double> boundingBox; // [x, y, width, height]

  const OCRBlock({
    required this.text,
    required this.confidence,
    this.boundingBox = const [],
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'confidence': confidence,
        'boundingBox': boundingBox,
      };

  factory OCRBlock.fromJson(Map<String, dynamic> json) => OCRBlock(
        text: json['text'] as String,
        confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
        boundingBox: (json['boundingBox'] as List<dynamic>?)
                ?.map((e) => (e as num).toDouble())
                .toList() ??
            [],
      );
}

class OCRResult {
  final String fullText;
  final String language;
  final List<OCRBlock> blocks;
  final DateTime processedAt;

  const OCRResult({
    required this.fullText,
    this.language = 'en',
    this.blocks = const [],
    required this.processedAt,
  });

  Map<String, dynamic> toJson() => {
        'fullText': fullText,
        'language': language,
        'blocks': blocks.map((b) => b.toJson()).toList(),
        'processedAt': processedAt.toIso8601String(),
      };

  factory OCRResult.fromJson(Map<String, dynamic> json) => OCRResult(
        fullText: json['fullText'] as String,
        language: json['language'] as String? ?? 'en',
        blocks: (json['blocks'] as List<dynamic>?)
                ?.map((e) => OCRBlock.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        processedAt: DateTime.parse(json['processedAt'] as String),
      );
}
