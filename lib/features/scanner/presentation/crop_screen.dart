import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../image_processing/domain/image_processor.dart';
import '../domain/scanned_page_item.dart';

/// Quadrilateral crop screen conforming to Google Stitch visual specifications.
class CropScreen extends StatefulWidget {
  final ScannedPageItem page;

  const CropScreen({
    super.key,
    required this.page,
  });

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  late math.Point<double> _topLeft;
  late math.Point<double> _topRight;
  late math.Point<double> _bottomRight;
  late math.Point<double> _bottomLeft;
  int _activeCorner = -1; // 0: TL, 1: TR, 2: BR, 3: BL
  Uint8List? _imageBytes;
  bool _isLoading = true;
  int _rotationDegrees = 0;
  Size _imageDisplaySize = Size.zero;

  @override
  void initState() {
    super.initState();
    _rotationDegrees = widget.page.enhancementParams.rotationDegrees;
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final file = File(widget.page.originalImagePath);
      if (await file.exists()) {
        _imageBytes = await file.readAsBytes();
      } else if (widget.page.cachedProcessedBytes != null) {
        _imageBytes = widget.page.cachedProcessedBytes;
      }
    } catch (e) {
      debugPrint('Error loading image for crop: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _initCropPoints(Size size) {
    _imageDisplaySize = size;
    if (widget.page.cropTopLeft != null) {
      _topLeft = widget.page.cropTopLeft!;
      _topRight = widget.page.cropTopRight!;
      _bottomRight = widget.page.cropBottomRight!;
      _bottomLeft = widget.page.cropBottomLeft!;
    } else {
      // Default 8% margin inset
      final insetX = size.width * 0.08;
      final insetY = size.height * 0.08;
      _topLeft = math.Point(insetX, insetY);
      _topRight = math.Point(size.width - insetX, insetY);
      _bottomRight = math.Point(size.width - insetX, size.height - insetY);
      _bottomLeft = math.Point(insetX, size.height - insetY);
    }
  }

  void _resetBounds() {
    if (_imageDisplaySize == Size.zero) return;
    setState(() {
      _topLeft = math.Point(0, 0);
      _topRight = math.Point(_imageDisplaySize.width, 0);
      _bottomRight = math.Point(_imageDisplaySize.width, _imageDisplaySize.height);
      _bottomLeft = math.Point(0, _imageDisplaySize.height);
    });
  }

  void _applyCrop() {
    if (_imageBytes == null) {
      Navigator.of(context).pop(widget.page);
      return;
    }

    final croppedBytes = ImageProcessor.cropQuadrilateral(
      rawBytes: _imageBytes!,
      topLeft: _topLeft,
      topRight: _topRight,
      bottomRight: _bottomRight,
      bottomLeft: _bottomLeft,
      displayWidth: _imageDisplaySize.width,
      displayHeight: _imageDisplaySize.height,
    );

    final updated = widget.page.copyWith(
      cachedProcessedBytes: croppedBytes,
      cropTopLeft: _topLeft,
      cropTopRight: _topRight,
      cropBottomRight: _bottomRight,
      cropBottomLeft: _bottomLeft,
      displayWidth: _imageDisplaySize.width,
      displayHeight: _imageDisplaySize.height,
      enhancementParams: widget.page.enhancementParams.copyWith(rotationDegrees: _rotationDegrees),
    );

    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Crop & Perspective',
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
            },
          ),
          IconButton(
            icon: const Icon(Icons.fullscreen_rounded),
            tooltip: 'Reset to Full Page',
            onPressed: _resetBounds,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final imgW = constraints.maxWidth;
                          final imgH = constraints.maxHeight;

                          if (_imageDisplaySize == Size.zero) {
                            _initCropPoints(Size(imgW, imgH));
                          }

                          return Stack(
                            children: [
                              // Background Base Image
                              Positioned.fill(
                                child: RotatedBox(
                                  quarterTurns: _rotationDegrees ~/ 90,
                                  child: _imageBytes != null
                                      ? Image.memory(
                                          _imageBytes!,
                                          fit: BoxFit.contain,
                                        )
                                      : Container(color: Colors.grey.shade900),
                                ),
                              ),

                              // Interactive Quadrilateral Mask and Handles
                              Positioned.fill(
                                child: GestureDetector(
                                  onPanDown: (details) {
                                    _activeCorner = _findNearestCorner(details.localPosition);
                                  },
                                  onPanUpdate: (details) {
                                    if (_activeCorner >= 0) {
                                      setState(() {
                                        final pos = details.localPosition;
                                        final clampedX = pos.dx.clamp(0.0, imgW);
                                        final clampedY = pos.dy.clamp(0.0, imgH);
                                        final newPt = math.Point(clampedX, clampedY);

                                        switch (_activeCorner) {
                                          case 0:
                                            _topLeft = newPt;
                                            break;
                                          case 1:
                                            _topRight = newPt;
                                            break;
                                          case 2:
                                            _bottomRight = newPt;
                                            break;
                                          case 3:
                                            _bottomLeft = newPt;
                                            break;
                                        }
                                      });
                                    }
                                  },
                                  onPanEnd: (_) => _activeCorner = -1,
                                  child: CustomPaint(
                                    painter: _CropOverlayPainter(
                                      topLeft: _topLeft,
                                      topRight: _topRight,
                                      bottomRight: _bottomRight,
                                      bottomLeft: _bottomLeft,
                                      activeCorner: _activeCorner,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // Bottom Action Toolbar
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
                          label: Text(
                            'Cancel',
                            style: AppTypography.labelLarge.copyWith(color: Colors.white70),
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: _applyCrop,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.check_rounded, color: Colors.white),
                          label: Text(
                            'Apply Crop',
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

  int _findNearestCorner(Offset pos) {
    final points = [_topLeft, _topRight, _bottomRight, _bottomLeft];
    var nearestIdx = -1;
    var shortestDist = double.infinity;

    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final dist = (Offset(p.x, p.y) - pos).distance;
      if (dist < 44 && dist < shortestDist) {
        shortestDist = dist;
        nearestIdx = i;
      }
    }
    return nearestIdx;
  }
}

class _CropOverlayPainter extends CustomPainter {
  final math.Point<double> topLeft;
  final math.Point<double> topRight;
  final math.Point<double> bottomRight;
  final math.Point<double> bottomLeft;
  final int activeCorner;

  _CropOverlayPainter({
    required this.topLeft,
    required this.topRight,
    required this.bottomRight,
    required this.bottomLeft,
    required this.activeCorner,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(topLeft.x, topLeft.y)
      ..lineTo(topRight.x, topRight.y)
      ..lineTo(bottomRight.x, bottomRight.y)
      ..lineTo(bottomLeft.x, bottomLeft.y)
      ..close();

    // Darkened Dim Background Outside Quad
    final bgPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final dimPath = Path.combine(PathOperation.difference, bgPath, path);
    final dimPaint = Paint()..color = Colors.black.withValues(alpha: 0.55);
    canvas.drawPath(dimPath, dimPaint);

    // Quad Border
    final borderPaint = Paint()
      ..color = AppColors.primaryFixed
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, borderPaint);

    // Corner Drag Handles
    final points = [topLeft, topRight, bottomRight, bottomLeft];
    final handleFill = Paint()..color = Colors.white;
    final handleBorder = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final radius = (i == activeCorner) ? 14.0 : 10.0;
      canvas.drawCircle(Offset(p.x, p.y), radius, handleFill);
      canvas.drawCircle(Offset(p.x, p.y), radius, handleBorder);
    }
  }

  @override
  bool shouldRepaint(covariant _CropOverlayPainter oldDelegate) => true;
}
