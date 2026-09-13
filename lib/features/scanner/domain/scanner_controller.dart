import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../shared/models/document_page.dart';
import '../../../shared/models/scan_session.dart';

/// State controller for the Camera Scanner screen and batch session management.
class ScannerController extends ChangeNotifier {
  ScanMode _mode = ScanMode.batch;
  bool _autoCapture = true;
  bool _flashOn = false;
  bool _isFrontCamera = false;
  bool _hasPermission = false;
  bool _isCapturing = false;
  final List<DocumentPage> _capturedPages = [];

  ScanMode get mode => _mode;
  bool get autoCapture => _autoCapture;
  bool get flashOn => _flashOn;
  bool get isFrontCamera => _isFrontCamera;
  bool get hasPermission => _hasPermission;
  bool get isCapturing => _isCapturing;
  List<DocumentPage> get capturedPages => List.unmodifiable(_capturedPages);
  int get pageCount => _capturedPages.length;

  void setMode(ScanMode mode) {
    _mode = mode;
    notifyListeners();
  }

  void toggleAutoCapture() {
    _autoCapture = !_autoCapture;
    notifyListeners();
  }

  void toggleFlash() {
    _flashOn = !_flashOn;
    notifyListeners();
  }

  void toggleCamera() {
    _isFrontCamera = !_isFrontCamera;
    notifyListeners();
  }

  void setPermissionGranted(bool granted) {
    _hasPermission = granted;
    notifyListeners();
  }

  Future<void> simulateCapture() async {
    if (_isCapturing) return;
    _isCapturing = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));

    final newPage = DocumentPage(
      id: const Uuid().v4(),
      pageNumber: _capturedPages.length + 1,
      imagePath: '',
      createdAt: DateTime.now(),
    );

    _capturedPages.add(newPage);
    _isCapturing = false;
    notifyListeners();
  }

  void removePage(String pageId) {
    _capturedPages.removeWhere((p) => p.id == pageId);
    notifyListeners();
  }

  void clearSession() {
    _capturedPages.clear();
    notifyListeners();
  }
}
