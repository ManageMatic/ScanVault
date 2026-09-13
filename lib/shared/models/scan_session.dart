import 'document_page.dart';

/// Represents an active camera scanning session.
enum ScanMode { single, batch, idCard, book, qrCode }

class ScanSession {
  final String id;
  final ScanMode mode;
  final List<DocumentPage> pages;
  final bool autoCaptureEnabled;
  final bool flashEnabled;
  final DateTime startedAt;

  const ScanSession({
    required this.id,
    this.mode = ScanMode.batch,
    this.pages = const [],
    this.autoCaptureEnabled = true,
    this.flashEnabled = false,
    required this.startedAt,
  });

  ScanSession copyWith({
    String? id,
    ScanMode? mode,
    List<DocumentPage>? pages,
    bool? autoCaptureEnabled,
    bool? flashEnabled,
    DateTime? startedAt,
  }) {
    return ScanSession(
      id: id ?? this.id,
      mode: mode ?? this.mode,
      pages: pages ?? this.pages,
      autoCaptureEnabled: autoCaptureEnabled ?? this.autoCaptureEnabled,
      flashEnabled: flashEnabled ?? this.flashEnabled,
      startedAt: startedAt ?? this.startedAt,
    );
  }
}
