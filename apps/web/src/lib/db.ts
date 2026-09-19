import Dexie, { type EntityTable } from 'dexie';

export interface LocalDocument {
  id: string;
  userId?: string;
  folderId?: string | null;
  title: string;
  mimeType: string;
  size: number;
  pageCount: number;
  favorite: boolean;
  pdfBlob?: Blob;
  isSynced: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export interface LocalPage {
  id: string;
  documentId: string;
  pageNumber: number;
  imageBlob: Blob;
  thumbnailBlob?: Blob;
  width: number;
  height: number;
  createdAt: Date;
}

export interface LocalFolder {
  id: string;
  name: string;
  parentId?: string | null;
  createdAt: Date;
  updatedAt: Date;
}

export interface LocalOcr {
  id: string;
  pageId: string;
  text: string;
  language: string;
  createdAt: Date;
}

export interface LocalAnnotation {
  id: string;
  pageId: string;
  type: string;
  data: unknown;
  createdAt: Date;
}

export interface LocalSignature {
  id: string;
  name: string;
  data: unknown;
  createdAt: Date;
}

/**
 * Dexie IndexedDB client database for offline document vault
 */
export class ScanVaultLocalDB extends Dexie {
  documents!: EntityTable<LocalDocument, 'id'>;
  pages!: EntityTable<LocalPage, 'id'>;
  folders!: EntityTable<LocalFolder, 'id'>;
  ocrResults!: EntityTable<LocalOcr, 'id'>;
  annotations!: EntityTable<LocalAnnotation, 'id'>;
  signatures!: EntityTable<LocalSignature, 'id'>;

  constructor() {
    super('ScanVaultLocalDB');
    this.version(1).stores({
      documents: 'id, folderId, favorite, isSynced, createdAt, updatedAt',
      pages: 'id, documentId, pageNumber',
      folders: 'id, parentId, createdAt',
      ocrResults: 'id, pageId',
      annotations: 'id, pageId',
      signatures: 'id, createdAt',
    });
  }
}

export const db = new ScanVaultLocalDB();
