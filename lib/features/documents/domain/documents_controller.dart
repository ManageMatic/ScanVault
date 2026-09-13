import 'package:flutter/foundation.dart';
import '../../../shared/models/document.dart';
import '../../../shared/models/folder.dart';
import 'documents_repository.dart';

enum DocumentSortOption { newest, oldest, nameAsc, nameDesc, sizeLargest, sizeSmallest }
enum DocumentFilterType { all, pdfOnly, scansOnly, ocrOnly, favoritesOnly }

/// Reactive state controller for document list management.
class DocumentsController extends ChangeNotifier {
  final DocumentsRepository _repository;

  DocumentsController(this._repository);

  List<Document> _documents = [];
  List<Folder> _folders = [];
  bool _isLoading = false;
  String _searchQuery = '';
  DocumentSortOption _sortOption = DocumentSortOption.newest;
  DocumentFilterType _filterType = DocumentFilterType.all;
  bool _isGridView = false;

  List<Document> get documents => _applySortAndFilter(_documents);
  List<Folder> get folders => _folders;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  DocumentSortOption get sortOption => _sortOption;
  DocumentFilterType get filterType => _filterType;
  bool get isGridView => _isGridView;

  int get totalDocumentCount => _documents.length;
  int get totalStorageBytes => _documents.fold<int>(0, (sum, d) => sum + d.fileSize);

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    _documents = await _repository.getAllDocuments();
    _folders = await _repository.getAllFolders();
    _isLoading = false;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSortOption(DocumentSortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  void setFilterType(DocumentFilterType type) {
    _filterType = type;
    notifyListeners();
  }

  void toggleViewMode() {
    _isGridView = !_isGridView;
    notifyListeners();
  }

  Future<void> toggleFavorite(String documentId) async {
    await _repository.toggleFavorite(documentId);
    await loadData();
  }

  Future<void> deleteDocument(String documentId) async {
    await _repository.deleteDocument(documentId);
    await loadData();
  }

  List<Document> _applySortAndFilter(List<Document> docs) {
    var result = List<Document>.from(docs);

    // Filter by query
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((d) {
        final title = d.title.toLowerCase().contains(q);
        final tag = d.tags.any((t) => t.toLowerCase().contains(q));
        final ocr = d.extractedOcrText?.toLowerCase().contains(q) ?? false;
        return title || tag || ocr;
      }).toList();
    }

    // Filter by type
    switch (_filterType) {
      case DocumentFilterType.pdfOnly:
        result = result.where((d) => d.type == DocumentType.pdf).toList();
        break;
      case DocumentFilterType.scansOnly:
        result = result.where((d) => d.type == DocumentType.scan).toList();
        break;
      case DocumentFilterType.ocrOnly:
        result = result.where((d) => d.hasOcr).toList();
        break;
      case DocumentFilterType.favoritesOnly:
        result = result.where((d) => d.isFavorite).toList();
        break;
      case DocumentFilterType.all:
        break;
    }

    // Sort
    switch (_sortOption) {
      case DocumentSortOption.newest:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case DocumentSortOption.oldest:
        result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case DocumentSortOption.nameAsc:
        result.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case DocumentSortOption.nameDesc:
        result.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;
      case DocumentSortOption.sizeLargest:
        result.sort((a, b) => b.fileSize.compareTo(a.fileSize));
        break;
      case DocumentSortOption.sizeSmallest:
        result.sort((a, b) => a.fileSize.compareTo(b.fileSize));
        break;
    }

    return result;
  }
}
