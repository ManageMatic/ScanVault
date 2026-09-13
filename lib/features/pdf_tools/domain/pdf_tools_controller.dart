import 'package:flutter/material.dart';
import 'entities/pdf_tool_definition.dart';
import 'services/recent_tools_service.dart';

export 'entities/pdf_tool_definition.dart';

class ToolCategoryGroup {
  final String id;
  final String title;
  final Color accentColor;
  final List<PdfToolDefinition> tools;

  const ToolCategoryGroup({
    required this.id,
    required this.title,
    required this.accentColor,
    required this.tools,
  });
}

/// Controller managing PDF tools discovery, live filtering, and recent tool history.
class PdfToolsController extends ChangeNotifier {
  final RecentToolsService _recentToolsService;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  List<RecentToolUsage> _recentUsages = [];
  List<RecentToolUsage> get recentUsages => _recentUsages;

  bool _isLoadingRecents = false;
  bool get isLoadingRecents => _isLoadingRecents;

  PdfToolsController({RecentToolsService? recentToolsService})
      : _recentToolsService = recentToolsService ?? RecentToolsService() {
    loadRecentTools();
  }

  static const List<PdfToolDefinition> allTools = [
    // Organize & Modify (6 Tools)
    PdfToolDefinition(
      type: PdfToolType.merge,
      id: 'merge',
      title: 'Merge PDF',
      subtitle: 'Combine multiple PDFs into a single continuous file',
      icon: Icons.call_merge_rounded,
      accentColor: Color(0xFF00685F),
      category: PdfToolCategory.organize,
    ),
    PdfToolDefinition(
      type: PdfToolType.split,
      id: 'split',
      title: 'Split PDF',
      subtitle: 'Extract specific page ranges or burst by intervals',
      icon: Icons.call_split_rounded,
      accentColor: Color(0xFF00685F),
      category: PdfToolCategory.organize,
    ),
    PdfToolDefinition(
      type: PdfToolType.compress,
      id: 'compress',
      title: 'Compress PDF',
      subtitle: 'Reduce file size while preserving high visual legibility',
      icon: Icons.zoom_in_map_rounded,
      accentColor: Color(0xFF00685F),
      category: PdfToolCategory.organize,
      badgeText: 'Fast',
    ),
    PdfToolDefinition(
      type: PdfToolType.rotateReorder,
      id: 'rotateReorder',
      title: 'Rotate & Reorder',
      subtitle: 'Adjust orientation in 90° steps or drag shuffle',
      icon: Icons.rotate_right_rounded,
      accentColor: Color(0xFF00685F),
      category: PdfToolCategory.organize,
    ),
    PdfToolDefinition(
      type: PdfToolType.extractPages,
      id: 'extractPages',
      title: 'Extract Pages',
      subtitle: 'Save selected page selections as a separate document',
      icon: Icons.content_copy_rounded,
      accentColor: Color(0xFF00685F),
      category: PdfToolCategory.organize,
    ),
    PdfToolDefinition(
      type: PdfToolType.deletePages,
      id: 'deletePages',
      title: 'Delete Pages',
      subtitle: 'Prune and scrub unwanted pages permanently',
      icon: Icons.delete_outline_rounded,
      accentColor: Color(0xFFBA1A1A),
      category: PdfToolCategory.organize,
    ),

    // Conversion & Intelligence (3 Tools)
    PdfToolDefinition(
      type: PdfToolType.pdfToImages,
      id: 'pdfToImages',
      title: 'PDF → Images',
      subtitle: 'Export pages to crisp high-res 300 DPI JPG or PNG',
      icon: Icons.image_rounded,
      accentColor: Color(0xFF006860),
      category: PdfToolCategory.conversion,
    ),
    PdfToolDefinition(
      type: PdfToolType.imagesToPdf,
      id: 'imagesToPdf',
      title: 'Images → PDF',
      subtitle: 'Assemble photos and gallery snapshots into clean document',
      icon: Icons.picture_as_pdf_rounded,
      accentColor: Color(0xFF006860),
      category: PdfToolCategory.conversion,
    ),
    PdfToolDefinition(
      type: PdfToolType.ocrTextExtractor,
      id: 'ocrTextExtractor',
      title: 'OCR Text Extractor',
      subtitle: 'Extract machine-encoded copyable text using local neural models',
      icon: Icons.document_scanner_rounded,
      accentColor: Color(0xFF00685F),
      category: PdfToolCategory.conversion,
      badgeText: 'On-Device AI',
    ),

    // Security & Signatures (4 Tools)
    PdfToolDefinition(
      type: PdfToolType.protectPin,
      id: 'protectPin',
      title: 'Protect with PIN',
      subtitle: 'Encrypt with military-grade AES-256 key derivation',
      icon: Icons.lock_outline_rounded,
      accentColor: Color(0xFF855300),
      category: PdfToolCategory.security,
      badgeText: 'AES-256',
    ),
    PdfToolDefinition(
      type: PdfToolType.watermark,
      id: 'watermark',
      title: 'Watermark',
      subtitle: 'Imprint custom confidential stamps, logos, or serial badges',
      icon: Icons.branding_watermark_rounded,
      accentColor: Color(0xFF855300),
      category: PdfToolCategory.security,
    ),
    PdfToolDefinition(
      type: PdfToolType.metadata,
      id: 'metadata',
      title: 'PDF Metadata',
      subtitle: 'Inspect and edit document title, author, and keywords',
      icon: Icons.info_outline_rounded,
      accentColor: Color(0xFF855300),
      category: PdfToolCategory.security,
    ),
    PdfToolDefinition(
      type: PdfToolType.flatten,
      id: 'flatten',
      title: 'Flatten PDF',
      subtitle: 'Lock in annotations, forms, and interactive markups',
      icon: Icons.layers_clear_rounded,
      accentColor: Color(0xFF855300),
      category: PdfToolCategory.security,
    ),
  ];

  Future<void> loadRecentTools() async {
    _isLoadingRecents = true;
    notifyListeners();
    _recentUsages = await _recentToolsService.getRecentTools(limit: 5);
    _isLoadingRecents = false;
    notifyListeners();
  }

  Future<void> recordToolUsed(String toolId) async {
    await _recentToolsService.recordToolUsage(toolId);
    await loadRecentTools();
  }

  Future<void> clearRecentTools() async {
    await _recentToolsService.clearRecentTools();
    await loadRecentTools();
  }

  PdfToolDefinition? findToolById(String toolId) {
    try {
      return allTools.firstWhere((t) => t.id == toolId);
    } catch (_) {
      return null;
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  List<PdfToolDefinition> get filteredTools {
    if (_searchQuery.isEmpty) return allTools;
    final q = _searchQuery.toLowerCase().trim();
    return allTools.where((t) {
      return t.title.toLowerCase().contains(q) ||
          t.subtitle.toLowerCase().contains(q) ||
          t.categoryTitle.toLowerCase().contains(q) ||
          t.id.toLowerCase().contains(q);
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
