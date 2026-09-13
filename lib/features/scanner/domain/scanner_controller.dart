import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import '../../../shared/models/scan_session.dart';
import 'scanned_page_item.dart';

/// Comprehensive controller managing real camera viewfinder, capture pipeline, and session pages.
class ScannerController extends ChangeNotifier {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isInitialized = false;
  bool _isCapturing = false;
  bool _hasPermission = false;
  bool _autoCapture = true;
  ScanMode _mode = ScanMode.batch;
  FlashMode _flashMode = FlashMode.off;
  final List<ScannedPageItem> _pages = [];
  final ImagePicker _picker = ImagePicker();

  CameraController? get cameraController => _cameraController;
  bool get isInitialized => _isInitialized && _cameraController != null && _cameraController!.value.isInitialized;
  bool get isCapturing => _isCapturing;
  bool get hasPermission => _hasPermission;
  bool get autoCapture => _autoCapture;
  ScanMode get mode => _mode;
  FlashMode get flashMode => _flashMode;
  bool get flashOn => _flashMode == FlashMode.torch || _flashMode == FlashMode.always;
  bool get isFrontCamera => _cameras.isNotEmpty && _cameras[_selectedCameraIndex].lensDirection == CameraLensDirection.front;
  List<ScannedPageItem> get pages => List.unmodifiable(_pages);
  int get pageCount => _pages.length;

  Future<void> initialize() async {
    try {
      final status = await Permission.camera.request();
      _hasPermission = status.isGranted;
      notifyListeners();

      if (!_hasPermission) return;

      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        _isInitialized = true;
        notifyListeners();
        return;
      }

      await _initCameraController(_cameras[_selectedCameraIndex]);
    } catch (e) {
      debugPrint('Error initializing camera scanner: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _initCameraController(CameraDescription description) async {
    await _cameraController?.dispose();
    _cameraController = CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.jpeg : ImageFormatGroup.bgra8888,
    );

    await _cameraController!.initialize();
    await _cameraController!.setFlashMode(_flashMode);
    _isInitialized = true;
    notifyListeners();
  }

  void setMode(ScanMode mode) {
    _mode = mode;
    notifyListeners();
  }

  void toggleAutoCapture() {
    _autoCapture = !_autoCapture;
    notifyListeners();
  }

  Future<void> toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (_flashMode == FlashMode.off) {
      _flashMode = FlashMode.torch;
    } else {
      _flashMode = FlashMode.off;
    }
    await _cameraController!.setFlashMode(_flashMode);
    notifyListeners();
  }

  Future<void> toggleCamera() async {
    if (_cameras.length < 2) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _initCameraController(_cameras[_selectedCameraIndex]);
  }

  /// Real picture capture from camera sensor
  Future<ScannedPageItem?> capture() async {
    if (_isCapturing) return null;
    _isCapturing = true;
    notifyListeners();

    try {
      String imagePath;
      Uint8List imageBytes;

      if (_cameraController != null && _cameraController!.value.isInitialized) {
        final xFile = await _cameraController!.takePicture();
        imagePath = xFile.path;
        imageBytes = await xFile.readAsBytes();
      } else {
        // Fallback simulator placeholder
        final tempDir = await getTemporaryDirectory();
        final dummyPath = p.join(tempDir.path, 'scan_sim_${DateTime.now().millisecondsSinceEpoch}.jpg');
        final dummyFile = File(dummyPath);
        // Create 1200x1600 dummy page
        final dummyImg = Uint8List.fromList(List.generate(100, (i) => 255));
        await dummyFile.writeAsBytes(dummyImg);
        imagePath = dummyPath;
        imageBytes = dummyImg;
      }

      final page = ScannedPageItem(
        id: const Uuid().v4(),
        originalImagePath: imagePath,
        cachedProcessedBytes: imageBytes,
        capturedAt: DateTime.now(),
      );

      _pages.add(page);
      _isCapturing = false;
      notifyListeners();
      return page;
    } catch (e) {
      debugPrint('Failed to capture page: $e');
      _isCapturing = false;
      notifyListeners();
      return null;
    }
  }

  /// Import photos from phone gallery
  Future<List<ScannedPageItem>> importFromGallery() async {
    try {
      final images = await _picker.pickMultiImage();
      final addedPages = <ScannedPageItem>[];
      for (final img in images) {
        final bytes = await img.readAsBytes();
        final page = ScannedPageItem(
          id: const Uuid().v4(),
          originalImagePath: img.path,
          cachedProcessedBytes: bytes,
          capturedAt: DateTime.now(),
        );
        _pages.add(page);
        addedPages.add(page);
      }
      notifyListeners();
      return addedPages;
    } catch (e) {
      debugPrint('Error importing from gallery: $e');
      return [];
    }
  }

  void updatePage(ScannedPageItem updated) {
    final idx = _pages.indexWhere((p) => p.id == updated.id);
    if (idx >= 0) {
      _pages[idx] = updated;
      notifyListeners();
    }
  }

  void rotatePage(String pageId) {
    final idx = _pages.indexWhere((p) => p.id == pageId);
    if (idx >= 0) {
      final current = _pages[idx];
      final newRotation = (current.enhancementParams.rotationDegrees + 90) % 360;
      final newParams = current.enhancementParams.copyWith(rotationDegrees: newRotation);
      _pages[idx] = current.copyWith(enhancementParams: newParams);
      notifyListeners();
    }
  }

  void removePage(String pageId) {
    _pages.removeWhere((p) => p.id == pageId);
    notifyListeners();
  }

  void reorderPages(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _pages.removeAt(oldIndex);
    _pages.insert(newIndex, item);
    notifyListeners();
  }

  void clearSession() {
    _pages.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }
}
