import 'dart:io';
import '../../../core/database/app_database.dart';
import '../../../core/storage/storage_manager_service.dart';
import '../../../shared/models/document.dart';
import '../../../shared/models/folder.dart';
import '../domain/documents_controller.dart';
import '../domain/documents_repository.dart';

/// Production SQLite & File-backed implementation of DocumentsRepository with user data isolation.
class LocalDocumentsRepository implements DocumentsRepository {
  final AppDatabase _db;
  final StorageManagerService _storageService;
  final String Function() _userIdProvider;
  bool _purged = false;

  LocalDocumentsRepository({
    AppDatabase? db,
    StorageManagerService? storageService,
    String Function()? userIdProvider,
  })  : _db = db ?? AppDatabase(),
        _storageService = storageService ?? StorageManagerService(),
        _userIdProvider = userIdProvider ?? (() => 'local_user');

  String get _currentUserId => _userIdProvider();
  StorageManagerService get storageService => _storageService;

  Future<void> _ensureClean() async {
    if (_purged) return;
    await _db.purgeDemoDocuments();
    _purged = true;
  }

  @override
  Future<List<Document>> getAllDocuments() async {
    await _ensureClean();
    return await _db.getDocumentsForUser(_currentUserId);
  }

  @override
  Future<List<Document>> getDocumentsPaginated({
    int limit = 30,
    int offset = 0,
    String? folderId,
    bool? onlyFavorites,
    String? searchQuery,
    DocumentSortOption sortOption = DocumentSortOption.newest,
    DocumentFilterType filterType = DocumentFilterType.all,
  }) async {
    await _ensureClean();
    return await _db.getDocumentsForUserPaginated(
      userId: _currentUserId,
      limit: limit,
      offset: offset,
      folderId: folderId,
      onlyFavorites: onlyFavorites,
      searchQuery: searchQuery,
      sortOption: sortOption,
      filterType: filterType,
    );
  }

  @override
  Future<List<Document>> getRecentDocuments({int limit = 6}) async {
    await _ensureClean();
    return await _db.getRecentDocumentsForUser(_currentUserId, limit: limit);
  }

  @override
  Future<List<Document>> getFavoriteDocuments() async {
    await _ensureClean();
    return await _db.getDocumentsForUser(_currentUserId, onlyFavorites: true);
  }

  @override
  Future<List<Document>> getDocumentsByFolder(String folderId) async {
    await _ensureClean();
    return await _db.getDocumentsForUser(_currentUserId, folderId: folderId);
  }

  @override
  Future<List<Folder>> getAllFolders() async {
    return await _db.getFoldersForUser(_currentUserId);
  }

  @override
  Future<Map<String, int>> getFolderDocumentCounts() async {
    return await _db.getFolderDocumentCounts(_currentUserId);
  }

  @override
  Future<Document?> getDocumentById(String id) async {
    return await _db.getDocumentById(_currentUserId, id);
  }

  @override
  Future<void> saveDocument(Document document) async {
    await _db.insertDocument(_currentUserId, document);
  }

  @override
  Future<void> updateDocument(Document document) async {
    await _db.updateDocument(_currentUserId, document);
  }

  @override
  Future<void> renameDocument(String id, String newTitle) async {
    await _db.renameDocument(_currentUserId, id, newTitle);
  }

  @override
  Future<void> moveDocument(String id, String? folderId) async {
    await _db.moveDocument(_currentUserId, id, folderId);
  }

  @override
  Future<void> deleteDocument(String id) async {
    final doc = await _db.getDocumentById(_currentUserId, id);
    if (doc != null) {
      if (doc.filePath.isNotEmpty) {
        final f = File(doc.filePath);
        if (await f.exists()) {
          try {
            await f.delete();
          } catch (_) {}
        }
      }
      if (doc.thumbnailPath != null && doc.thumbnailPath!.isNotEmpty) {
        final t = File(doc.thumbnailPath!);
        if (await t.exists()) {
          try {
            await t.delete();
          } catch (_) {}
        }
      }
    }
    await _db.deleteDocument(_currentUserId, id);
  }

  @override
  Future<void> toggleFavorite(String id) async {
    final doc = await _db.getDocumentById(_currentUserId, id);
    if (doc != null) {
      final updated = doc.copyWith(
        isFavorite: !doc.isFavorite,
        updatedAt: DateTime.now(),
      );
      await _db.updateDocument(_currentUserId, updated);
    }
  }

  @override
  Future<void> saveFolder(Folder folder) async {
    await _db.insertFolder(_currentUserId, folder);
  }

  @override
  Future<void> renameFolder(String id, String newName) async {
    await _db.renameFolder(_currentUserId, id, newName);
  }

  @override
  Future<void> deleteFolder(String id) async {
    await _db.deleteFolder(_currentUserId, id);
  }

  @override
  Future<List<Document>> searchDocuments(String query) async {
    await _ensureClean();
    return await _db.getDocumentsForUser(_currentUserId, searchQuery: query);
  }

  @override
  Future<int> getTotalStorageBytes() async {
    return await _db.getTotalStorageBytesForUser(_currentUserId);
  }

  @override
  Future<int> getTotalDocumentCount() async {
    return await _db.getTotalDocumentsCountForUser(_currentUserId);
  }
}
