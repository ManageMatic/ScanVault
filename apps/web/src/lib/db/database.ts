import Dexie, { type EntityTable } from 'dexie';
import {
  DB_NAME,
  DB_VERSION,
  type LocalDocument,
  type LocalDocumentFile,
  type LocalDocumentPage,
  type LocalFolder,
  type LocalThumbnail,
  type LocalRecentItem,
  type LocalSettings,
  type LocalOcrResult,
  type LocalAnnotation,
  type LocalSignature,
} from './schema';

/**
 * ScanVault Local IndexedDB Database using Dexie
 * Air-gapped, privacy-first client-side document vault.
 */
export class ScanVaultDatabase extends Dexie {
  documents!: EntityTable<LocalDocument, 'id'>;
  documentFiles!: EntityTable<LocalDocumentFile, 'id'>;
  documentPages!: EntityTable<LocalDocumentPage, 'id'>;
  folders!: EntityTable<LocalFolder, 'id'>;
  thumbnails!: EntityTable<LocalThumbnail, 'id'>;
  recentItems!: EntityTable<LocalRecentItem, 'id'>;
  localSettings!: EntityTable<LocalSettings, 'id'>;
  ocrResults!: EntityTable<LocalOcrResult, 'id'>;
  annotations!: EntityTable<LocalAnnotation, 'id'>;
  signatures!: EntityTable<LocalSignature, 'id'>;

  constructor(dbName = DB_NAME) {
    super(dbName);

    // Schema Version 1
    this.version(DB_VERSION).stores({
      documents:
        '&id, userId, folderId, favorite, status, deletedAt, updatedAt, lastOpenedAt, mimeType, source, [userId+deletedAt], [userId+favorite], [userId+folderId]',
      documentFiles: '&id, documentId, createdAt',
      documentPages: '&id, documentId, pageNumber, [documentId+pageNumber]',
      folders: '&id, userId, parentId, createdAt, [userId+parentId]',
      thumbnails: '&id, documentId, createdAt',
      recentItems: '&id, userId, documentId, openedAt, [userId+openedAt]',
      localSettings: '&id, userId, key, [userId+key]',
      ocrResults: '&id, pageId',
      annotations: '&id, pageId',
      signatures: '&id, createdAt',
    });
  }
}

// Export singleton instance
export const db = new ScanVaultDatabase();
