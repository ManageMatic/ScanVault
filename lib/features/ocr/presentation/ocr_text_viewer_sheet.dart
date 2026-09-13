import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/models/ocr_result.dart';

/// Modal sheet displaying extracted OCR text with search, copy, and export capabilities.
class OcrTextViewerSheet extends StatefulWidget {
  final String title;
  final String rawText;
  final OCRResult? ocrResult;

  const OcrTextViewerSheet({
    super.key,
    required this.title,
    required this.rawText,
    this.ocrResult,
  });

  static Future<void> show({
    required BuildContext context,
    required String title,
    required String rawText,
    OCRResult? ocrResult,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OcrTextViewerSheet(
        title: title,
        rawText: rawText,
        ocrResult: ocrResult,
      ),
    );
  }

  @override
  State<OcrTextViewerSheet> createState() => _OcrTextViewerSheetState();
}

class _OcrTextViewerSheetState extends State<OcrTextViewerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  int get _wordCount {
    if (widget.rawText.trim().isEmpty) return 0;
    return widget.rawText.trim().split(RegExp(r'\s+')).length;
  }

  int get _charCount => widget.rawText.length;

  void _copyAllToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: widget.rawText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Extracted text copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasText = widget.rawText.trim().isNotEmpty;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161B22) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: const [
              BoxShadow(color: Colors.black38, blurRadius: 24, offset: Offset(0, -4)),
            ],
          ),
          child: Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.document_scanner_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$_wordCount words • $_charCount characters • 100% Offline',
                            style: AppTypography.labelSmall.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isSearching ? Icons.close_rounded : Icons.search_rounded,
                        color: _isSearching ? AppColors.primary : null,
                      ),
                      tooltip: 'Search in Text',
                      onPressed: () {
                        setState(() {
                          _isSearching = !_isSearching;
                          if (!_isSearching) {
                            _searchQuery = '';
                            _searchController.clear();
                          }
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_all_rounded, color: AppColors.primary),
                      tooltip: 'Copy Full Text',
                      onPressed: hasText ? () => _copyAllToClipboard(context) : null,
                    ),
                  ],
                ),
              ),

              // Search Input Bar (if open)
              if (_isSearching)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E2630) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: AppTypography.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Find in extracted text...',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    ),
                  ),
                ),

              const Divider(height: 1),

              // Main Text Body
              Expanded(
                child: hasText
                    ? SingleChildScrollView(
                        controller: scrollController,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        child: SelectableText(
                          widget.rawText,
                          style: AppTypography.bodyLarge.copyWith(
                            height: 1.6,
                            color: Theme.of(context).colorScheme.onSurface,
                            letterSpacing: 0.2,
                          ),
                        ),
                      )
                    : Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.text_snippet_outlined,
                                size: 56,
                                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'No text recognized',
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'The scanned document did not contain clear typed or printed characters.',
                                textAlign: TextAlign.center,
                                style: AppTypography.bodySmall.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),

              // Bottom Action Bar
              if (hasText)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF14191F) : const Color(0xFFF8FAFC),
                    border: Border(
                      top: BorderSide(
                        color: isDark ? Colors.white10 : Colors.black12,
                      ),
                    ),
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _copyAllToClipboard(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.copy_rounded, size: 18),
                            label: const Text('Copy to Clipboard'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                          label: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
