/// Model representing a locally saved digital signature in the user's vault library.
class DigitalSignature {
  final String id;
  final String title;
  final String imagePath;
  final DateTime createdAt;

  const DigitalSignature({
    required this.id,
    required this.title,
    required this.imagePath,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'imagePath': imagePath,
        'createdAt': createdAt.toIso8601String(),
      };

  factory DigitalSignature.fromJson(Map<String, dynamic> json) => DigitalSignature(
        id: json['id'] as String,
        title: json['title'] as String,
        imagePath: json['imagePath'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
