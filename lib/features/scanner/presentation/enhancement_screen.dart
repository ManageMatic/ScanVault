import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../image_processing/domain/image_processor.dart';
import '../domain/scanned_page_item.dart';

/// Document Enhancement and Color Filter screen conforming to Stitch specifications.
class EnhancementScreen extends StatefulWidget {
  final ScannedPageItem page;

  const EnhancementScreen({
    super.key,
    required this.page,
  });

  @override
  State<EnhancementScreen> createState() => _EnhancementScreenState();
}

class _EnhancementScreenState extends State<EnhancementScreen> {
  late ScanFilterMode _selectedFilter;
  late double _brightness;
  late double _contrast;
  late int _rotationDegrees;
  Uint8List? _rawBytes;
  Uint8List? _previewBytes;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.page.enhancementParams.filterMode;
    _brightness = widget.page.enhancementParams.brightness;
    _contrast = widget.page.enhancementParams.contrast;
    _rotationDegrees = widget.page.enhancementParams.rotationDegrees;
    _loadAndProcess();
  }

  Future<void> _loadAndProcess() async {
    try {
      if (widget.page.cachedProcessedBytes != null) {
        _rawBytes = widget.page.cachedProcessedBytes;
      } else {
        final f = File(widget.page.originalImagePath);
        if (await f.exists()) {
          _rawBytes = await f.readAsBytes();
        }
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
    final processed = ImageProcessor.processImageSync(
      rawBytes: _rawBytes!,
      params: ImageEnhancementParams(
        filterMode: _selectedFilter,
        brightness: _brightness,
        contrast: _contrast,
        rotationDegrees: _rotationDegrees,
      ),
    );
    if (mounted) {
      setState(() => _previewBytes = processed);
    }
  }

  void _saveAndApply() {
    if (_previewBytes == null) {
      Navigator.of(context).pop(widget.page);
      return;
    }

    final updated = widget.page.copyWith(
      cachedProcessedBytes: _previewBytes,
      enhancementParams: ImageEnhancementParams(
        filterMode: _selectedFilter,
        brightness: _brightness,
        contrast: _contrast,
        rotationDegrees: _rotationDegrees,
      ),
    );

    Navigator.of(context).pop(updated);
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
          : Column(
              children: [
                // Main Preview
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
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
                                fit: BoxFit.contain,
                              )
                            : Container(color: Colors.grey.shade900),
                      ),
                    ),
                  ),
                ),

                // Fine Tuning Sliders
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    children: [
                      // Brightness Slider
                      Row(
                        children: [
                          const Icon(Icons.brightness_6_rounded, color: Colors.white70, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Slider(
                              value: _brightness,
                              min: -0.5,
                              max: 0.5,
                              activeColor: AppColors.primary,
                              inactiveColor: Colors.white24,
                              onChanged: (val) {
                                setState(() => _brightness = val);
                                _updatePreview();
                              },
                            ),
                          ),
                          Text(
                            '${(_brightness * 100).toInt()}%',
                            style: AppTypography.labelSmall.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                      // Contrast Slider
                      Row(
                        children: [
                          const Icon(Icons.contrast_rounded, color: Colors.white70, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Slider(
                              value: _contrast,
                              min: 0.5,
                              max: 1.5,
                              activeColor: AppColors.primary,
                              inactiveColor: Colors.white24,
                              onChanged: (val) {
                                setState(() => _contrast = val);
                                _updatePreview();
                              },
                            ),
                          ),
                          Text(
                            '${(_contrast * 100).toInt()}%',
                            style: AppTypography.labelSmall.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Filter Modes Selector
                Container(
                  height: 90,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildFilterCard(ScanFilterMode.documentClean, 'Clean', Icons.auto_fix_high_rounded),
                      _buildFilterCard(ScanFilterMode.magicColor, 'Magic Color', Icons.color_lens_rounded),
                      _buildFilterCard(ScanFilterMode.blackAndWhite, 'B&W Text', Icons.text_snippet_rounded),
                      _buildFilterCard(ScanFilterMode.grayscale, 'Grayscale', Icons.filter_b_and_w_rounded),
                      _buildFilterCard(ScanFilterMode.original, 'Original', Icons.photo_camera_rounded),
                    ],
                  ),
                ),

                // Bottom Action Buttons
                Container(
                  color: const Color(0xFF14191E),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: SafeArea(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded, color: Colors.white70),
                          label: Text('Cancel', style: AppTypography.labelLarge.copyWith(color: Colors.white70)),
                        ),
                        FilledButton.icon(
                          onPressed: _saveAndApply,
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
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.06),
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
              color: isSelected ? AppColors.primary : Colors.white70,
            ),
            const SizedBox(height: 6),
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
