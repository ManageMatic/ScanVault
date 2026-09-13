import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../shared/models/document.dart';
import '../../../shared/models/folder.dart';
import 'documents_repository.dart';

enum DocumentSortOption { newest, oldest, nameAsc, nameDesc, sizeLargest, sizeSmallest }
enum DocumentFilterType { all, pdfOnly, scansOnly, ocrOnly, favoritesOnly }

/// Reactive state controller for document vault, folder organization, search, and pagination.
class DocumentsController extends ChangeNotifier {
  final DocumentsRepository _repository;

  DocumentsController(this._repository);

  static const int _pageSize = 30;

  List<Document> _documents = [];
  List<Folder> _folders = [];
  Map<String, int> _folderCounts = {};

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentOffset = 0;

  String _searchQuery = '';
  String? _selectedFolderId;
  DocumentSortOption _sortOption = DocumentSortOption.newest;
  DocumentFilterType _filterType = DocumentFilterType.all;
  bool _isGridView = false;

  int _totalDocumentCount = 0;
  int _totalStorageBytes = 0;

  List<Document> get documents => _documents;
  List<Folder> get folders => _folders;
  Map<String, int> get folderCounts => _folderCounts;

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;

  String get searchQuery => _searchQuery;
  String? get selectedFolderId => _selectedFolderId;
  Folder? get selectedFolder => _folders.where((f) => f.id == _selectedFolderId).firstOrNull;

  DocumentSortOption get sortOption => _sortOption;
  DocumentFilterType get filterType => _filterType;
  bool get isGridView => _isGridView;

  int get totalDocumentCount => _totalDocumentCount;
  int get totalStorageBytes => _totalStorageBytes;

  Future<void> loadData() async {
    _isLoading = true;
    _currentOffset = 0;
    _hasMore = true;
    notifyListeners();

    try {
      final fetchedDocs = await _repository.getDocumentsPaginated(
        limit: _pageSize,
        offset: 0,
        folderId: _selectedFolderId,
        searchQuery: _searchQuery,
        sortOption: _sortOption,
        filterType: _filterType,
      );

      _documents = fetchedDocs;
      _currentOffset = fetchedDocs.length;
      _hasMore = fetchedDocs.length >= _pageSize;

      _folders = await _repository.getAllFolders();
      _folderCounts = await _repository.getFolderDocumentCounts();
      _totalDocumentCount = await _repository.getTotalDocumentCount();
      _totalStorageBytes = await _repository.getTotalStorageBytes();
    } catch (e) {
      debugPrint('Error loading documents: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextChunk = await _repository.getDocumentsPaginated(
        limit: _pageSize,
        offset: _currentOffset,
        folderId: _selectedFolderId,
        searchQuery: _searchQuery,
        sortOption: _sortOption,
        filterType: _filterType,
      );

      if (nextChunk.isNotEmpty) {
        _documents.addAll(nextChunk);
        _currentOffset += nextChunk.length;
      }
      _hasMore = nextChunk.length >= _pageSize;
    } catch (e) {
      debugPrint('Error loading more documents: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    loadData();
  }

  void selectFolder(String? folderId) {
    if (_selectedFolderId == folderId) return;
    _selectedFolderId = folderId;
    loadData();
  }

  void setSortOption(DocumentSortOption option) {
    if (_sortOption == option) return;
    _sortOption = option;
    loadData();
  }

  void setFilterType(DocumentFilterType type) {
    if (_filterType == type) return;
    _filterType = type;
    loadData();
  }

  void toggleViewMode() {
    _isGridView = !_isGridView;
    notifyListeners();
  }

  Future<void> toggleFavorite(String documentId) async {
    // Optimistic UI update
    final idx = _documents.indexWhere((d) => d.id == documentId);
    if (idx >= 0) {
      final current = _documents[idx];
      _documents[idx] = current.copyWith(isFavorite: !current.isFavorite);
      notifyListeners();
    }

    try {
      await _repository.toggleFavorite(documentId);
    } catch (e) {
      debugPrint('Failed to toggle favorite: $e');
      await loadData();
    }
  }

  Future<void> renameDocument(String documentId, String newTitle) async {
    final cleanTitle = newTitle.trim();
    if (cleanTitle.isEmpty) return;

    try {
      await _repository.renameDocument(documentId, cleanTitle);
      await loadData();
    } catch (e) {
      debugPrint('Failed to rename document: $e');
    }
  }

  Future<void> moveDocumentToFolder(String documentId, String? folderId) async {
    try {
      await _repository.moveDocument(documentId, folderId);
      await loadData();
    } catch (e) {
      debugPrint('Failed to move document: $e');
    }
  }

  Future<void> deleteDocument(String documentId) async {
    try {
      await _repository.deleteDocument(documentId);
      await loadData();
    } catch (e) {
      debugPrint('Failed to delete document: $e');
    }
  }

  // --- Folder Management ---

  Future<Folder?> createFolder(String name, {String? colorHex, String? iconName}) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return null;

    final now = DateTime.now();
    final folder = Folder(
      id: const Uuid().v4(),
      name: cleanName,
      colorHex: colorHex ?? '#00685F',
      iconName: iconName ?? 'folder',
      createdAt: now,
      updatedAt: now,
    );

    try {
      await _repository.saveFolder(folder);
      await loadData();
      return folder;
    } catch (e) {
      debugPrint('Failed to create folder: $e');
      return null;
    }
  }

  Future<void> renameFolder(String folderId, String newName) async {
    final cleanName = newName.trim();
    if (cleanName.isEmpty) return;

    try {
      await _repository.renameFolder(folderId, cleanName);
      await loadData();
    } catch (e) {
      debugPrint('Failed to rename folder: $e');
    }
  }

  Future<void> deleteFolder(String folderId) async {
    try {
      if (_selectedFolderId == folderId) {
        _selectedFolderId = null;
      }
      await _repository.deleteFolder(folderId);
      await loadData();
    } catch (e) {
      debugPrint('Failed to delete folder: $e');
    }
  }
}
