import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/models/document.dart';
import '../../ocr/presentation/ocr_text_viewer_sheet.dart';
import '../../pdf_creation/domain/pdf_models.dart';

/// In-App PDF Viewer and Export Screen adhering to Google Stitch specifications.
class PdfViewerScreen extends StatefulWidget {
  final Document document;
  final VoidCallback? onDeleted;

  const PdfViewerScreen({
    super.key,
    required this.document,
    this.onDeleted,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late File _pdfFile;
  bool _fileExists = false;

  @override
  void initState() {
    super.initState();
    _pdfFile = File(widget.document.filePath);
    _checkFile();
  }

  void _checkFile() async {
    final exists = await _pdfFile.exists();
    if (mounted) {
      setState(() => _fileExists = exists);
    }
  }

  void _sharePdf() async {
    if (!await _pdfFile.exists()) return;
    final xFile = XFile(
      _pdfFile.path,
      mimeType: 'application/pdf',
      name: sanitizePdfFilename(widget.document.title),
    );
    await Share.shareXFiles([xFile], text: widget.document.title);
  }

  void _exportPdf() async {
    if (!await _pdfFile.exists()) return;

    try {
      Directory? targetDir;
      if (Platform.isAndroid) {
        targetDir = Directory('/storage/emulated/0/Download');
        if (!await targetDir.exists()) {
          targetDir = Directory('/sdcard/Download');
        }
      }

      if (targetDir == null || !await targetDir.exists()) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not access Downloads folder. Use Share to save file.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final safeName = sanitizePdfFilename(widget.document.title);
      final destPath = '${targetDir.path}/$safeName';
      await _pdfFile.copy(destPath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported to Downloads: $safeName'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e. Try Share instead.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showDocumentInfo() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Document Metadata',
                    style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildMetaRow('Title', widget.document.title),
              _buildMetaRow('Pages', '${widget.document.pageCount} page(s)'),
              _buildMetaRow('File Size', formatBytes(widget.document.fileSize)),
              _buildMetaRow('Optimization', widget.document.compressionPreset.name.toUpperCase()),
              _buildMetaRow('Created', DateFormat('MMM dd, yyyy • HH:mm').format(widget.document.createdAt)),
              _buildMetaRow('Vault Path', widget.document.filePath, isMonospace: true),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaRow(String label, String value, {bool isMonospace = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTypography.labelMedium.copyWith(color: AppColors.outline),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: isMonospace
                  ? AppTypography.bodySmall.copyWith(fontFamily: 'monospace', fontSize: 11)
                  : AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.document.title,
              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${widget.document.pageCount} page(s) • ${formatBytes(widget.document.fileSize)}',
              style: AppTypography.labelSmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share PDF',
            onPressed: _sharePdf,
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Export to Downloads',
            onPressed: _exportPdf,
          ),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'Document Details',
            onPressed: _showDocumentInfo,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: !_fileExists
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 64, color: Colors.redAccent),
                    const SizedBox(height: 16),
                    Text(
                      'PDF File Not Found',
                      style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.document.filePath,
                      style: AppTypography.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : Stack(
              children: [
                // Real-time Interactive PDF Previewer
                PdfPreview(
                  build: (format) => _pdfFile.readAsBytes(),
                  canChangeOrientation: false,
                  canChangePageFormat: false,
                  canDebug: false,
                  allowPrinting: true,
                  allowSharing: true,
                  maxPageWidth: 700,
                  pdfFileName: sanitizePdfFilename(widget.document.title),
                  loadingWidget: const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  scrollViewDecoration: BoxDecoration(
                    color: isDark ? const Color(0xFF101418) : const Color(0xFFE8ECEF),
                  ),
                ),

                // Floating Action Pill for OCR Text View
                if (widget.document.extractedOcrText != null &&
                    widget.document.extractedOcrText!.isNotEmpty)
                  Positioned(
                    bottom: 24,
                    left: 20,
                    right: 20,
                    child: Center(
                      child: FilledButton.icon(
                        onPressed: () {
                          OcrTextViewerSheet.show(
                            context: context,
                            title: widget.document.title,
                            rawText: widget.document.extractedOcrText!,
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 6,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        icon: const Icon(Icons.text_snippet_rounded, size: 18, color: Colors.white),
                        label: Text(
                          'View Extracted OCR Text',
                          style: AppTypography.labelMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
