import 'fake-indexeddb/auto';
import { describe, it, expect, beforeEach } from 'vitest';
import {
  db,
  ScanVaultDatabase,
  documentRepository,
  folderRepository,
  fileRepository,
  documentService,
  validateImportFile,
  getStorageQuotaInfo,
  DB_VERSION,
  type LocalDocument,
  type LocalDocumentFile,
  type LocalFolder,
} from '../lib/db';

describe('ScanVault Local Document Vault (Module 04)', () => {
  beforeEach(async () => {
    // Clear all tables before each test
    await db.documents.clear();
    await db.documentFiles.clear();
    await db.documentPages.clear();
    await db.folders.clear();
    await db.thumbnails.clear();
    await db.recentItems.clear();
    await db.localSettings.clear();
  });

  describe('1. Dexie Database Initialization & Schema', () => {
    it('instantiates Dexie database with correct name and version', () => {
      expect(db).toBeInstanceOf(ScanVaultDatabase);
      expect(db.name).toBe('scanvault');
      expect(db.verno).toBe(DB_VERSION);
    });

    it('contains all required tables for local document workspace', () => {
      const tableNames = db.tables.map((t) => t.name);
      expect(tableNames).toEqual(
        expect.arrayContaining([
          'documents',
          'documentFiles',
          'documentPages',
          'folders',
          'thumbnails',
          'recentItems',
          'localSettings',
          'ocrResults',
          'annotations',
          'signatures',
        ])
      );
    });
  });

  describe('2. Document Creation & Atomic Storage', () => {
    it('creates document with binary file blob atomically', async () => {
      const docId = 'doc-test-1';
      const userId = 'user-1';
      const fileBlob = new Blob(['sample pdf content'], { type: 'application/pdf' });

      const doc: LocalDocument = {
        id: docId,
        userId,
        title: 'Contract 2026',
        mimeType: 'application/pdf',
        size: fileBlob.size,
        pageCount: 1,
        favorite: false,
        status: 'ready',
        createdAt: new Date(),
        updatedAt: new Date(),
        source: 'imported-pdf',
        version: 1,
      };

      const file: LocalDocumentFile = {
        id: 'file-test-1',
        documentId: docId,
        blob: fileBlob,
        mimeType: 'application/pdf',
        size: fileBlob.size,
        createdAt: new Date(),
        updatedAt: new Date(),
      };

      await documentRepository.createDocument(doc, file);

      const savedDoc = await documentRepository.getDocumentById(docId, userId);
      expect(savedDoc).toBeDefined();
      expect(savedDoc?.title).toBe('Contract 2026');

      const savedFile = await fileRepository.getFileByDocumentId(docId);
      expect(savedFile).toBeDefined();
      expect(savedFile?.size).toBe(fileBlob.size);
    });
  });

  describe('3. Document Retrieval & User Isolation', () => {
    it('isolates documents between different users', async () => {
      const user1 = 'user-alice';
      const user2 = 'user-bob';

      const doc1: LocalDocument = {
        id: 'doc-alice',
        userId: user1,
        title: "Alice's Secret",
        mimeType: 'application/pdf',
        size: 100,
        pageCount: 1,
        favorite: false,
        status: 'ready',
        createdAt: new Date(),
        updatedAt: new Date(),
        source: 'imported-pdf',
        version: 1,
      };

      const doc2: LocalDocument = {
        id: 'doc-bob',
        userId: user2,
        title: "Bob's Report",
        mimeType: 'application/pdf',
        size: 200,
        pageCount: 1,
        favorite: false,
        status: 'ready',
        createdAt: new Date(),
        updatedAt: new Date(),
        source: 'imported-pdf',
        version: 1,
      };

      await db.documents.bulkPut([doc1, doc2]);

      const aliceDocs = await documentRepository.getDocumentsByUser(user1);
      expect(aliceDocs).toHaveLength(1);
      expect(aliceDocs[0]!.title).toBe("Alice's Secret");

      const bobDocs = await documentRepository.getDocumentsByUser(user2);
      expect(bobDocs).toHaveLength(1);
      expect(bobDocs[0]!.title).toBe("Bob's Report");

      // Attempting to access Alice's document with Bob's userId returns undefined
      const unauthorized = await documentRepository.getDocumentById('doc-alice', user2);
      expect(unauthorized).toBeUndefined();
    });
  });

  describe('4. Favorites, Rename & Updates', () => {
    it('toggles favorite status', async () => {
      const doc: LocalDocument = {
        id: 'doc-fav',
        userId: 'user-1',
        title: 'Tax Invoice',
        mimeType: 'application/pdf',
        size: 150,
        pageCount: 1,
        favorite: false,
        status: 'ready',
        createdAt: new Date(),
        updatedAt: new Date(),
        source: 'imported-pdf',
        version: 1,
      };
      await db.documents.put(doc);

      const favState1 = await documentRepository.toggleFavorite('doc-fav', 'user-1');
      expect(favState1).toBe(true);

      const favList = await documentRepository.getDocumentsByUser('user-1', { tab: 'favorites' });
      expect(favList).toHaveLength(1);

      const favState2 = await documentRepository.toggleFavorite('doc-fav', 'user-1');
      expect(favState2).toBe(false);

      const favListAfter = await documentRepository.getDocumentsByUser('user-1', { tab: 'favorites' });
      expect(favListAfter).toHaveLength(0);
    });

    it('renames document with validation', async () => {
      const doc: LocalDocument = {
        id: 'doc-rename',
        userId: 'user-1',
        title: 'Old Name',
        mimeType: 'application/pdf',
        size: 150,
        pageCount: 1,
        favorite: false,
        status: 'ready',
        createdAt: new Date(),
        updatedAt: new Date(),
        source: 'imported-pdf',
        version: 1,
      };
      await db.documents.put(doc);

      await documentRepository.renameDocument('doc-rename', 'user-1', 'New Document Title');
      const updated = await documentRepository.getDocumentById('doc-rename', 'user-1');
      expect(updated?.title).toBe('New Document Title');

      await expect(
        documentRepository.renameDocument('doc-rename', 'user-1', '   ')
      ).rejects.toThrow('Document title cannot be empty');
    });
  });

  describe('5. Soft Delete, Restore & Permanent Deletion', () => {
    it('moves document to trash and restores it', async () => {
      const doc: LocalDocument = {
        id: 'doc-trash',
        userId: 'user-1',
        title: 'Temporary Draft',
        mimeType: 'application/pdf',
        size: 500,
        pageCount: 1,
        favorite: true,
        status: 'ready',
        createdAt: new Date(),
        updatedAt: new Date(),
        source: 'imported-pdf',
        version: 1,
      };
      await db.documents.put(doc);

      // Move to trash
      await documentRepository.softDeleteDocument('doc-trash', 'user-1');

      // Normal queries must exclude trashed documents
      const activeDocs = await documentRepository.getDocumentsByUser('user-1', { tab: 'all' });
      expect(activeDocs).toHaveLength(0);

      const favDocs = await documentRepository.getDocumentsByUser('user-1', { tab: 'favorites' });
      expect(favDocs).toHaveLength(0);

      // Trash tab must include it
      const trashDocs = await documentRepository.getDocumentsByUser('user-1', { tab: 'trash' });
      expect(trashDocs).toHaveLength(1);
      expect(trashDocs[0]!.id).toBe('doc-trash');

      // Restore document
      await documentRepository.restoreDocument('doc-trash', 'user-1');
      const restoredDocs = await documentRepository.getDocumentsByUser('user-1', { tab: 'all' });
      expect(restoredDocs).toHaveLength(1);
      expect(restoredDocs[0]!.deletedAt).toBeNull();
    });

    it('permanently deletes document and cascades to blobs/pages/thumbnails', async () => {
      const docId = 'doc-perm';
      const fileId = 'file-perm';
      const thumbId = 'thumb-perm';

      await documentRepository.createDocument(
        {
          id: docId,
          userId: 'user-1',
          title: 'To Be Erased',
          mimeType: 'image/png',
          size: 1024,
          pageCount: 1,
          favorite: false,
          status: 'ready',
          createdAt: new Date(),
          updatedAt: new Date(),
          source: 'imported-image',
          version: 1,
        },
        {
          id: fileId,
          documentId: docId,
          blob: new Blob(['png-bytes'], { type: 'image/png' }),
          mimeType: 'image/png',
          size: 1024,
          createdAt: new Date(),
          updatedAt: new Date(),
        },
        [
          {
            id: 'page-perm',
            documentId: docId,
            pageNumber: 1,
            createdAt: new Date(),
            updatedAt: new Date(),
          },
        ],
        {
          id: thumbId,
          documentId: docId,
          blob: new Blob(['thumb-bytes'], { type: 'image/jpeg' }),
          mimeType: 'image/jpeg',
          width: 300,
          height: 200,
          createdAt: new Date(),
        }
      );

      // Permanently delete
      await documentRepository.permanentlyDeleteDocument(docId, 'user-1');

      expect(await db.documents.get(docId)).toBeUndefined();
      expect(await db.documentFiles.where('documentId').equals(docId).first()).toBeUndefined();
      expect(await db.documentPages.where('documentId').equals(docId).toArray()).toHaveLength(0);
      expect(await db.thumbnails.where('documentId').equals(docId).first()).toBeUndefined();
    });
  });

  describe('6. Duplicate Document', () => {
    it('clones document with new IDs and copy suffix', async () => {
      const originalDocId = 'doc-orig';
      const originalBlob = new Blob(['pdf data'], { type: 'application/pdf' });

      await documentRepository.createDocument(
        {
          id: originalDocId,
          userId: 'user-1',
          title: 'Original Project',
          mimeType: 'application/pdf',
          size: originalBlob.size,
          pageCount: 2,
          favorite: true,
          status: 'ready',
          createdAt: new Date(),
          updatedAt: new Date(),
          source: 'imported-pdf',
          version: 1,
        },
        {
          id: 'file-orig',
          documentId: originalDocId,
          blob: originalBlob,
          mimeType: 'application/pdf',
          size: originalBlob.size,
          createdAt: new Date(),
          updatedAt: new Date(),
        }
      );

      const duplicated = await documentRepository.duplicateDocument(originalDocId, 'user-1');
      expect(duplicated).toBeDefined();
      expect(duplicated?.id).not.toBe(originalDocId);
      expect(duplicated?.title).toBe('Original Project (Copy)');

      const duplicatedFile = await fileRepository.getFileByDocumentId(duplicated!.id);
      expect(duplicatedFile).toBeDefined();
      expect(duplicatedFile?.size).toBe(originalBlob.size);
    });
  });

  describe('7. Folders & Hierarchies', () => {
    it('creates folders, prevents circular parents, and cascades deletion safely', async () => {
      const folderA: LocalFolder = {
        id: 'folder-a',
        userId: 'user-1',
        name: 'Work',
        createdAt: new Date(),
        updatedAt: new Date(),
      };
      const folderB: LocalFolder = {
        id: 'folder-b',
        userId: 'user-1',
        name: 'Projects',
        parentId: 'folder-a',
        createdAt: new Date(),
        updatedAt: new Date(),
      };

      await folderRepository.createFolder(folderA);
      await folderRepository.createFolder(folderB);

      // Verify circular hierarchy rejection
      await expect(
        folderRepository.setParentFolder('folder-a', 'user-1', 'folder-a')
      ).rejects.toThrow('A folder cannot be its own parent');

      // Put document into folder-b
      await db.documents.put({
        id: 'doc-in-folder',
        userId: 'user-1',
        title: 'Folder Child Doc',
        folderId: 'folder-b',
        mimeType: 'application/pdf',
        size: 100,
        pageCount: 1,
        favorite: false,
        status: 'ready',
        createdAt: new Date(),
        updatedAt: new Date(),
        source: 'imported-pdf',
        version: 1,
      });

      // Deleting folder-b must safely move documents to root
      await folderRepository.deleteFolder('folder-b', 'user-1');

      const docAfter = await db.documents.get('doc-in-folder');
      expect(docAfter?.folderId).toBeNull();
      expect(await db.folders.get('folder-b')).toBeUndefined();
    });
  });

  describe('8. Search & Sorting', () => {
    it('searches documents by title case-insensitively', async () => {
      await db.documents.bulkPut([
        {
          id: 'doc-alpha',
          userId: 'user-search',
          title: 'Financial Quarterly Report',
          mimeType: 'application/pdf',
          size: 100,
          pageCount: 1,
          favorite: false,
          status: 'ready',
          createdAt: new Date(),
          updatedAt: new Date(),
          source: 'imported-pdf',
          version: 1,
        },
        {
          id: 'doc-beta',
          userId: 'user-search',
          title: 'Design Blueprint Architecture',
          mimeType: 'application/pdf',
          size: 200,
          pageCount: 1,
          favorite: false,
          status: 'ready',
          createdAt: new Date(),
          updatedAt: new Date(),
          source: 'imported-pdf',
          version: 1,
        },
      ]);

      const results = await documentRepository.getDocumentsByUser('user-search', {
        search: 'quarterly',
      });
      expect(results).toHaveLength(1);
      expect(results[0]!.title).toBe('Financial Quarterly Report');
    });

    it('sorts documents by name and size correctly', async () => {
      await db.documents.bulkPut([
        {
          id: 'doc-z',
          userId: 'user-sort',
          title: 'Zebra Doc',
          mimeType: 'application/pdf',
          size: 100,
          pageCount: 1,
          favorite: false,
          status: 'ready',
          createdAt: new Date('2026-01-01'),
          updatedAt: new Date('2026-01-01'),
          source: 'imported-pdf',
          version: 1,
        },
        {
          id: 'doc-a',
          userId: 'user-sort',
          title: 'Apple Doc',
          mimeType: 'application/pdf',
          size: 500,
          pageCount: 1,
          favorite: false,
          status: 'ready',
          createdAt: new Date('2026-02-01'),
          updatedAt: new Date('2026-02-01'),
          source: 'imported-pdf',
          version: 1,
        },
      ]);

      const nameAsc = await documentRepository.getDocumentsByUser('user-sort', {
        sortBy: 'name-asc',
      });
      expect(nameAsc[0]!.title).toBe('Apple Doc');

      const sizeDesc = await documentRepository.getDocumentsByUser('user-sort', {
        sortBy: 'size-desc',
      });
      expect(sizeDesc[0]!.title).toBe('Apple Doc');
      expect(sizeDesc[1]!.title).toBe('Zebra Doc');
    });
  });

  describe('9. File Validation & Document Service Import Pipeline', () => {
    it('validates file types and sizes properly', () => {
      const validPdf = new File(['pdf-content'], 'statement.pdf', {
        type: 'application/pdf',
      });
      expect(validateImportFile(validPdf).valid).toBe(true);

      const validImg = new File(['img-content'], 'scan.jpg', {
        type: 'image/jpeg',
      });
      expect(validateImportFile(validImg).valid).toBe(true);

      const invalidExe = new File(['binary'], 'virus.exe', {
        type: 'application/octet-stream',
      });
      expect(validateImportFile(invalidExe).valid).toBe(false);

      const emptyFile = new File([], 'empty.pdf', {
        type: 'application/pdf',
      });
      expect(validateImportFile(emptyFile).valid).toBe(false);
    });

    it('imports PDF file through documentService into local IndexedDB', async () => {
      const pdfFile = new File(['real-pdf-binary-data'], 'Monthly Invoice.pdf', {
        type: 'application/pdf',
      });

      const importedDoc = await documentService.importDocumentFile(pdfFile, 'user-import');
      expect(importedDoc.title).toBe('Monthly Invoice');
      expect(importedDoc.source).toBe('imported-pdf');
      expect(importedDoc.size).toBe(pdfFile.size);

      const dbDoc = await documentRepository.getDocumentById(importedDoc.id, 'user-import');
      expect(dbDoc).toBeDefined();

      const dbFile = await fileRepository.getFileByDocumentId(importedDoc.id);
      expect(dbFile).toBeDefined();
      expect(dbFile?.blob.size).toBe(pdfFile.size);
    });
  });

  describe('10. Orphan Cleanup & Storage Quota', () => {
    it('cleans up orphaned files and thumbnails', async () => {
      // Create orphaned file and thumbnail with non-existent document ID
      await db.documentFiles.put({
        id: 'orphan-file',
        documentId: 'non-existent-doc',
        blob: new Blob(['orphan']),
        mimeType: 'application/pdf',
        size: 10,
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      await db.thumbnails.put({
        id: 'orphan-thumb',
        documentId: 'non-existent-doc',
        blob: new Blob(['orphan-thumb']),
        mimeType: 'image/jpeg',
        width: 100,
        height: 100,
        createdAt: new Date(),
      });

      const cleanup = await documentService.cleanupOrphanedData('user-1');
      expect(cleanup.orphanedFiles).toBe(1);
      expect(cleanup.orphanedThumbnails).toBe(1);

      expect(await db.documentFiles.get('orphan-file')).toBeUndefined();
      expect(await db.thumbnails.get('orphan-thumb')).toBeUndefined();
    });

    it('returns graceful storage info in node / test environment', async () => {
      const quota = await getStorageQuotaInfo();
      expect(quota).toBeDefined();
      expect(typeof quota.usage).toBe('number');
      expect(typeof quota.isSupported).toBe('boolean');
    });
  });
});
