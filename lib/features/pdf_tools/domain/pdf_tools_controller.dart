import 'package:flutter/material.dart';

enum PdfToolType {
  merge,
  split,
  compress,
  rotate,
  extractPages,
  imagesToPdf,
  pdfToImages,
  protect,
  watermark,
  ocrRecognize,
}

class PdfToolItem {
  final PdfToolType type;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final String category;

  const PdfToolItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.category,
  });
}

/// Controller managing PDF tools discovery and execution state.
class PdfToolsController extends ChangeNotifier {
  static const List<PdfToolItem> tools = [
    PdfToolItem(
      type: PdfToolType.merge,
      title: 'Merge PDFs',
      subtitle: 'Combine multiple documents into one',
      icon: Icons.call_merge_rounded,
      accentColor: Color(0xFF00685F),
      category: 'Organize',
    ),
    PdfToolItem(
      type: PdfToolType.split,
      title: 'Split PDF',
      subtitle: 'Extract page ranges into separate files',
      icon: Icons.call_split_rounded,
      accentColor: Color(0xFF1976D2),
      category: 'Organize',
    ),
    PdfToolItem(
      type: PdfToolType.compress,
      title: 'Compress PDF',
      subtitle: 'Reduce file size without loss of text',
      icon: Icons.compress_rounded,
      accentColor: Color(0xFF855300),
      category: 'Optimize',
    ),
    PdfToolItem(
      type: PdfToolType.imagesToPdf,
      title: 'Images to PDF',
      subtitle: 'Convert gallery photos into clean PDF',
      icon: Icons.collections_rounded,
      accentColor: Color(0xFF7E57C2),
      category: 'Convert',
    ),
    PdfToolItem(
      type: PdfToolType.pdfToImages,
      title: 'PDF to Images',
      subtitle: 'Extract high-res PNG / JPEG pages',
      icon: Icons.image_rounded,
      accentColor: Color(0xFF008378),
      category: 'Convert',
    ),
    PdfToolItem(
      type: PdfToolType.ocrRecognize,
      title: 'OCR Text Recognition',
      subtitle: 'Convert scans into searchable text',
      icon: Icons.text_fields_rounded,
      accentColor: Color(0xFF006860),
      category: 'AI Vision',
    ),
    PdfToolItem(
      type: PdfToolType.rotate,
      title: 'Rotate Pages',
      subtitle: 'Fix orientation for 90°, 180°, 270°',
      icon: Icons.rotate_right_rounded,
      accentColor: Color(0xFF2E7D32),
      category: 'Edit',
    ),
    PdfToolItem(
      type: PdfToolType.extractPages,
      title: 'Extract Pages',
      subtitle: 'Select specific pages to save separately',
      icon: Icons.filter_none_rounded,
      accentColor: Color(0xFFE53935),
      category: 'Edit',
    ),
    PdfToolItem(
      type: PdfToolType.protect,
      title: 'Protect PDF',
      subtitle: 'Set open & edit password protection',
      icon: Icons.lock_outline_rounded,
      accentColor: Color(0xFF455A64),
      category: 'Security',
    ),
    PdfToolItem(
      type: PdfToolType.watermark,
      title: 'Add Watermark',
      subtitle: 'Apply custom text or confidential stamp',
      icon: Icons.branding_watermark_rounded,
      accentColor: Color(0xFFD81B60),
      category: 'Security',
    ),
  ];
}
