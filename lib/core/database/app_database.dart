import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../../../shared/models/document.dart';
import '../../../shared/models/folder.dart';

/// Production asynchronous SQLite database with indexing and user data isolation.
class AppDatabase {
  static const String _dbName = 'scanvault_metadata.db';
  static const int _dbVersion = 1;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docsDir.path, _dbName);

    final databaseInstance = await openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: (db, version) async {
        // Folders Table
        await db.execute('''
          CREATE TABLE folders (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            name TEXT NOT NULL,
            color_hex TEXT,
            icon_name TEXT,
            created_at INTEGER NOT NULL
          )
        ''');

        await db.execute('CREATE INDEX idx_folders_user ON folders(user_id);');

        // Documents Table
        await db.execute('''
          CREATE TABLE documents (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            title TEXT NOT NULL,
            file_path TEXT NOT NULL,
            thumbnail_path TEXT,
            folder_id TEXT,
            mime_type TEXT NOT NULL,
            file_size_bytes INTEGER NOT NULL,
            page_count INTEGER NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            ocr_status TEXT,
            extracted_text TEXT,
            is_favorite INTEGER NOT NULL DEFAULT 0,
            is_locked INTEGER NOT NULL DEFAULT 0,
            compression_preset TEXT NOT NULL DEFAULT 'balanced'
          )
        ''');

        // Indexes for fast scalable lookups
        await db.execute('CREATE INDEX idx_documents_user ON documents(user_id);');
        await db.execute('CREATE INDEX idx_documents_user_created ON documents(user_id, created_at DESC);');
        await db.execute('CREATE INDEX idx_documents_user_fav ON documents(user_id, is_favorite);');
        await db.execute('CREATE INDEX idx_documents_user_folder ON documents(user_id, folder_id);');
      },
    );

    // Automatically purge any lingering demo documents and folders from early versions
    await databaseInstance.delete('documents', where: "id LIKE 'doc-%' OR id LIKE 'demo-%' OR id LIKE 'sample-%'");
    await databaseInstance.delete('folders', where: "id LIKE 'folder-%' OR id LIKE 'demo-%'");

    return databaseInstance;
  }

  // --- Document Operations ---

  Future<List<Document>> getDocumentsForUser(String userId, {String? folderId, bool? onlyFavorites, String? searchQuery}) async {
    final db = await database;
    final whereClauses = ['user_id = ?'];
    final whereArgs = <dynamic>[userId];

    if (folderId != null) {
      whereClauses.add('folder_id = ?');
      whereArgs.add(folderId);
    }
    if (onlyFavorites == true) {
      whereClauses.add('is_favorite = 1');
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereClauses.add('(title LIKE ? OR extracted_text LIKE ?)');
      whereArgs.add('%$searchQuery%');
      whereArgs.add('%$searchQuery%');
    }

    final maps = await db.query(
      'documents',
      where: whereClauses.join(' AND '),
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );

    return maps.map((m) => _documentFromMap(m)).toList();
  }

  Future<Document?> getDocumentById(String userId, String id) async {
    final db = await database;
    final maps = await db.query(
      'documents',
      where: 'user_id = ? AND id = ?',
      whereArgs: [userId, id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return _documentFromMap(maps.first);
  }

  Future<void> insertDocument(String userId, Document doc) async {
    final db = await database;
    final map = _documentToMap(doc, userId);
    await db.insert('documents', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateDocument(String userId, Document doc) async {
    final db = await database;
    final map = _documentToMap(doc, userId);
    await db.update(
      'documents',
      map,
      where: 'user_id = ? AND id = ?',
      whereArgs: [userId, doc.id],
    );
  }

  Future<void> deleteDocument(String userId, String id) async {
    final db = await database;
    await db.delete(
      'documents',
      where: 'user_id = ? AND id = ?',
      whereArgs: [userId, id],
    );
  }

  Future<void> purgeDemoDocuments() async {
    final db = await database;
    await db.delete('documents', where: "id LIKE 'doc-%' OR id LIKE 'demo-%' OR id LIKE 'sample-%'");
    await db.delete('folders', where: "id LIKE 'folder-%' OR id LIKE 'demo-%'");
  }

  // --- Folder Operations ---

  Future<List<Folder>> getFoldersForUser(String userId) async {
    final db = await database;
    final maps = await db.query(
      'folders',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at ASC',
    );

    if (maps.isEmpty) {
      // Seed default smart folders for user
      final now = DateTime.now();
      final defaultFolders = [
        Folder(id: 'personal_$userId', name: 'Personal', colorHex: '#0D9488', iconName: 'person', createdAt: now, updatedAt: now),
        Folder(id: 'work_$userId', name: 'Work & Tax', colorHex: '#F59E0B', iconName: 'work', createdAt: now, updatedAt: now),
        Folder(id: 'medical_$userId', name: 'Medical', colorHex: '#10B981', iconName: 'medical_services', createdAt: now, updatedAt: now),
        Folder(id: 'receipts_$userId', name: 'Receipts', colorHex: '#6366F1', iconName: 'receipt', createdAt: now, updatedAt: now),
      ];
      for (final f in defaultFolders) {
        await insertFolder(userId, f);
      }
      return defaultFolders;
    }

    return maps.map((m) => _folderFromMap(m)).toList();
  }

  Future<void> insertFolder(String userId, Folder folder) async {
    final db = await database;
    await db.insert('folders', {
      'id': folder.id,
      'user_id': userId,
      'name': folder.name,
      'color_hex': folder.colorHex,
      'icon_name': folder.iconName,
      'created_at': folder.createdAt.millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- Storage Aggregations ---

  Future<int> getTotalStorageBytesForUser(String userId) async {
    final db = await database;
    final res = await db.rawQuery('SELECT SUM(file_size_bytes) as total FROM documents WHERE user_id = ?', [userId]);
    return (res.first['total'] as int?) ?? 0;
  }

  Future<int> getTotalDocumentsCountForUser(String userId) async {
    final db = await database;
    final res = await db.rawQuery('SELECT COUNT(*) as total FROM documents WHERE user_id = ?', [userId]);
    return (res.first['total'] as int?) ?? 0;
  }

  // --- Mappings ---

  Map<String, dynamic> _documentToMap(Document doc, String userId) {
    return {
      'id': doc.id,
      'user_id': userId,
      'title': doc.title,
      'file_path': doc.filePath,
      'thumbnail_path': doc.thumbnailPath,
      'folder_id': doc.folderId,
      'mime_type': 'application/pdf',
      'file_size_bytes': doc.fileSize,
      'page_count': doc.pageCount,
      'created_at': doc.createdAt.millisecondsSinceEpoch,
      'updated_at': doc.updatedAt.millisecondsSinceEpoch,
      'ocr_status': doc.ocrStatus.name,
      'extracted_text': doc.extractedOcrText,
      'is_favorite': doc.isFavorite ? 1 : 0,
      'is_locked': doc.isLocked ? 1 : 0,
      'compression_preset': doc.compressionPreset.name,
    };
  }

  Document _documentFromMap(Map<String, dynamic> map) {
    return Document(
      id: map['id'] as String,
      title: map['title'] as String,
      pdfPath: map['file_path'] as String?,
      thumbnailPath: map['thumbnail_path'] as String?,
      folderId: map['folder_id'] as String?,
      fileSize: map['file_size_bytes'] as int? ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      extractedOcrText: map['extracted_text'] as String?,
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
      isLocked: (map['is_locked'] as int? ?? 0) == 1,
      compressionPreset: _parsePreset(map['compression_preset'] as String?),
      ocrStatus: _parseOcrStatus(map['ocr_status'] as String?),
    );
  }

  Folder _folderFromMap(Map<String, dynamic> map) {
    final created = DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int);
    return Folder(
      id: map['id'] as String,
      name: map['name'] as String,
      colorHex: map['color_hex'] as String? ?? '#0D9488',
      iconName: map['icon_name'] as String? ?? 'folder',
      createdAt: created,
      updatedAt: created,
    );
  }

  CompressionPreset _parsePreset(String? str) {
    switch (str) {
      case 'small':
        return CompressionPreset.small;
      case 'highQuality':
        return CompressionPreset.highQuality;
      default:
        return CompressionPreset.balanced;
    }
  }

  OcrStatus _parseOcrStatus(String? str) {
    switch (str) {
      case 'completed':
        return OcrStatus.completed;
      case 'processing':
        return OcrStatus.processing;
      case 'failed':
        return OcrStatus.failed;
      default:
        return OcrStatus.none;
    }
  }
}
