import '../../../shared/models/document.dart';
import '../../../shared/models/folder.dart';

/// Local documents repository interface.
abstract class DocumentsRepository {
  Future<List<Document>> getAllDocuments();
  Future<List<Document>> getRecentDocuments({int limit = 5});
  Future<List<Document>> getFavoriteDocuments();
  Future<List<Document>> getDocumentsByFolder(String folderId);
  Future<List<Folder>> getAllFolders();
  Future<Document?> getDocumentById(String id);
  Future<void> saveDocument(Document document);
  Future<void> updateDocument(Document document);
  Future<void> deleteDocument(String id);
  Future<void> toggleFavorite(String id);
  Future<void> saveFolder(Folder folder);
  Future<void> deleteFolder(String id);
  Future<List<Document>> searchDocuments(String query);
}
