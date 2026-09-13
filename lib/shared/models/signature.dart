/// Represents saved digital signatures.
class Signature {
  final String id;
  final String label;
  final String imagePath;
  final DateTime createdAt;

  const Signature({
    required this.id,
    required this.label,
    required this.imagePath,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'imagePath': imagePath,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Signature.fromJson(Map<String, dynamic> json) => Signature(
        id: json['id'] as String,
        label: json['label'] as String,
        imagePath: json['imagePath'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
