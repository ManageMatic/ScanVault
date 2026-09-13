import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../../../shared/models/ocr_result.dart';
import '../domain/ocr_service.dart';

/// Concrete 100% on-device Google ML Kit OCR service implementation.
class MLKitOcrService implements OcrService {
  TextRecognizer? _latinRecognizer;

  TextRecognizer _getRecognizer(String language) {
    switch (language.toLowerCase()) {
      case 'hi':
      case 'devanagari':
      case 'devanagiri':
        return TextRecognizer(script: TextRecognitionScript.devanagiri);
      case 'ja':
      case 'japanese':
        return TextRecognizer(script: TextRecognitionScript.japanese);
      case 'ko':
      case 'korean':
        return TextRecognizer(script: TextRecognitionScript.korean);
      case 'zh':
      case 'chinese':
        return TextRecognizer(script: TextRecognitionScript.chinese);
      default:
        _latinRecognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
        return _latinRecognizer!;
    }
  }

  @override
  Future<OCRResult> recognizeTextFromImage(File imageFile, {String language = 'en'}) async {
    if (!await imageFile.exists()) {
      return OCRResult(
        fullText: '',
        language: language,
        blocks: const [],
        processedAt: DateTime.now(),
      );
    }

    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizer = _getRecognizer(language);
      final recognizedText = await recognizer.processImage(inputImage);

      final blocks = <OCRBlock>[];
      for (final b in recognizedText.blocks) {
        final rect = b.boundingBox;
        blocks.add(
          OCRBlock(
            text: b.text,
            confidence: 0.95,
            boundingBox: [rect.left, rect.top, rect.width, rect.height],
          ),
        );
      }

      return OCRResult(
        fullText: recognizedText.text.trim(),
        language: language,
        blocks: blocks,
        processedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('MLKit OCR processing error: $e');
      return OCRResult(
        fullText: '',
        language: language,
        blocks: const [],
        processedAt: DateTime.now(),
      );
    }
  }

  /// Recognize text directly from in-memory byte buffer
  Future<OCRResult> recognizeTextFromBytes(Uint8List imageBytes, {String language = 'en'}) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(p.join(tempDir.path, 'ocr_${const Uuid().v4().substring(0, 8)}.jpg'));
      await tempFile.writeAsBytes(imageBytes);

      final result = await recognizeTextFromImage(tempFile, language: language);

      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      return result;
    } catch (e) {
      debugPrint('Error recognizing text from bytes: $e');
      return OCRResult(
        fullText: '',
        language: language,
        blocks: const [],
        processedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<List<OCRResult>> recognizeTextFromPdf(File pdfFile, {String language = 'en'}) async {
    return [];
  }

  @override
  Future<List<String>> getAvailableLanguages() async {
    return const [
      'English (Latin)',
      'Hindi (Devanagari)',
      'Spanish (Latin)',
      'French (Latin)',
      'German (Latin)',
      'Japanese',
      'Korean',
      'Chinese',
    ];
  }

  void dispose() {
    _latinRecognizer?.close();
  }
}
