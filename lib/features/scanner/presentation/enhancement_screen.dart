import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/storage/image_pipeline_diagnostics.dart';
import '../../../core/storage/page_image_resolver.dart';
import '../../../core/storage/session_workspace_manager.dart';
import '../../image_processing/domain/image_processor.dart';
import '../domain/scanned_page_item.dart';

/// Document Enhancement, Shadow Removal, and Color Filter screen conforming to Stitch specifications.
class EnhancementScreen extends StatefulWidget {
  final ScannedPageItem page;
  final String userId;

  const EnhancementScreen({
    super.key,
    required this.page,
    this.userId = 'local_user',
  });

  @override
  State<EnhancementScreen> createState() => _EnhancementScreenState();
}

class _EnhancementScreenState extends State<EnhancementScreen> {
  late ScanFilterMode _selectedFilter;
  late double _brightness;
  late double _contrast;
  late double _shadowRemoval;
  late int _rotationDegrees;
  Uint8List? _rawBytes;
  Uint8List? _previewBytes;
  bool _isLoading = true;
  bool _isProcessing = false;
  bool _isSaving = false;
  final SessionWorkspaceManager _workspaceManager = SessionWorkspaceManager();

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.page.enhancementParams.filterMode;
    _brightness = widget.page.enhancementParams.brightness;
    _contrast = widget.page.enhancementParams.contrast;
    _shadowRemoval = widget.page.enhancementParams.shadowRemoval;
    _rotationDegrees = widget.page.enhancementParams.rotationDegrees;
    _loadAndProcess();
  }

  Future<void> _loadAndProcess() async {
    try {
      // Base image priority: working image (crop) -> original image
      // We avoid basing on already-processed filter to allow non-destructive filter switching
      String? basePath = widget.page.workingImagePath;
      if (basePath == null || basePath.isEmpty || !File(basePath).existsSync()) {
        basePath = widget.page.originalImagePath;
      }

      if (basePath.isNotEmpty) {
        final f = File(basePath);
        if (await f.exists() && await f.length() > 0) {
          _rawBytes = await f.readAsBytes();
        }
      }

      if (_rawBytes == null) {
        final resolved = await PageImageResolver.resolveCurrentImage(widget.page);
        if (resolved.isValid) {
          _rawBytes = resolved.bytes ?? (resolved.path != null ? await File(resolved.path!).readAsBytes() : null);
        }
      }

      if (_rawBytes != null) {
        _previewBytes = _rawBytes;
        if (mounted) setState(() => _isLoading = false);
      }
      _updatePreview();
    } catch (e) {
      debugPrint('Error loading image for enhancement: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _updatePreview() {
    if (_rawBytes == null) return;
    _isProcessing = true;
    final processed = ImageProcessor.processImageSync(
      rawBytes: _rawBytes!,
      params: ImageEnhancementParams(
        filterMode: _selectedFilter,
        brightness: _brightness,
        contrast: _contrast,
        shadowRemoval: _shadowRemoval,
        rotationDegrees: _rotationDegrees,
      ),
      customMaxDimension: 900, // Fast preview resolution
    );
    if (mounted) {
      setState(() {
        _previewBytes = processed;
        _isProcessing = false;
      });
    }
  }

  void _resetToDefaults() {
    setState(() {
      _selectedFilter = ScanFilterMode.original;
      _brightness = 0.0;
      _contrast = 1.0;
      _shadowRemoval = 0.0;
    });
    _updatePreview();
  }

  Future<void> _saveAndApply() async {
    if (_rawBytes == null) {
      Navigator.of(context).pop(widget.page);
      return;
    }

    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 60));

    final newParams = ImageEnhancementParams(
      filterMode: _selectedFilter,
      brightness: _brightness,
      contrast: _contrast,
      shadowRemoval: _shadowRemoval,
      rotationDegrees: _rotationDegrees,
    );

    // Apply full-quality processing for the final page state
    final finalProcessed = ImageProcessor.processImageSync(
      rawBytes: _rawBytes!,
      params: newParams,
    );

    // Save processed image to disk in stable session workspace
    String? processedPath;
    String? thumbPath;
    try {
      processedPath = await _workspaceManager.saveProcessedImage(
        userId: widget.userId,
        sessionId: widget.page.sessionId,
        pageId: widget.page.id,
        bytes: finalProcessed,
      );
      thumbPath = p.join(p.dirname(processedPath), 'thumbnail.jpg');
    } catch (e) {
      debugPrint('[ScanVault][Enhance] Error saving processed image: $e');
    }

    final updated = widget.page.copyWith(
      processedImagePath: processedPath,
      thumbnailPath: thumbPath ?? widget.page.thumbnailPath,
      cachedProcessedBytes: finalProcessed,
      enhancementParams: newParams,
    );

    ImagePipelineDiagnostics.logStage(stage: 'FILTER_OUTPUT', page: updated);

    if (mounted) {
      Navigator.of(context).pop(updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101418),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101418),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Enhance Document',
          style: AppTypography.titleMedium.copyWith(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt_rounded),
            tooltip: 'Reset to Default',
            onPressed: _resetToDefaults,
          ),
          IconButton(
            icon: const Icon(Icons.rotate_right_rounded),
            tooltip: 'Rotate 90°',
            onPressed: () {
              setState(() {
                _rotationDegrees = (_rotationDegrees + 90) % 360;
              });
              _updatePreview();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Stack(
              children: [
                Column(
                  children: [
                    // Main Preview
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A222B),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: _previewBytes != null
                                ? Image.memory(
                                    _previewBytes!,
                                    key: ValueKey('preview_${_selectedFilter}_${_brightness}_${_contrast}_$_shadowRemoval'),
                                    fit: BoxFit.contain,
                                    cacheWidth: 1200,
                                    gaplessPlayback: true,
                                    filterQuality: FilterQuality.medium,
                                  )
                                : Container(color: Colors.grey.shade900),
                          ),
                        ),
                      ),
                    ),

                    // Fine Tuning Sliders
                    Container(
                      color: const Color(0xFF161C23),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        children: [
                          // Brightness Slider
                          _buildSliderRow(
                            icon: Icons.brightness_6_rounded,
                            label: 'Brightness',
                            value: _brightness,
                            min: -0.5,
                            max: 0.5,
                            displayVal: '${(_brightness * 100).toInt()}%',
                            onChanged: (val) {
                              setState(() => _brightness = val);
                              _updatePreview();
                            },
                          ),
                          // Contrast Slider
                          _buildSliderRow(
                            icon: Icons.contrast_rounded,
                            label: 'Contrast',
                            value: _contrast,
                            min: 0.5,
                            max: 1.8,
                            displayVal: '${(_contrast * 100).toInt()}%',
                            onChanged: (val) {
                              setState(() => _contrast = val);
                              _updatePreview();
                            },
                          ),
                          // Shadow Removal Slider
                          _buildSliderRow(
                            icon: Icons.wb_shade_rounded,
                            label: 'Shadows',
                            value: _shadowRemoval,
                            min: 0.0,
                            max: 1.0,
                            displayVal: '${(_shadowRemoval * 100).toInt()}%',
                            onChanged: (val) {
                              setState(() => _shadowRemoval = val);
                              _updatePreview();
                            },
                          ),
                        ],
                      ),
                    ),

                    // Filter Selection Pills Ribbon
                    Container(
                      height: 80,
                      color: const Color(0xFF161C23),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        children: [
                          _buildFilterCard(ScanFilterMode.original, 'Original', Icons.image_outlined),
                          _buildFilterCard(ScanFilterMode.auto, 'Auto', Icons.auto_awesome_rounded),
                          _buildFilterCard(ScanFilterMode.documentClean, 'Doc Clean', Icons.document_scanner_rounded),
                          _buildFilterCard(ScanFilterMode.magicColor, 'Magic Color', Icons.palette_rounded),
                          _buildFilterCard(ScanFilterMode.grayscale, 'Grayscale', Icons.filter_b_and_w_rounded),
                          _buildFilterCard(ScanFilterMode.blackAndWhite, 'B&W Text', Icons.contrast_rounded),
                        ],
                      ),
                    ),

                    // Bottom Action Toolbar
                    Container(
                      color: const Color(0xFF14191E),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: SafeArea(
                        top: false,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton.icon(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close_rounded, color: Colors.white70),
                              label: Text('Cancel', style: AppTypography.labelLarge.copyWith(color: Colors.white70)),
                            ),
                            FilledButton.icon(
                              onPressed: (_isProcessing || _isSaving) ? null : _saveAndApply,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.check_rounded, color: Colors.white),
                              label: Text(
                                'Apply Filter',
                                style: AppTypography.labelLarge.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (_isSaving)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black54,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E242B),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                'Applying Filter & Saving...',
                                style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildSliderRow({
    required IconData icon,
    required String label,
    required double value,
    required double min,
    required double max,
    required String displayVal,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 8),
        SizedBox(
          width: 68,
          child: Text(
            label,
            style: AppTypography.labelSmall.copyWith(color: Colors.white70, fontSize: 11),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              activeColor: AppColors.primary,
              inactiveColor: Colors.white12,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 38,
          child: Text(
            displayVal,
            textAlign: TextAlign.end,
            style: AppTypography.labelSmall.copyWith(color: Colors.white70, fontSize: 11),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterCard(ScanFilterMode mode, String label, IconData icon) {
    final isSelected = _selectedFilter == mode;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = mode);
        _updatePreview();
      },
      child: Container(
        width: 76,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? AppColors.primaryFixed : Colors.white70,
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
