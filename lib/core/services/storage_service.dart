import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Local sandbox file storage manager.
class StorageService {
  Directory? _documentsDir;
  Directory? _cacheDir;

  Future<void> init() async {
    _documentsDir = await getApplicationDocumentsDirectory();
    _cacheDir = await getTemporaryDirectory();

    // Ensure subdirectories exist
    await Directory(p.join(_documentsDir!.path, 'scans')).create(recursive: true);
    await Directory(p.join(_documentsDir!.path, 'pdfs')).create(recursive: true);
    await Directory(p.join(_documentsDir!.path, 'thumbnails')).create(recursive: true);
  }

  Directory get documentsDir => _documentsDir!;
  Directory get cacheDir => _cacheDir!;

  String get scansPath => p.join(_documentsDir!.path, 'scans');
  String get pdfsPath => p.join(_documentsDir!.path, 'pdfs');
  String get thumbnailsPath => p.join(_documentsDir!.path, 'thumbnails');

  Future<int> getCalculatedUsedStorageBytes() async {
    try {
      if (_documentsDir == null) return 0;
      var total = 0;
      if (await _documentsDir!.exists()) {
        await for (final file in _documentsDir!.list(recursive: true, followLinks: false)) {
          if (file is File) {
            total += await file.length();
          }
        }
      }
      return total;
    } catch (_) {
      return 0;
    }
  }
}
