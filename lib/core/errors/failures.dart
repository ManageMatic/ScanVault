/// Base failure class for domain layer error representation.
abstract class Failure {
  final String message;
  final String? code;

  const Failure(this.message, [this.code]);

  @override
  String toString() => message;
}

class StorageFailure extends Failure {
  const StorageFailure(super.message, [super.code]);
}

class CameraFailure extends Failure {
  const CameraFailure(super.message, [super.code]);
}

class PdfFailure extends Failure {
  const PdfFailure(super.message, [super.code]);
}

class OcrFailure extends Failure {
  const OcrFailure(super.message, [super.code]);
}

class SecurityFailure extends Failure {
  const SecurityFailure(super.message, [super.code]);
}

class PermissionFailure extends Failure {
  const PermissionFailure(super.message, [super.code]);
}
