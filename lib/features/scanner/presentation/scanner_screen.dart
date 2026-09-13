import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../domain/scanner_controller.dart';
import 'widgets/camera_controls.dart';
import 'widgets/camera_viewfinder_overlay.dart';

/// Camera Scanner Screen conforming to Stitch camera UI specifications.
class ScannerScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const ScannerScreen({
    super.key,
    this.onBack,
  });

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final ScannerController _controller = ScannerController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onStateChanged);
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
    await _controller.simulateCapture();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Page ${_controller.pageCount} captured • Ready for review'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _finishBatch() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_controller.pageCount} pages saved to Vault'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (widget.onBack != null) {
      widget.onBack!();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Viewfinder Background Simulator
          Container(
            color: const Color(0xFF14191E),
            child: Center(
              child: Icon(
                Icons.document_scanner_rounded,
                size: 80,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),

          // Viewfinder Overlays & Brackets
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

                    // Auto Capture Toggle Pill
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

                    // Flash Toggle & Camera Switch
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
              onGalleryImport: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Gallery photo import ready.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              onFinishBatch: _finishBatch,
              pageCount: _controller.pageCount,
              isCapturing: _controller.isCapturing,
            ),
          ),
        ],
      ),
    );
  }
}
