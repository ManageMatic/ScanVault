import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/models/scan_session.dart';
import '../domain/scanner_controller.dart';
import 'crop_screen.dart';
import 'session_review_screen.dart';
import 'widgets/camera_controls.dart';
import 'widgets/camera_viewfinder_overlay.dart';

/// Production Camera Scanner Screen conforming to Stitch camera UI specifications.
class ScannerScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final String userId;

  const ScannerScreen({
    super.key,
    this.onBack,
    this.userId = 'local_user',
  });

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  late final ScannerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScannerController(userId: widget.userId);
    _controller.addListener(_onStateChanged);
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.removeListener(_onStateChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  void _handleCapture() async {
    final page = await _controller.capture();
    if (!mounted || page == null) return;

    if (_controller.mode == ScanMode.single) {
      // Direct to Crop / Review
      final cropped = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CropScreen(page: page, userId: widget.userId),
        ),
      );
      if (cropped != null) {
        _controller.updatePage(cropped);
      }
      _openReview();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Page ${_controller.pageCount} captured • Ready for review'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleGalleryImport() async {
    final imported = await _controller.importFromGallery();
    if (imported.isNotEmpty && mounted) {
      _openReview();
    }
  }

  void _openReview() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SessionReviewScreen(
          scannerController: _controller,
          userId: widget.userId,
          onSaved: () {
            Navigator.of(context).pop(); // pop review screen
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              Navigator.of(context).pop(); // pop scanner
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Real Camera Viewfinder or Fallback
          if (_controller.isInitialized && _controller.cameraController != null)
            Center(
              child: CameraPreview(_controller.cameraController!),
            )
          else
            Container(
              color: const Color(0xFF14191E),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.document_scanner_rounded,
                      size: 80,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _controller.hasPermission
                          ? 'Starting Camera Feed...'
                          : 'Camera permission required to scan',
                      style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),

          // Viewfinder Overlays & Document Alignment Brackets
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: CameraViewfinderOverlay(isAutoCapture: _controller.autoCapture),
            ),
          ),

          // Top App Bar Controls
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Close Button
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                      onPressed: () {
                        if (widget.onBack != null) {
                          widget.onBack!();
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                    ),

                    // Auto / Manual Capture Pill
                    GestureDetector(
                      onTap: _controller.toggleAutoCapture,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: _controller.autoCapture ? AppColors.primary : Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _controller.autoCapture ? Icons.flash_auto_rounded : Icons.touch_app_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _controller.autoCapture ? 'AUTO' : 'MANUAL',
                              style: AppTypography.labelSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Flash Toggle & Camera Flip
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            _controller.flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                            color: _controller.flashOn ? const Color(0xFFFEA619) : Colors.white,
                          ),
                          onPressed: _controller.toggleFlash,
                        ),
                        IconButton(
                          icon: const Icon(Icons.flip_camera_android_rounded, color: Colors.white),
                          onPressed: _controller.toggleCamera,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Camera Controls Bar
          Align(
            alignment: Alignment.bottomCenter,
            child: CameraControls(
              currentMode: _controller.mode,
              onModeChanged: _controller.setMode,
              onCapture: _handleCapture,
              onGalleryImport: _handleGalleryImport,
              onFinishBatch: _openReview,
              pageCount: _controller.pageCount,
              isCapturing: _controller.isCapturing,
            ),
          ),
        ],
      ),
    );
  }
}
