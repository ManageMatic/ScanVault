export type DocumentSource = 'imported-pdf' | 'imported-image' | 'scanned' | 'generated-pdf';

export type DocumentStatus = 'ready' | 'processing' | 'error';

export interface LocalDocument {
  id: string;
  userId: string;
  title: string;
  mimeType: string;
  size: number;
  pageCount: number;
  folderId?: string | null;
  favorite: boolean;
  status: DocumentStatus;
  createdAt: Date;
  updatedAt: Date;
  lastOpenedAt?: Date | null;
  deletedAt?: Date | null;
  thumbnailId?: string | null;
  source: DocumentSource;
  version: number;
  tags?: string[];
  thumbnailColor?: string;
}

export interface LocalDocumentFile {
  id: string;
  documentId: string;
  blob: Blob;
  mimeType: string;
  size: number;
  createdAt: Date;
  updatedAt: Date;
}

export interface LocalDocumentPage {
  id: string;
  documentId: string;
  pageNumber: number;
  width?: number;
  height?: number;
  imageBlobId?: string | null;
  thumbnailId?: string | null;
  createdAt: Date;
  updatedAt: Date;
}

export interface LocalFolder {
  id: string;
  userId: string;
  name: string;
  parentId?: string | null;
  color?: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface LocalThumbnail {
  id: string;
  documentId: string;
  blob: Blob;
  mimeType: string;
  width: number;
  height: number;
  createdAt: Date;
}

export interface LocalRecentItem {
  id: string;
  userId: string;
  documentId: string;
  openedAt: Date;
}

export interface LocalSettings {
  id: string;
  userId: string;
  key: string;
  value: unknown;
  updatedAt: Date;
}

export interface LocalOcrResult {
  id: string;
  pageId: string;
  text: string;
  language?: string;
  confidence?: number;
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

export const DB_NAME = 'scanvault';
export const DB_VERSION = 1;

/** Max upload size limit (100 MB) */
export const MAX_IMPORT_SIZE_BYTES = 100 * 1024 * 1024;

/** Supported import MIME types */
export const SUPPORTED_PDF_MIME_TYPES = ['application/pdf'];
export const SUPPORTED_IMAGE_MIME_TYPES = [
  'image/jpeg',
  'image/png',
  'image/webp',
];
