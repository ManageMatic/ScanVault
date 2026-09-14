import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../image_processing/domain/document_detector.dart';
import '../../image_processing/domain/image_processor.dart';
import '../domain/scanned_page_item.dart';

import 'package:path/path.dart' as p;
import '../../../core/storage/page_image_resolver.dart';
import '../../../core/storage/session_workspace_manager.dart';

/// Quadrilateral crop and perspective screen conforming to Google Stitch specifications.
class CropScreen extends StatefulWidget {
  final ScannedPageItem page;
  final String userId;

  const CropScreen({
    super.key,
    required this.page,
    this.userId = 'local_user',
  });

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  // Stored in normalized (0.0 to 1.0) space
  math.Point<double> _normTopLeft = const math.Point(0.05, 0.05);
  math.Point<double> _normTopRight = const math.Point(0.95, 0.05);
  math.Point<double> _normBottomRight = const math.Point(0.95, 0.95);
  math.Point<double> _normBottomLeft = const math.Point(0.05, 0.95);

  int _activeCorner = -1; // 0: TL, 1: TR, 2: BR, 3: BL
  Uint8List? _imageBytes;
  bool _isLoading = true;
  bool _isDetecting = false;
  bool _isApplyingCrop = false;
  int _rotationDegrees = 0;
  Size _imageDisplaySize = Size.zero;
  DocumentDetectionResult? _detectionResult;
  final SessionWorkspaceManager _workspaceManager = SessionWorkspaceManager();

  @override
  void initState() {
    super.initState();
    _rotationDegrees = widget.page.enhancementParams.rotationDegrees;
    _loadImageAndDetect();
  }

  Future<void> _loadImageAndDetect() async {
    try {
      final bestPath = PageImageResolver.resolveCurrentImagePath(widget.page);
      if (bestPath != null) {
        final file = File(bestPath);
        if (await file.exists() && await file.length() > 0) {
          _imageBytes = await file.readAsBytes();
        }
      }

      if (_imageBytes == null && widget.page.cachedProcessedBytes != null && widget.page.cachedProcessedBytes!.isNotEmpty) {
        _imageBytes = widget.page.cachedProcessedBytes;
      }

      if (_imageBytes != null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }

        if (widget.page.cropTopLeft != null) {
          // Restore previously saved normalized crop points
          _normTopLeft = widget.page.cropTopLeft!;
          _normTopRight = widget.page.cropTopRight!;
          _normBottomRight = widget.page.cropBottomRight!;
          _normBottomLeft = widget.page.cropBottomLeft!;
        } else {
          // Run Automatic Document Detection in background
          _isDetecting = true;
          if (mounted) setState(() {});

          try {
            const detector = EdgeDocumentDetector();
            final result = await detector.detectFromBytes(_imageBytes!);
            if (mounted) {
              setState(() {
                _detectionResult = result;
                _normTopLeft = result.topLeft;
                _normTopRight = result.topRight;
                _normBottomRight = result.bottomRight;
                _normBottomLeft = result.bottomLeft;
              });
            }
          } catch (e) {
            debugPrint('Document detection fallback: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading image for crop: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isDetecting = false;
        });
      }
    }
  }

  void _runAutoDetection() async {
    if (_imageBytes == null) return;
    setState(() => _isDetecting = true);

    const detector = EdgeDocumentDetector();
    final result = await detector.detectFromBytes(_imageBytes!);

    if (mounted) {
      setState(() {
        _detectionResult = result;
        _normTopLeft = result.topLeft;
        _normTopRight = result.topRight;
        _normBottomRight = result.bottomRight;
        _normBottomLeft = result.bottomLeft;
        _isDetecting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.confidenceLevel == DetectionConfidence.high
                ? 'Document boundaries auto-detected'
                : 'Edge boundary proposed • Adjust handles if needed',
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _resetBounds() {
    setState(() {
      _normTopLeft = const math.Point(0.0, 0.0);
      _normTopRight = const math.Point(1.0, 0.0);
      _normBottomRight = const math.Point(1.0, 1.0);
      _normBottomLeft = const math.Point(0.0, 1.0);
      _detectionResult = null;
    });
  }

  Future<void> _applyCrop() async {
    if (_imageBytes == null) {
      Navigator.of(context).pop(widget.page);
      return;
    }

    setState(() => _isApplyingCrop = true);
    await Future.delayed(const Duration(milliseconds: 60));

    final croppedBytes = ImageProcessor.cropQuadrilateral(
      rawBytes: _imageBytes!,
      topLeft: _normTopLeft,
      topRight: _normTopRight,
      bottomRight: _normBottomRight,
      bottomLeft: _normBottomLeft,
      displayWidth: 1.0,
      displayHeight: 1.0,
    );

    // Save working image to disk in stable session workspace
    String? workingPath;
    String? thumbPath;
    try {
      workingPath = await _workspaceManager.saveWorkingImage(
        userId: widget.userId,
        sessionId: widget.page.sessionId,
        pageId: widget.page.id,
        bytes: croppedBytes,
      );
      thumbPath = p.join(p.dirname(workingPath), 'thumbnail.jpg');
    } catch (e) {
      debugPrint('[ScanVault][Crop] Error saving working image: $e');
    }

    final updated = widget.page.copyWith(
      workingImagePath: workingPath,
      thumbnailPath: thumbPath ?? widget.page.thumbnailPath,
      cachedProcessedBytes: croppedBytes,
      cropTopLeft: _normTopLeft,
      cropTopRight: _normTopRight,
      cropBottomRight: _normBottomRight,
      cropBottomLeft: _normBottomLeft,
      displayWidth: _imageDisplaySize.width,
      displayHeight: _imageDisplaySize.height,
      enhancementParams: widget.page.enhancementParams.copyWith(rotationDegrees: _rotationDegrees),
    );

    if (mounted) {
      Navigator.of(context).pop(updated);
    }
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
            icon: const Icon(Icons.auto_fix_high_rounded),
            tooltip: 'Auto-detect Edges',
            onPressed: _isDetecting ? null : _runAutoDetection,
          ),
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
          : Stack(
              children: [
                Column(
                  children: [
                    // Detection Confidence Status Pill
                    if (_detectionResult != null)
                      Container(
                        margin: const EdgeInsets.only(top: 6, bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _detectionResult!.confidenceLevel == DetectionConfidence.high
                              ? AppColors.primary.withValues(alpha: 0.2)
                              : Colors.white12,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _detectionResult!.confidenceLevel == DetectionConfidence.high
                                ? AppColors.primary
                                : Colors.white24,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _detectionResult!.confidenceLevel == DetectionConfidence.high
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.tune_rounded,
                              size: 14,
                              color: _detectionResult!.confidenceLevel == DetectionConfidence.high
                                  ? AppColors.primaryFixed
                                  : Colors.white70,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _detectionResult!.confidenceLevel == DetectionConfidence.high
                                  ? 'Auto-detected Boundary'
                                  : 'Adjust Corners Manually',
                              style: AppTypography.labelSmall.copyWith(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),

                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final imgW = constraints.maxWidth;
                              final imgH = constraints.maxHeight;

                              if (imgW > 0 && imgH > 0) {
                                _imageDisplaySize = Size(imgW, imgH);
                              }

                              // Denormalize points to current render box constraints
                              final screenTl = math.Point(_normTopLeft.x * imgW, _normTopLeft.y * imgH);
                              final screenTr = math.Point(_normTopRight.x * imgW, _normTopRight.y * imgH);
                              final screenBr = math.Point(_normBottomRight.x * imgW, _normBottomRight.y * imgH);
                              final screenBl = math.Point(_normBottomLeft.x * imgW, _normBottomLeft.y * imgH);

                              return SizedBox(
                                width: imgW,
                                height: imgH,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    // Background Image
                                    Positioned.fill(
                                      child: RotatedBox(
                                        quarterTurns: _rotationDegrees ~/ 90,
                                        child: _imageBytes != null
                                            ? Image.memory(
                                                _imageBytes!,
                                                fit: BoxFit.contain,
                                                cacheWidth: 1200,
                                                gaplessPlayback: true,
                                                filterQuality: FilterQuality.medium,
                                              )
                                            : Container(color: Colors.grey.shade900),
                                      ),
                                    ),

                                    // Interactive Quadrilateral Mask and Draggable Handles
                                    Positioned.fill(
                                      child: GestureDetector(
                                        onPanDown: (details) {
                                          _activeCorner = _findNearestCorner(
                                            details.localPosition,
                                            screenTl,
                                            screenTr,
                                            screenBr,
                                            screenBl,
                                          );
                                        },
                                        onPanUpdate: (details) {
                                          if (_activeCorner >= 0 && imgW > 0 && imgH > 0) {
                                            setState(() {
                                              final pos = details.localPosition;
                                              final clampedNormX = (pos.dx / imgW).clamp(0.0, 1.0);
                                              final clampedNormY = (pos.dy / imgH).clamp(0.0, 1.0);
                                              final newNormPt = math.Point(clampedNormX, clampedNormY);

                                              switch (_activeCorner) {
                                                case 0:
                                                  _normTopLeft = newNormPt;
                                                  break;
                                                case 1:
                                                  _normTopRight = newNormPt;
                                                  break;
                                                case 2:
                                                  _normBottomRight = newNormPt;
                                                  break;
                                                case 3:
                                                  _normBottomLeft = newNormPt;
                                                  break;
                                              }
                                            });
                                          }
                                        },
                                        onPanEnd: (_) => setState(() => _activeCorner = -1),
                                        child: CustomPaint(
                                          painter: _CropOverlayPainter(
                                            topLeft: screenTl,
                                            topRight: screenTr,
                                            bottomRight: screenBr,
                                            bottomLeft: screenBl,
                                            activeCorner: _activeCorner,
                                          ),
                                        ),
                                      ),
                                    ),

                                    if (_isDetecting)
                                      Positioned.fill(
                                        child: Container(
                                          color: Colors.black45,
                                          child: const Center(
                                            child: CircularProgressIndicator(color: AppColors.primary),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    // Bottom Action Bar
                    Container(
                      height: 72,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      color: const Color(0xFF14191E),
                      child: SafeArea(
                        top: false,
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
                              onPressed: _isApplyingCrop ? null : _applyCrop,
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
                if (_isApplyingCrop)
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
                                'Applying Perspective Crop...',
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

  int _findNearestCorner(
    Offset pos,
    math.Point<double> tl,
    math.Point<double> tr,
    math.Point<double> br,
    math.Point<double> bl,
  ) {
    final points = [tl, tr, br, bl];
    var nearestIdx = -1;
    var shortestDist = double.infinity;

    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final dist = (Offset(p.x, p.y) - pos).distance;
      if (dist < 48 && dist < shortestDist) {
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

    // Grid Guidelines (Rule of thirds inside the quad)
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (var t = 0.33; t <= 0.67; t += 0.33) {
      final pTop = _lerp(topLeft, topRight, t);
      final pBot = _lerp(bottomLeft, bottomRight, t);
      canvas.drawLine(Offset(pTop.x, pTop.y), Offset(pBot.x, pBot.y), gridPaint);

      final pLeft = _lerp(topLeft, bottomLeft, t);
      final pRight = _lerp(topRight, bottomRight, t);
      canvas.drawLine(Offset(pLeft.x, pLeft.y), Offset(pRight.x, pRight.y), gridPaint);
    }

    // Corner Drag Handles
    final points = [topLeft, topRight, bottomRight, bottomLeft];
    final handleFill = Paint()..color = Colors.white;
    final handleBorder = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final radius = (i == activeCorner) ? 15.0 : 11.0;
      canvas.drawCircle(Offset(p.x, p.y), radius, handleFill);
      canvas.drawCircle(Offset(p.x, p.y), radius, handleBorder);
    }
  }

  static math.Point<double> _lerp(math.Point<double> a, math.Point<double> b, double t) {
    return math.Point(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t);
  }

  @override
  bool shouldRepaint(covariant _CropOverlayPainter oldDelegate) => true;
}
