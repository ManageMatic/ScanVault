/// Application specific exceptions.
class AppException implements Exception {
  final String message;
  final dynamic cause;

  const AppException(this.message, [this.cause]);

  @override
  String toString() => 'AppException: $message${cause != null ? " ($cause)" : ""}';
}

class StorageException extends AppException {
  const StorageException(super.message, [super.cause]);
}

class CameraException extends AppException {
  const CameraException(super.message, [super.cause]);
}

class PdfException extends AppException {
  const PdfException(super.message, [super.cause]);
}

class OcrException extends AppException {
  const OcrException(super.message, [super.cause]);
}
