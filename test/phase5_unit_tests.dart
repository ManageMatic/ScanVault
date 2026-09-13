import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scanvault/core/database/app_database.dart';
import 'package:scanvault/features/documents/data/local_documents_repository.dart';
import 'package:scanvault/features/documents/domain/documents_controller.dart';
import 'package:scanvault/shared/models/document.dart';
import 'package:scanvault/shared/models/folder.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory tempDir;
  late AppDatabase appDb;
  late LocalDocumentsRepository repoUserA;
  late LocalDocumentsRepository repoUserB;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('scanvault_db_test_');

    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'getApplicationDocumentsDirectory' ||
            methodCall.method == 'getTemporaryDirectory') {
          return tempDir.path;
        }
        return null;
      },
    );
  });

  tearDownAll(() async {
    try {
      final db = await appDb.database;
      await db.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  setUp(() async {
    appDb = AppDatabase();
    repoUserA = LocalDocumentsRepository(
      db: appDb,
      userIdProvider: () => 'user_alpha',
    );
    repoUserB = LocalDocumentsRepository(
      db: appDb,
      userIdProvider: () => 'user_beta',
    );

    // Clean initial state
    final db = await appDb.database;
    await db.delete('documents');
    await db.delete('folders');
  });

  tearDown(() async {
    final db = await appDb.database;
    await db.delete('documents');
    await db.delete('folders');
  });

  group('Phase 5: User Isolation & Document Vault Security', () {
    test('User A cannot see User B documents or folders', () async {
      final now = DateTime.now();

      // Insert User A doc
      final docA = Document(
        id: 'doc_a_1',
        title: 'Secret Contract User A',
        fileSize: 1024,
        createdAt: now,
        updatedAt: now,
      );
      await repoUserA.saveDocument(docA);

      // Insert User B doc
      final docB = Document(
        id: 'doc_b_1',
        title: 'Invoice User B',
        fileSize: 2048,
        createdAt: now,
        updatedAt: now,
      );
      await repoUserB.saveDocument(docB);

      // Verify User A sees ONLY User A doc
      final docsA = await repoUserA.getAllDocuments();
      expect(docsA.length, 1);
      expect(docsA.first.id, 'doc_a_1');
      expect(docsA.first.title, 'Secret Contract User A');

      // Verify User B sees ONLY User B doc
      final docsB = await repoUserB.getAllDocuments();
      expect(docsB.length, 1);
      expect(docsB.first.id, 'doc_b_1');
      expect(docsB.first.title, 'Invoice User B');
    });
  });

  group('Phase 5: Database Pagination & Sorting', () {
    test('paginates large document collections and applies database sorting', () async {
      final now = DateTime.now();

      // Insert 35 documents for User A
      for (var i = 1; i <= 35; i++) {
        final doc = Document(
          id: 'doc_$i',
          title: 'Doc ${i.toString().padLeft(2, '0')}',
          fileSize: i * 100,
          createdAt: now.add(Duration(minutes: i)),
          updatedAt: now.add(Duration(minutes: i)),
        );
        await repoUserA.saveDocument(doc);
      }

      // Page 1: 30 items
      final page1 = await repoUserA.getDocumentsPaginated(
        limit: 30,
        offset: 0,
        sortOption: DocumentSortOption.newest,
      );
      expect(page1.length, 30);
      expect(page1.first.title, 'Doc 35'); // Newest first

      // Page 2: 5 items
      final page2 = await repoUserA.getDocumentsPaginated(
        limit: 30,
        offset: 30,
        sortOption: DocumentSortOption.newest,
      );
      expect(page2.length, 5);
      expect(page2.last.title, 'Doc 01');

      // Test Name Ascending Sort
      final sortedName = await repoUserA.getDocumentsPaginated(
        limit: 5,
        offset: 0,
        sortOption: DocumentSortOption.nameAsc,
      );
      expect(sortedName.first.title, 'Doc 01');

      // Test Size Largest Sort
      final sortedSize = await repoUserA.getDocumentsPaginated(
        limit: 5,
        offset: 0,
        sortOption: DocumentSortOption.sizeLargest,
      );
      expect(sortedSize.first.fileSize, 3500);
    });
  });

  group('Phase 5: Local Search & OCR Text Matching', () {
    test('searches by title and extracted OCR text accurately', () async {
      final now = DateTime.now();

      await repoUserA.saveDocument(Document(
        id: 'search_1',
        title: 'Electricity Utility Bill',
        extractedOcrText: 'Payment due on Oct 2026 total 150 USD',
        createdAt: now,
        updatedAt: now,
      ));

      await repoUserA.saveDocument(Document(
        id: 'search_2',
        title: 'Apartment Lease Agreement',
        extractedOcrText: 'Landlord signature and rental terms',
        createdAt: now,
        updatedAt: now,
      ));

      // Search by title match
      final titleMatch = await repoUserA.getDocumentsPaginated(searchQuery: 'Utility');
      expect(titleMatch.length, 1);
      expect(titleMatch.first.id, 'search_1');

      // Search by OCR extracted content match
      final ocrMatch = await repoUserA.getDocumentsPaginated(searchQuery: 'rental terms');
      expect(ocrMatch.length, 1);
      expect(ocrMatch.first.id, 'search_2');

      // No match
      final noMatch = await repoUserA.getDocumentsPaginated(searchQuery: 'NonExistentXYZ');
      expect(noMatch, isEmpty);
    });
  });

  group('Phase 5: Folder Management & Safe Unlinking', () {
    test('creates, renames, moves documents, and unlinks documents safely on folder deletion', () async {
      final now = DateTime.now();

      // Create Folder
      final folder = Folder(
        id: 'folder_tax',
        name: 'Tax 2026',
        createdAt: now,
        updatedAt: now,
      );
      await repoUserA.saveFolder(folder);

      // Create doc in folder
      final doc = Document(
        id: 'doc_tax_1',
        title: 'W2 Form',
        folderId: 'folder_tax',
        createdAt: now,
        updatedAt: now,
      );
      await repoUserA.saveDocument(doc);

      // Verify folder counts
      var counts = await repoUserA.getFolderDocumentCounts();
      expect(counts['folder_tax'], 1);

      // Rename Folder
      await repoUserA.renameFolder('folder_tax', 'Taxes & Finances');
      final folders = await repoUserA.getAllFolders();
      final renamed = folders.firstWhere((f) => f.id == 'folder_tax');
      expect(renamed.name, 'Taxes & Finances');

      // Delete Folder: Document MUST NOT be deleted, only unlinked (folderId = null)
      await repoUserA.deleteFolder('folder_tax');

      final remainingDoc = await repoUserA.getDocumentById('doc_tax_1');
      expect(remainingDoc, isNotNull);
      expect(remainingDoc!.title, 'W2 Form');
      expect(remainingDoc.folderId, isNull);

      counts = await repoUserA.getFolderDocumentCounts();
      expect(counts['folder_tax'], isNull);
    });
  });

  group('Phase 5: Document Rename, Move & Favorite Operations', () {
    test('renames, moves, and toggles favorite status reliably', () async {
      final now = DateTime.now();

      final doc = Document(
        id: 'op_doc_1',
        title: 'Original Title',
        isFavorite: false,
        createdAt: now,
        updatedAt: now,
      );
      await repoUserA.saveDocument(doc);

      // Toggle Favorite
      await repoUserA.toggleFavorite('op_doc_1');
      var updated = await repoUserA.getDocumentById('op_doc_1');
      expect(updated!.isFavorite, isTrue);

      // Rename Document
      await repoUserA.renameDocument('op_doc_1', 'Renamed Document Title');
      updated = await repoUserA.getDocumentById('op_doc_1');
      expect(updated!.title, 'Renamed Document Title');

      // Move Document to Folder
      await repoUserA.moveDocument('op_doc_1', 'custom_folder_id');
      updated = await repoUserA.getDocumentById('op_doc_1');
      expect(updated!.folderId, 'custom_folder_id');

      // Move back to root (null)
      await repoUserA.moveDocument('op_doc_1', null);
      updated = await repoUserA.getDocumentById('op_doc_1');
      expect(updated!.folderId, isNull);
    });
  });
}
