import 'package:flutter/material.dart';

enum PdfToolCategory {
  organize,
  conversion,
  security,
}

enum PdfToolType {
  merge,
  split,
  compress,
  rotateReorder,
  extractPages,
  deletePages,
  pdfToImages,
  imagesToPdf,
  ocrTextExtractor,
  protectPin,
  addSignature,
  watermark,
  annotateMarkup,
  metadata,
  flatten,
}

class PdfToolDefinition {
  final PdfToolType type;
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final PdfToolCategory category;
  final String? badgeText;
  final bool isSupported;
  final String? unsupportedReason;

  const PdfToolDefinition({
    required this.type,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.category,
    this.badgeText,
    this.isSupported = true,
    this.unsupportedReason,
  });

  String get categoryTitle {
    switch (category) {
      case PdfToolCategory.organize:
        return 'Organize & Modify';
      case PdfToolCategory.conversion:
        return 'Conversion & Intelligence';
      case PdfToolCategory.security:
        return 'Security & Signatures';
    }
  }

  String get categoryId {
    switch (category) {
      case PdfToolCategory.organize:
        return 'organize';
      case PdfToolCategory.conversion:
        return 'conversion';
      case PdfToolCategory.security:
        return 'security';
    }
  }
}
