import '../../../shared/models/document.dart';
import '../../../shared/models/folder.dart';
import '../../home/data/sample_data.dart';
import '../domain/documents_repository.dart';

/// Local implementation of DocumentsRepository.
/// Initializes with sample data on first run for development, then maintains in-memory / local state.
class LocalDocumentsRepository implements DocumentsRepository {
  final List<Document> _documents = [];
  final List<Folder> _folders = [];
  bool _initialized = false;

  void _ensureInitialized() {
    if (!_initialized) {
      _documents.addAll(SampleData.initialDocuments);
      _folders.addAll(SampleData.initialFolders);
      _initialized = true;
    }
  }

  @override
  Future<List<Document>> getAllDocuments() async {
    _ensureInitialized();
    return List.unmodifiable(_documents);
  }

  @override
  Future<List<Document>> getRecentDocuments({int limit = 5}) async {
    _ensureInitialized();
    final sorted = List<Document>.from(_documents)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sorted.take(limit).toList();
  }

  @override
  Future<List<Document>> getFavoriteDocuments() async {
    _ensureInitialized();
    return _documents.where((d) => d.isFavorite).toList();
  }

  @override
  Future<List<Document>> getDocumentsByFolder(String folderId) async {
    _ensureInitialized();
    return _documents.where((d) => d.folderId == folderId).toList();
  }

  @override
  Future<List<Folder>> getAllFolders() async {
    _ensureInitialized();
    return List.unmodifiable(_folders);
  }

  @override
  Future<Document?> getDocumentById(String id) async {
    _ensureInitialized();
    try {
      return _documents.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveDocument(Document document) async {
    _ensureInitialized();
    final index = _documents.indexWhere((d) => d.id == document.id);
    if (index >= 0) {
      _documents[index] = document;
    } else {
      _documents.insert(0, document);
    }
  }

  @override
  Future<void> updateDocument(Document document) async {
    _ensureInitialized();
    final index = _documents.indexWhere((d) => d.id == document.id);
    if (index >= 0) {
      _documents[index] = document;
    }
  }

  @override
  Future<void> deleteDocument(String id) async {
    _ensureInitialized();
    _documents.removeWhere((d) => d.id == id);
  }

  @override
  Future<void> toggleFavorite(String id) async {
    _ensureInitialized();
    final index = _documents.indexWhere((d) => d.id == id);
    if (index >= 0) {
      final doc = _documents[index];
      _documents[index] = doc.copyWith(isFavorite: !doc.isFavorite);
    }
  }

  @override
  Future<void> saveFolder(Folder folder) async {
    _ensureInitialized();
    final index = _folders.indexWhere((f) => f.id == folder.id);
    if (index >= 0) {
      _folders[index] = folder;
    } else {
      _folders.add(folder);
    }
  }

  @override
  Future<void> deleteFolder(String id) async {
    _ensureInitialized();
    _folders.removeWhere((f) => f.id == id);
  }

  @override
  Future<List<Document>> searchDocuments(String query) async {
    _ensureInitialized();
    if (query.trim().isEmpty) return List.unmodifiable(_documents);

    final q = query.toLowerCase();
    return _documents.where((d) {
      final titleMatch = d.title.toLowerCase().contains(q);
      final tagMatch = d.tags.any((t) => t.toLowerCase().contains(q));
      final ocrMatch = d.extractedOcrText?.toLowerCase().contains(q) ?? false;
      return titleMatch || tagMatch || ocrMatch;
    }).toList();
  }
}
