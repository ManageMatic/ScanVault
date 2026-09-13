import 'dart:io';
import '../../../shared/models/ocr_result.dart';

/// On-device OCR Service abstraction.
abstract class OcrService {
  Future<OCRResult> recognizeTextFromImage(File imageFile, {String language = 'en'});
  Future<List<OCRResult>> recognizeTextFromPdf(File pdfFile, {String language = 'en'});
  Future<List<String>> getAvailableLanguages();
}
