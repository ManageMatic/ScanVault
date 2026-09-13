import 'package:flutter/foundation.dart';
import '../../../shared/models/document.dart';
import '../../documents/domain/documents_repository.dart';

/// Controller for Home dashboard metrics and recent documents.
class HomeController extends ChangeNotifier {
  final DocumentsRepository _repository;

  HomeController(this._repository);

  List<Document> _recentDocuments = [];
  List<Document> _favoriteDocuments = [];
  int _totalDocumentCount = 0;
  int _totalStorageBytes = 0;
  bool _isLoading = false;

  List<Document> get recentDocuments => _recentDocuments;
  List<Document> get favoriteDocuments => _favoriteDocuments;
  int get totalDocumentCount => _totalDocumentCount;
  int get totalStorageBytes => _totalStorageBytes;
  bool get isLoading => _isLoading;

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();

    final allDocs = await _repository.getAllDocuments();
    _recentDocuments = await _repository.getRecentDocuments(limit: 5);
    _favoriteDocuments = await _repository.getFavoriteDocuments();
    _totalDocumentCount = allDocs.length;
    _totalStorageBytes = allDocs.fold<int>(0, (sum, doc) => sum + doc.fileSize);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleFavorite(String documentId) async {
    await _repository.toggleFavorite(documentId);
    await refresh();
  }
}
