import '../../../shared/models/document.dart';
import '../../../shared/models/folder.dart';
import 'documents_controller.dart';

/// Local documents repository interface with user data isolation.
abstract class DocumentsRepository {
  Future<List<Document>> getAllDocuments();
  Future<List<Document>> getDocumentsPaginated({
    int limit = 30,
    int offset = 0,
    String? folderId,
    bool? onlyFavorites,
    String? searchQuery,
    DocumentSortOption sortOption = DocumentSortOption.newest,
    DocumentFilterType filterType = DocumentFilterType.all,
  });
  Future<List<Document>> getRecentDocuments({int limit = 6});
  Future<List<Document>> getFavoriteDocuments();
  Future<List<Document>> getDocumentsByFolder(String folderId);
  Future<List<Folder>> getAllFolders();
  Future<Map<String, int>> getFolderDocumentCounts();
  Future<Document?> getDocumentById(String id);
  Future<void> saveDocument(Document document);
  Future<void> updateDocument(Document document);
  Future<void> renameDocument(String id, String newTitle);
  Future<void> moveDocument(String id, String? folderId);
  Future<void> deleteDocument(String id);
  Future<void> toggleFavorite(String id);
  Future<void> saveFolder(Folder folder);
  Future<void> renameFolder(String id, String newName);
  Future<void> deleteFolder(String id);
  Future<List<Document>> searchDocuments(String query);
  Future<int> getTotalStorageBytes();
  Future<int> getTotalDocumentCount();
}
