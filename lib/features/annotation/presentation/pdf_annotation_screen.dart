import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:scanvault/core/constants/app_colors.dart';
import 'package:scanvault/core/constants/app_typography.dart';
import 'package:scanvault/core/database/app_database.dart';
import 'package:scanvault/shared/models/document.dart';
import '../data/pdf_annotation_service.dart';
import '../domain/models/annotation_model.dart';

class PdfAnnotationScreen extends StatefulWidget {
  final Document document;
  final String? userId;

  const PdfAnnotationScreen({super.key, required this.document, this.userId});

  @override
  State<PdfAnnotationScreen> createState() => _PdfAnnotationScreenState();
}

class _PdfAnnotationScreenState extends State<PdfAnnotationScreen> {
  final PdfAnnotationService _annotationService = const PdfAnnotationService();
  final AppDatabase _database = AppDatabase();

  int _currentPageIndex = 0;
  int _totalPages = 1;
  Uint8List? _currentPageImageBytes;
  bool _isLoadingPage = true;
  bool _isSaving = false;

  AnnotationType _activeTool = AnnotationType.pen;
  Color _selectedColor = const Color(0xFFE53935); // Vivid Red
  final double _strokeWidth = 3.5;

  final List<AnnotationModel> _annotations = [];
  final List<AnnotationModel> _undoStack = [];

  // Temporary stroke in progress
  List<NormalizedPoint> _currentStrokePoints = [];
  NormalizedPoint? _shapeStartPoint;
  NormalizedPoint? _shapeEndPoint;

  @override
  void initState() {
    super.initState();
    _totalPages = widget.document.pageCount > 0 ? widget.document.pageCount : 1;
    _renderPage(_currentPageIndex);
  }

  Future<void> _renderPage(int pageIndex) async {
    setState(() => _isLoadingPage = true);
    try {
      final file = File(widget.document.filePath);
      if (!await file.exists()) return;

      final pdfBytes = await file.readAsBytes();
      await for (final raster in Printing.raster(pdfBytes, pages: [pageIndex], dpi: 150)) {
        final pngBytes = await raster.toPng();
        if (mounted) {
          setState(() {
            _currentPageImageBytes = pngBytes;
            _isLoadingPage = false;
          });
        }
        break;
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingPage = false);
    }
  }

  void _undo() {
    final pageAnns = _annotations.where((a) => a.pageIndex == _currentPageIndex).toList();
    if (pageAnns.isNotEmpty) {
      final last = pageAnns.last;
      setState(() {
        _annotations.remove(last);
        _undoStack.add(last);
      });
    }
  }

  void _redo() {
    if (_undoStack.isNotEmpty) {
      final item = _undoStack.removeLast();
      setState(() {
        _annotations.add(item);
      });
    }
  }

  void _clearPageAnnotations() {
    setState(() {
      _annotations.removeWhere((a) => a.pageIndex == _currentPageIndex);
      _undoStack.clear();
    });
  }

  Future<void> _promptTextAnnotation(NormalizedPoint point) async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Text Annotation'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter note or comment...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (text != null && text.isNotEmpty) {
      setState(() {
        _annotations.add(
          AnnotationModel(
            id: 'ann_${DateTime.now().millisecondsSinceEpoch}',
            pageIndex: _currentPageIndex,
            type: AnnotationType.text,
            startPoint: point,
            text: text,
            colorValue: _selectedColor.toARGB32(),
            strokeWidth: _strokeWidth,
            createdAt: DateTime.now(),
          ),
        );
      });
    }
  }

  Future<void> _saveAnnotatedPdf() async {
    if (_annotations.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _isSaving = true);
    try {
      final sourceFile = File(widget.document.filePath);
      final tempTarget = File('${sourceFile.path}.annotated.tmp');

      await _annotationService.applyAnnotationsAndSignatures(
        sourcePdf: sourceFile,
        targetFile: tempTarget,
        annotations: _annotations,
        signatures: const [],
      );

      // Replace original PDF safely
      if (await tempTarget.exists()) {
        await tempTarget.rename(sourceFile.path);
      }

      // Update database
      final updatedDoc = widget.document.copyWith(
        updatedAt: DateTime.now(),
        fileSize: await sourceFile.length(),
      );
      await _database.updateDocument(widget.userId ?? 'local_user', updatedDoc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Annotations saved to document.')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save annotations: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
              'Annotate Document',
              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              'Page ${_currentPageIndex + 1} of $_totalPages',
              style: AppTypography.labelSmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo_rounded),
            tooltip: 'Undo',
            onPressed: _annotations.any((a) => a.pageIndex == _currentPageIndex) ? _undo : null,
          ),
          IconButton(
            icon: const Icon(Icons.redo_rounded),
            tooltip: 'Redo',
            onPressed: _undoStack.isNotEmpty ? _redo : null,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Clear Page',
            onPressed: _clearPageAnnotations,
          ),
          FilledButton.tonal(
            onPressed: _isSaving ? null : _saveAnnotatedPdf,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            ),
            child: _isSaving
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 1. Tool Options Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
            child: Row(
              children: [
                _buildToolButton(AnnotationType.pen, Icons.edit_rounded, 'Pen'),
                _buildToolButton(AnnotationType.highlighter, Icons.border_color_rounded, 'Highlighter'),
                _buildToolButton(AnnotationType.text, Icons.title_rounded, 'Text'),
                _buildToolButton(AnnotationType.rectangle, Icons.crop_square_rounded, 'Rectangle'),
                _buildToolButton(AnnotationType.circle, Icons.circle_outlined, 'Circle'),
                _buildToolButton(AnnotationType.arrow, Icons.arrow_right_alt_rounded, 'Arrow'),
                const Spacer(),
                _buildColorCircle(const Color(0xFFE53935)), // Red
                const SizedBox(width: 6),
                _buildColorCircle(const Color(0xFFFFB300)), // Yellow
                const SizedBox(width: 6),
                _buildColorCircle(AppColors.primary), // Teal
                const SizedBox(width: 6),
                _buildColorCircle(Colors.black), // Black
              ],
            ),
          ),

          // 2. Interactive Canvas
          Expanded(
            child: _isLoadingPage
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _currentPageImageBytes == null
                    ? const Center(child: Text('Failed to render page.'))
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          return Center(
                            child: AspectRatio(
                              aspectRatio: 1 / 1.414, // A4 ratio standard
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRect(
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.memory(
                                        _currentPageImageBytes!,
                                        fit: BoxFit.fill,
                                      ),
                                      GestureDetector(
                                        onPanStart: (details) {
                                          final box = context.findRenderObject() as RenderBox?;
                                          final size = box?.size ?? Size.zero;
                                          if (size.width <= 0 || size.height <= 0) return;

                                          final norm = NormalizedPoint(
                                            (details.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0),
                                            (details.localPosition.dy / constraints.maxHeight).clamp(0.0, 1.0),
                                          );

                                          if (_activeTool == AnnotationType.text) {
                                            _promptTextAnnotation(norm);
                                            return;
                                          }

                                          setState(() {
                                            if (_activeTool == AnnotationType.pen ||
                                                _activeTool == AnnotationType.highlighter) {
                                              _currentStrokePoints = [norm];
                                            } else {
                                              _shapeStartPoint = norm;
                                              _shapeEndPoint = norm;
                                            }
                                          });
                                        },
                                        onPanUpdate: (details) {
                                          final norm = NormalizedPoint(
                                            (details.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0),
                                            (details.localPosition.dy / constraints.maxHeight).clamp(0.0, 1.0),
                                          );

                                          setState(() {
                                            if (_activeTool == AnnotationType.pen ||
                                                _activeTool == AnnotationType.highlighter) {
                                              _currentStrokePoints.add(norm);
                                            } else {
                                              _shapeEndPoint = norm;
                                            }
                                          });
                                        },
                                        onPanEnd: (_) {
                                          if (_activeTool == AnnotationType.text) return;

                                          setState(() {
                                            if (_activeTool == AnnotationType.pen ||
                                                _activeTool == AnnotationType.highlighter) {
                                              if (_currentStrokePoints.length >= 2) {
                                                _annotations.add(
                                                  AnnotationModel(
                                                    id: 'ann_${DateTime.now().millisecondsSinceEpoch}',
                                                    pageIndex: _currentPageIndex,
                                                    type: _activeTool,
                                                    points: List.from(_currentStrokePoints),
                                                    colorValue: _selectedColor.toARGB32(),
                                                    opacity: _activeTool == AnnotationType.highlighter ? 0.35 : 1.0,
                                                    strokeWidth: _strokeWidth,
                                                    createdAt: DateTime.now(),
                                                  ),
                                                );
                                              }
                                              _currentStrokePoints = [];
                                            } else {
                                              if (_shapeStartPoint != null && _shapeEndPoint != null) {
                                                _annotations.add(
                                                  AnnotationModel(
                                                    id: 'ann_${DateTime.now().millisecondsSinceEpoch}',
                                                    pageIndex: _currentPageIndex,
                                                    type: _activeTool,
                                                    startPoint: _shapeStartPoint,
                                                    endPoint: _shapeEndPoint,
                                                    colorValue: _selectedColor.toARGB32(),
                                                    strokeWidth: _strokeWidth,
                                                    createdAt: DateTime.now(),
                                                  ),
                                                );
                                              }
                                              _shapeStartPoint = null;
                                              _shapeEndPoint = null;
                                            }
                                          });
                                        },
                                        child: CustomPaint(
                                          painter: _AnnotationCanvasPainter(
                                            annotations: _annotations.where((a) => a.pageIndex == _currentPageIndex).toList(),
                                            activeTool: _activeTool,
                                            activeColor: _selectedColor,
                                            activeStrokeWidth: _strokeWidth,
                                            currentStrokePoints: _currentStrokePoints,
                                            shapeStartPoint: _shapeStartPoint,
                                            shapeEndPoint: _shapeEndPoint,
                                          ),
                                          size: Size.infinite,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // 3. Page Switcher (if multi-page)
          if (_totalPages > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: _currentPageIndex > 0
                        ? () {
                            setState(() => _currentPageIndex--);
                            _renderPage(_currentPageIndex);
                          }
                        : null,
                  ),
                  Text(
                    'Page ${_currentPageIndex + 1} of $_totalPages',
                    style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: _currentPageIndex < _totalPages - 1
                        ? () {
                            setState(() => _currentPageIndex++);
                            _renderPage(_currentPageIndex);
                          }
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildToolButton(AnnotationType type, IconData icon, String tooltip) {
    final isSelected = _activeTool == type;
    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      color: isSelected ? AppColors.primary : Theme.of(context).colorScheme.outline,
      style: isSelected
          ? IconButton.styleFrom(
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            )
          : null,
      onPressed: () => setState(() => _activeTool = type),
    );
  }

  Widget _buildColorCircle(Color color) {
    final isSelected = _selectedColor == color;
    return InkWell(
      onTap: () => setState(() => _selectedColor = color),
      borderRadius: BorderRadius.circular(9999),
      child: Container(
        width: 22,
        height: 22,
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
                    blurRadius: 4,
                  )
                ]
              : null,
        ),
      ),
    );
  }
}

class _AnnotationCanvasPainter extends CustomPainter {
  final List<AnnotationModel> annotations;
  final AnnotationType activeTool;
  final Color activeColor;
  final double activeStrokeWidth;
  final List<NormalizedPoint> currentStrokePoints;
  final NormalizedPoint? shapeStartPoint;
  final NormalizedPoint? shapeEndPoint;

  const _AnnotationCanvasPainter({
    required this.annotations,
    required this.activeTool,
    required this.activeColor,
    required this.activeStrokeWidth,
    required this.currentStrokePoints,
    this.shapeStartPoint,
    this.shapeEndPoint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Draw existing annotations
    for (final ann in annotations) {
      final paint = Paint()
        ..color = Color(ann.colorValue).withValues(alpha: ann.opacity)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = ann.strokeWidth
        ..style = PaintingStyle.stroke;

      switch (ann.type) {
        case AnnotationType.pen:
        case AnnotationType.highlighter:
          if (ann.points.length < 2) break;
          final path = Path()..moveTo(ann.points.first.x * w, ann.points.first.y * h);
          for (var i = 1; i < ann.points.length; i++) {
            path.lineTo(ann.points[i].x * w, ann.points[i].y * h);
          }
          if (ann.type == AnnotationType.highlighter) {
            paint.strokeWidth = ann.strokeWidth * 3.5;
          }
          canvas.drawPath(path, paint);
          break;

        case AnnotationType.rectangle:
          if (ann.startPoint == null || ann.endPoint == null) break;
          final rect = Rect.fromPoints(
            Offset(ann.startPoint!.x * w, ann.startPoint!.y * h),
            Offset(ann.endPoint!.x * w, ann.endPoint!.y * h),
          );
          canvas.drawRect(rect, paint);
          break;

        case AnnotationType.circle:
          if (ann.startPoint == null || ann.endPoint == null) break;
          final rect = Rect.fromPoints(
            Offset(ann.startPoint!.x * w, ann.startPoint!.y * h),
            Offset(ann.endPoint!.x * w, ann.endPoint!.y * h),
          );
          canvas.drawOval(rect, paint);
          break;

        case AnnotationType.arrow:
        case AnnotationType.underline:
        case AnnotationType.strikethrough:
          if (ann.startPoint == null || ann.endPoint == null) break;
          final p1 = Offset(ann.startPoint!.x * w, ann.startPoint!.y * h);
          final p2 = Offset(ann.endPoint!.x * w, ann.endPoint!.y * h);
          canvas.drawLine(p1, p2, paint);
          break;

        case AnnotationType.text:
          if (ann.startPoint == null || ann.text == null) break;
          final textPainter = TextPainter(
            text: TextSpan(
              text: ann.text,
              style: TextStyle(
                color: Color(ann.colorValue),
                fontSize: ann.fontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout(maxWidth: w * (1.0 - ann.startPoint!.x));
          textPainter.paint(canvas, Offset(ann.startPoint!.x * w, ann.startPoint!.y * h));
          break;
      }
    }

    // 2. Draw live interactive stroke
    if (currentStrokePoints.length >= 2) {
      final livePaint = Paint()
        ..color = activeTool == AnnotationType.highlighter
            ? activeColor.withValues(alpha: 0.35)
            : activeColor
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = activeTool == AnnotationType.highlighter ? activeStrokeWidth * 3.5 : activeStrokeWidth
        ..style = PaintingStyle.stroke;

      final path = Path()..moveTo(currentStrokePoints.first.x * w, currentStrokePoints.first.y * h);
      for (var i = 1; i < currentStrokePoints.length; i++) {
        path.lineTo(currentStrokePoints[i].x * w, currentStrokePoints[i].y * h);
      }
      canvas.drawPath(path, livePaint);
    }

    // 3. Draw live interactive shape preview
    if (shapeStartPoint != null && shapeEndPoint != null) {
      final shapePaint = Paint()
        ..color = activeColor
        ..strokeCap = StrokeCap.round
        ..strokeWidth = activeStrokeWidth
        ..style = PaintingStyle.stroke;

      final p1 = Offset(shapeStartPoint!.x * w, shapeStartPoint!.y * h);
      final p2 = Offset(shapeEndPoint!.x * w, shapeEndPoint!.y * h);

      if (activeTool == AnnotationType.rectangle) {
        canvas.drawRect(Rect.fromPoints(p1, p2), shapePaint);
      } else if (activeTool == AnnotationType.circle) {
        canvas.drawOval(Rect.fromPoints(p1, p2), shapePaint);
      } else if (activeTool == AnnotationType.arrow) {
        canvas.drawLine(p1, p2, shapePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AnnotationCanvasPainter oldDelegate) => true;
}
