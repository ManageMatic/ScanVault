/// Folder for organizing documents in ScanVault.
class Folder {
  final String id;
  final String name;
  final String? colorHex;
  final String iconName;
  final int documentCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Folder({
    required this.id,
    required this.name,
    this.colorHex,
    this.iconName = 'folder',
    this.documentCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Folder copyWith({
    String? id,
    String? name,
    String? colorHex,
    String? iconName,
    int? documentCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Folder(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      iconName: iconName ?? this.iconName,
      documentCount: documentCount ?? this.documentCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorHex': colorHex,
        'iconName': iconName,
        'documentCount': documentCount,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Folder.fromJson(Map<String, dynamic> json) => Folder(
        id: json['id'] as String,
        name: json['name'] as String,
        colorHex: json['colorHex'] as String?,
        iconName: json['iconName'] as String? ?? 'folder',
        documentCount: json['documentCount'] as int? ?? 0,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
