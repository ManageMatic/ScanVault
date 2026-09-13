import 'dart:io';
import '../../../shared/models/document_page.dart';
import '../../../shared/models/scan_session.dart';

/// Abstraction for Camera Scanner Hardware / Edge Detection layer.
abstract class ScannerRepository {
  Future<bool> requestCameraPermission();
  Future<bool> isCameraPermissionGranted();
  Future<ScanSession> createNewScanSession({ScanMode mode = ScanMode.batch});
  Future<DocumentPage> capturePage({required String sessionId, bool applyAutoEnhance = true});
  Future<DocumentPage> importFromGallery({required String sessionId, required File file});
  Future<void> deletePage({required String sessionId, required String pageId});
}
