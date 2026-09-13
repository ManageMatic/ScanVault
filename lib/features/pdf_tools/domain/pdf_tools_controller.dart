import 'package:flutter/material.dart';

enum PdfToolType {
  // Organize & Modify
  merge,
  split,
  compress,
  rotateReorder,
  extractPages,
  deletePages,

  // Conversion & Intelligence
  pdfToImages,
  imagesToPdf,
  ocrTextExtractor,

  // Security & Signatures
  protectPin,
  addSignature,
  watermark,
  annotateMarkup,
}

class PdfToolItem {
  final PdfToolType type;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final String categoryId; // 'organize', 'conversion', 'security'
  final String categoryTitle;
  final String? badgeText;

  const PdfToolItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.categoryId,
    required this.categoryTitle,
    this.badgeText,
  });
}

class ToolCategoryGroup {
  final String id;
  final String title;
  final Color accentColor;
  final List<PdfToolItem> tools;

  const ToolCategoryGroup({
    required this.id,
    required this.title,
    required this.accentColor,
    required this.tools,
  });
}

/// Controller managing PDF tools discovery, filtering, and execution state.
class PdfToolsController extends ChangeNotifier {
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  static const List<PdfToolItem> allTools = [
    // Organize & Modify (6 Tools)
    PdfToolItem(
      type: PdfToolType.merge,
      title: 'Merge PDF',
      subtitle: 'Combine multiple PDFs into a single continuous file',
      icon: Icons.call_merge_rounded,
      accentColor: Color(0xFF00685F),
      categoryId: 'organize',
      categoryTitle: 'Organize & Modify',
    ),
    PdfToolItem(
      type: PdfToolType.split,
      title: 'Split PDF',
      subtitle: 'Extract specific pages or burst by intervals',
      icon: Icons.call_split_rounded,
      accentColor: Color(0xFF00685F),
      categoryId: 'organize',
      categoryTitle: 'Organize & Modify',
    ),
    PdfToolItem(
      type: PdfToolType.compress,
      title: 'Compress PDF',
      subtitle: 'Reduce file size while preserving high visual legibility',
      icon: Icons.zoom_in_map_rounded,
      accentColor: Color(0xFF00685F),
      categoryId: 'organize',
      categoryTitle: 'Organize & Modify',
      badgeText: 'Fast',
    ),
    PdfToolItem(
      type: PdfToolType.rotateReorder,
      title: 'Rotate & Reorder',
      subtitle: 'Adjust orientation in 90° steps or drag shuffle',
      icon: Icons.rotate_right_rounded,
      accentColor: Color(0xFF00685F),
      categoryId: 'organize',
      categoryTitle: 'Organize & Modify',
    ),
    PdfToolItem(
      type: PdfToolType.extractPages,
      title: 'Extract Pages',
      subtitle: 'Save selected page selections as a separate document',
      icon: Icons.content_copy_rounded,
      accentColor: Color(0xFF00685F),
      categoryId: 'organize',
      categoryTitle: 'Organize & Modify',
    ),
    PdfToolItem(
      type: PdfToolType.deletePages,
      title: 'Delete Pages',
      subtitle: 'Prune and scrub unwanted pages permanently',
      icon: Icons.delete_outline_rounded,
      accentColor: Color(0xFFBA1A1A),
      categoryId: 'organize',
      categoryTitle: 'Organize & Modify',
    ),

    // Conversion & Intelligence (3 Tools)
    PdfToolItem(
      type: PdfToolType.pdfToImages,
      title: 'PDF → Images',
      subtitle: 'Export pages to crisp high-res 300 DPI JPG or PNG',
      icon: Icons.image_rounded,
      accentColor: Color(0xFF006860),
      categoryId: 'conversion',
      categoryTitle: 'Conversion & Intelligence',
    ),
    PdfToolItem(
      type: PdfToolType.imagesToPdf,
      title: 'Images → PDF',
      subtitle: 'Assemble photos and gallery snapshots into clean document',
      icon: Icons.picture_as_pdf_rounded,
      accentColor: Color(0xFF006860),
      categoryId: 'conversion',
      categoryTitle: 'Conversion & Intelligence',
    ),
    PdfToolItem(
      type: PdfToolType.ocrTextExtractor,
      title: 'OCR Text Extractor',
      subtitle: 'Extract machine-encoded copyable text using local neural models',
      icon: Icons.document_scanner_rounded,
      accentColor: Color(0xFF00685F),
      categoryId: 'conversion',
      categoryTitle: 'Conversion & Intelligence',
      badgeText: 'On-Device AI',
    ),

    // Security & Signatures (4 Tools)
    PdfToolItem(
      type: PdfToolType.protectPin,
      title: 'Protect with PIN',
      subtitle: 'Encrypt with military-grade key derivation & permission locks',
      icon: Icons.lock_outline_rounded,
      accentColor: Color(0xFF855300),
      categoryId: 'security',
      categoryTitle: 'Security & Signatures',
      badgeText: 'AES-256',
    ),
    PdfToolItem(
      type: PdfToolType.addSignature,
      title: 'Add Signature',
      subtitle: 'Digitally sign using stylus, touch ink, or saved biometric signature',
      icon: Icons.draw_rounded,
      accentColor: Color(0xFF855300),
      categoryId: 'security',
      categoryTitle: 'Security & Signatures',
    ),
    PdfToolItem(
      type: PdfToolType.watermark,
      title: 'Watermark',
      subtitle: 'Imprint custom confidential stamps, logos, or serial badges',
      icon: Icons.branding_watermark_rounded,
      accentColor: Color(0xFF855300),
      categoryId: 'security',
      categoryTitle: 'Security & Signatures',
    ),
    PdfToolItem(
      type: PdfToolType.annotateMarkup,
      title: 'Annotate & Markup',
      subtitle: 'Highlight clauses, freehand pencil annotations, and adhesive notes',
      icon: Icons.border_color_rounded,
      accentColor: Color(0xFF855300),
      categoryId: 'security',
      categoryTitle: 'Security & Signatures',
    ),
  ];

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  List<PdfToolItem> get filteredTools {
    if (_searchQuery.isEmpty) return allTools;
    final q = _searchQuery.toLowerCase().trim();
    return allTools.where((t) {
      return t.title.toLowerCase().contains(q) ||
          t.subtitle.toLowerCase().contains(q) ||
          t.categoryTitle.toLowerCase().contains(q);
    }).toList();
  }

  List<ToolCategoryGroup> get groupedCategories {
    final filtered = filteredTools;
    const categories = [
      ('organize', 'Organize & Modify', Color(0xFF00685F)),
      ('conversion', 'Conversion & Intelligence', Color(0xFF248279)),
      ('security', 'Security & Signatures', Color(0xFFFEA619)),
    ];

    final List<ToolCategoryGroup> groups = [];
    for (final (id, title, color) in categories) {
      final items = filtered.where((t) => t.categoryId == id).toList();
      if (items.isNotEmpty) {
        groups.add(ToolCategoryGroup(
          id: id,
          title: title,
          accentColor: color,
          tools: items,
        ));
      }
    }
    return groups;
  }
}
