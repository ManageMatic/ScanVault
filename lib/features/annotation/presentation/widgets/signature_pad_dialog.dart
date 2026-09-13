import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:scanvault/core/constants/app_colors.dart';
import 'package:scanvault/core/constants/app_typography.dart';
import '../../data/signature_storage_service.dart';
import '../../domain/models/digital_signature_model.dart';

class SignaturePadDialog extends StatefulWidget {
  final String userId;

  const SignaturePadDialog({super.key, required this.userId});

  static Future<DigitalSignature?> show(BuildContext context, {String userId = 'local_user'}) {
    return showDialog<DigitalSignature>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SignaturePadDialog(userId: userId),
    );
  }

  @override
  State<SignaturePadDialog> createState() => _SignaturePadDialogState();
}

class _SignaturePadDialogState extends State<SignaturePadDialog> {
  final SignatureStorageService _storageService = const SignatureStorageService();
  final TextEditingController _titleController = TextEditingController(text: 'My Signature');
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  Color _selectedColor = Colors.black;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _currentStroke = [];
    });
  }

  Future<void> _importFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _isSaving = true);
    try {
      final fileBytes = await File(picked.path).readAsBytes();
      final decoded = img.decodeImage(fileBytes);
      if (decoded != null) {
        // Convert white/light background to transparent
        final transparentImg = img.Image(width: decoded.width, height: decoded.height, numChannels: 4);
        for (var y = 0; y < decoded.height; y++) {
          for (var x = 0; x < decoded.width; x++) {
            final pixel = decoded.getPixel(x, y);
            final r = pixel.r;
            final g = pixel.g;
            final b = pixel.b;
            final lum = 0.299 * r + 0.587 * g + 0.114 * b;
            if (lum > 200) {
              transparentImg.setPixelRgba(x, y, 0, 0, 0, 0);
            } else {
              transparentImg.setPixelRgba(x, y, r.toInt(), g.toInt(), b.toInt(), 255);
            }
          }
        }
        final pngBytes = img.encodePng(transparentImg);
        final sig = await _storageService.saveSignature(
          userId: widget.userId,
          title: _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : 'Imported Signature',
          pngBytes: pngBytes,
        );
        if (mounted) Navigator.of(context).pop(sig);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to import signature: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveDrawnSignature() async {
    if (_strokes.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 500, 250));

      final paint = Paint()
        ..color = _selectedColor
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 4.0
        ..style = PaintingStyle.stroke;

      for (final stroke in _strokes) {
        if (stroke.length < 2) continue;
        final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
        for (var i = 1; i < stroke.length; i++) {
          path.lineTo(stroke[i].dx, stroke[i].dy);
        }
        canvas.drawPath(path, paint);
      }

      final picture = recorder.endRecording();
      final image = await picture.toImage(500, 250);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();
      final sig = await _storageService.saveSignature(
        userId: widget.userId,
        title: _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : 'Digital Signature',
        pngBytes: pngBytes,
      );

      if (mounted) {
        Navigator.of(context).pop(sig);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save signature: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Draw Signature',
                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Signature Label',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Color Selector Bar
            Row(
              children: [
                _buildColorDot(Colors.black),
                const SizedBox(width: 8),
                _buildColorDot(const Color(0xFF003882)), // Classic Blue
                const SizedBox(width: 8),
                _buildColorDot(AppColors.primary),
                const SizedBox(width: 8),
                _buildColorDot(const Color(0xFFB3261E)), // Red
                const Spacer(),
                TextButton.icon(
                  onPressed: _importFromGallery,
                  icon: const Icon(Icons.image_outlined, size: 18),
                  label: const Text('Import Image'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Drawing Area
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2429) : const Color(0xFFF4F7F6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder,
                  width: 1.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GestureDetector(
                  onPanStart: (details) {
                    setState(() {
                      _currentStroke = [details.localPosition];
                      _strokes.add(_currentStroke);
                    });
                  },
                  onPanUpdate: (details) {
                    setState(() {
                      _currentStroke.add(details.localPosition);
                    });
                  },
                  child: CustomPaint(
                    painter: _SignaturePainter(
                      strokes: _strokes,
                      color: _selectedColor,
                    ),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Bottom Buttons
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _clear,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Clear'),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _isSaving ? null : _saveDrawnSignature,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Save & Use'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorDot(Color color) {
    final isSelected = _selectedColor == color;
    return InkWell(
      onTap: () => setState(() => _selectedColor = color),
      borderRadius: BorderRadius.circular(9999),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 6,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final Color color;

  const _SignaturePainter({required this.strokes, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (var i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
