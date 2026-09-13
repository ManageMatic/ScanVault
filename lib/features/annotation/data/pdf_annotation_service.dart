import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart' show Color;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../domain/models/annotation_model.dart';

/// Model representing a digital signature placed on a specific PDF page.
class PlacedSignature {
  final String signatureImagePath;
  final int pageIndex;
  final double normalizedX;
  final double normalizedY;
  final double normalizedWidth;
  final double normalizedHeight;
  final double rotationDegrees;

  const PlacedSignature({
    required this.signatureImagePath,
    required this.pageIndex,
    required this.normalizedX,
    required this.normalizedY,
    required this.normalizedWidth,
    required this.normalizedHeight,
    this.rotationDegrees = 0.0,
  });
}

class PdfAnnotationService {
  const PdfAnnotationService();

  Future<File> applyAnnotationsAndSignatures({
    required File sourcePdf,
    required File targetFile,
    required List<AnnotationModel> annotations,
    required List<PlacedSignature> signatures,
  }) async {
    if (!await sourcePdf.exists()) {
      throw FileSystemException('Source PDF does not exist', sourcePdf.path);
    }

    final bytes = await sourcePdf.readAsBytes();
    final document = PdfDocument(inputBytes: bytes);

    try {
      // 1. Group annotations by pageIndex
      final annotationsByPage = <int, List<AnnotationModel>>{};
      for (final ann in annotations) {
        annotationsByPage.putIfAbsent(ann.pageIndex, () => []).add(ann);
      }

      // 2. Group signatures by pageIndex
      final signaturesByPage = <int, List<PlacedSignature>>{};
      for (final sig in signatures) {
        signaturesByPage.putIfAbsent(sig.pageIndex, () => []).add(sig);
      }

      for (var pageIdx = 0; pageIdx < document.pages.count; pageIdx++) {
        final page = document.pages[pageIdx];
        final pageWidth = page.size.width;
        final pageHeight = page.size.height;
        final graphics = page.graphics;

        // Render annotations for this page
        final pageAnns = annotationsByPage[pageIdx] ?? [];
        for (final ann in pageAnns) {
          _drawAnnotation(graphics, ann, pageWidth, pageHeight);
        }

        // Render signatures for this page
        final pageSigs = signaturesByPage[pageIdx] ?? [];
        for (final sig in pageSigs) {
          _drawSignature(graphics, sig, pageWidth, pageHeight);
        }
      }

      final outputBytes = document.saveSync();
      await targetFile.parent.create(recursive: true);
      await targetFile.writeAsBytes(outputBytes, flush: true);
      return targetFile;
    } finally {
      document.dispose();
    }
  }

  void _drawAnnotation(
    PdfGraphics graphics,
    AnnotationModel ann,
    double pageWidth,
    double pageHeight,
  ) {
    final color = Color(ann.colorValue);
    final r = (color.r * 255.0).round().clamp(0, 255);
    final g = (color.g * 255.0).round().clamp(0, 255);
    final b = (color.b * 255.0).round().clamp(0, 255);
    final pdfColor = PdfColor(r, g, b, (ann.opacity * 255).round());

    switch (ann.type) {
      case AnnotationType.pen:
        if (ann.points.length < 2) break;
        final pen = PdfPen(pdfColor, width: ann.strokeWidth)
          ..lineCap = PdfLineCap.round
          ..lineJoin = PdfLineJoin.round;

        for (var i = 0; i < ann.points.length - 1; i++) {
          final p1 = ann.points[i];
          final p2 = ann.points[i + 1];
          graphics.drawLine(
            pen,
            ui.Offset(p1.x * pageWidth, p1.y * pageHeight),
            ui.Offset(p2.x * pageWidth, p2.y * pageHeight),
          );
        }
        break;

      case AnnotationType.highlighter:
        if (ann.points.length < 2) break;
        // Semi-transparent wide stroke for highlighter
        final highColor = PdfColor(r, g, b, 80);
        final pen = PdfPen(highColor, width: ann.strokeWidth * 3.5)
          ..lineCap = PdfLineCap.square;

        for (var i = 0; i < ann.points.length - 1; i++) {
          final p1 = ann.points[i];
          final p2 = ann.points[i + 1];
          graphics.drawLine(
            pen,
            ui.Offset(p1.x * pageWidth, p1.y * pageHeight),
            ui.Offset(p2.x * pageWidth, p2.y * pageHeight),
          );
        }
        break;

      case AnnotationType.rectangle:
        if (ann.startPoint == null || ann.endPoint == null) break;
        final x1 = ann.startPoint!.x * pageWidth;
        final y1 = ann.startPoint!.y * pageHeight;
        final x2 = ann.endPoint!.x * pageWidth;
        final y2 = ann.endPoint!.y * pageHeight;

        final rect = ui.Rect.fromLTRB(
          math.min(x1, x2),
          math.min(y1, y2),
          math.max(x1, x2),
          math.max(y1, y2),
        );
        final pen = PdfPen(pdfColor, width: ann.strokeWidth);
        graphics.drawRectangle(pen: pen, bounds: rect);
        break;

      case AnnotationType.circle:
        if (ann.startPoint == null || ann.endPoint == null) break;
        final x1 = ann.startPoint!.x * pageWidth;
        final y1 = ann.startPoint!.y * pageHeight;
        final x2 = ann.endPoint!.x * pageWidth;
        final y2 = ann.endPoint!.y * pageHeight;

        final bounds = ui.Rect.fromLTRB(
          math.min(x1, x2),
          math.min(y1, y2),
          math.max(x1, x2),
          math.max(y1, y2),
        );
        final pen = PdfPen(pdfColor, width: ann.strokeWidth);
        graphics.drawEllipse(bounds, pen: pen);
        break;

      case AnnotationType.arrow:
      case AnnotationType.underline:
      case AnnotationType.strikethrough:
        if (ann.startPoint == null || ann.endPoint == null) break;
        final p1 = ui.Offset(ann.startPoint!.x * pageWidth, ann.startPoint!.y * pageHeight);
        final p2 = ui.Offset(ann.endPoint!.x * pageWidth, ann.endPoint!.y * pageHeight);
        final pen = PdfPen(pdfColor, width: ann.strokeWidth)..lineCap = PdfLineCap.round;
        graphics.drawLine(pen, p1, p2);

        if (ann.type == AnnotationType.arrow) {
          // Draw arrowhead
          final angle = math.atan2(p2.dy - p1.dy, p2.dx - p1.dx);
          const arrowLength = 14.0;
          const arrowAngle = math.pi / 6;

          final left = ui.Offset(
            p2.dx - arrowLength * math.cos(angle - arrowAngle),
            p2.dy - arrowLength * math.sin(angle - arrowAngle),
          );
          final right = ui.Offset(
            p2.dx - arrowLength * math.cos(angle + arrowAngle),
            p2.dy - arrowLength * math.sin(angle + arrowAngle),
          );

          graphics.drawLine(pen, p2, left);
          graphics.drawLine(pen, p2, right);
        }
        break;

      case AnnotationType.text:
        if (ann.startPoint == null || ann.text == null || ann.text!.trim().isEmpty) break;
        final font = PdfStandardFont(PdfFontFamily.helvetica, ann.fontSize);
        final brush = PdfSolidBrush(pdfColor);
        graphics.drawString(
          ann.text!,
          font,
          brush: brush,
          bounds: ui.Rect.fromLTWH(
            ann.startPoint!.x * pageWidth,
            ann.startPoint!.y * pageHeight,
            pageWidth * (1.0 - ann.startPoint!.x),
            100,
          ),
        );
        break;
    }
  }

  void _drawSignature(
    PdfGraphics graphics,
    PlacedSignature sig,
    double pageWidth,
    double pageHeight,
  ) {
    final file = File(sig.signatureImagePath);
    if (!file.existsSync()) return;

    final imageBytes = file.readAsBytesSync();
    final pdfImage = PdfBitmap(imageBytes);

    final x = sig.normalizedX * pageWidth;
    final y = sig.normalizedY * pageHeight;
    final w = sig.normalizedWidth * pageWidth;
    final h = sig.normalizedHeight * pageHeight;

    graphics.save();
    if (sig.rotationDegrees != 0.0) {
      graphics.translateTransform(x + w / 2, y + h / 2);
      graphics.rotateTransform(sig.rotationDegrees);
      graphics.translateTransform(-(x + w / 2), -(y + h / 2));
    }

    graphics.drawImage(pdfImage, ui.Rect.fromLTWH(x, y, w, h));
    graphics.restore();
  }
}
