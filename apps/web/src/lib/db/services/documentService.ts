import { db } from '../database';
import {
  MAX_IMPORT_SIZE_BYTES,
  SUPPORTED_PDF_MIME_TYPES,
  SUPPORTED_IMAGE_MIME_TYPES,
  type LocalDocument,
  type LocalDocumentFile,
  type LocalDocumentPage,
  type LocalThumbnail,
} from '../schema';
import { documentRepository } from '../repositories/documentRepository';
import { generateImageThumbnail } from './thumbnailService';

export interface FileValidationResult {
  valid: boolean;
  error?: string;
  kind?: 'pdf' | 'image';
}

/**
 * Validates a file before local import
 */
export function validateImportFile(file: File | Blob & { name?: string }): FileValidationResult {
  const fileName = (file as File).name || 'document';
  const extension = fileName.split('.').pop()?.toLowerCase() || '';
  const mimeType = file.type?.toLowerCase() || '';
  const size = file.size;

  if (size <= 0) {
    return { valid: false, error: 'The selected file is empty.' };
  }

  if (size > MAX_IMPORT_SIZE_BYTES) {
    return {
      valid: false,
      error: `File exceeds maximum allowed import size of ${Math.round(MAX_IMPORT_SIZE_BYTES / (1024 * 1024))} MB.`,
    };
  }

  // Check PDF
  const isPdfExt = extension === 'pdf';
  const isPdfMime = SUPPORTED_PDF_MIME_TYPES.includes(mimeType) || mimeType === 'application/pdf';
  if (isPdfExt || isPdfMime) {
    return { valid: true, kind: 'pdf' };
  }

  // Check Image
  const isImageExt = ['jpg', 'jpeg', 'png', 'webp'].includes(extension);
  const isImageMime =
    SUPPORTED_IMAGE_MIME_TYPES.includes(mimeType) || mimeType.startsWith('image/');
  if (isImageExt || isImageMime) {
    return { valid: true, kind: 'image' };
  }

  return {
    valid: false,
    error: `Unsupported file format (.${extension || 'unknown'}). Please select a PDF or image (JPG, PNG, WebP).`,
  };
}

export interface ImportOptions {
  folderId?: string | null;
  customTitle?: string;
  tags?: string[];
}

export const documentService = {
  /**
   * Imports a browser File or Blob into the local Dexie IndexedDB vault.
   */
  async importDocumentFile(
    file: File,
    userId: string,
    options: ImportOptions = {}
  ): Promise<LocalDocument> {
    if (!userId) {
      throw new Error('Authentication required to save local documents.');
    }

    const validation = validateImportFile(file);
    if (!validation.valid) {
      throw new Error(validation.error || 'Invalid file');
    }

    const isImage = validation.kind === 'image';
    const isPdf = validation.kind === 'pdf';

    const now = new Date();
    const docId = crypto.randomUUID ? crypto.randomUUID() : `doc-${Date.now()}-${Math.random().toString(36).substring(2, 9)}`;
    const fileId = crypto.randomUUID ? crypto.randomUUID() : `file-${Date.now()}-${Math.random().toString(36).substring(2, 9)}`;
    const thumbId = crypto.randomUUID ? crypto.randomUUID() : `thumb-${Date.now()}-${Math.random().toString(36).substring(2, 9)}`;

    // Generate clean title
    let title = options.customTitle || file.name || 'Untitled Document';
    if (!options.customTitle && title.includes('.')) {
      title = title.substring(0, title.lastIndexOf('.'));
    }

    const mimeType = file.type || (isPdf ? 'application/pdf' : 'image/jpeg');

    const documentRecord: LocalDocument = {
      id: docId,
      userId,
      title,
      mimeType,
      size: file.size,
      pageCount: 1, // Default 1 page for image / placeholder for PDF
      folderId: options.folderId || null,
      favorite: false,
      status: 'ready',
      createdAt: now,
      updatedAt: now,
      lastOpenedAt: now,
      deletedAt: null,
      thumbnailId: isImage ? thumbId : null,
      source: isPdf ? 'imported-pdf' : 'imported-image',
      version: 1,
      tags: options.tags || [],
    };

    const fileRecord: LocalDocumentFile = {
      id: fileId,
      documentId: docId,
      blob: file,
      mimeType,
      size: file.size,
      createdAt: now,
      updatedAt: now,
    };

    const pages: LocalDocumentPage[] = [];
    let thumbnail: LocalThumbnail | undefined;

    if (isImage) {
      const pageId = crypto.randomUUID ? crypto.randomUUID() : `page-${Date.now()}-${Math.random().toString(36).substring(2, 9)}`;
      pages.push({
        id: pageId,
        documentId: docId,
        pageNumber: 1,
        thumbnailId: thumbId,
        createdAt: now,
        updatedAt: now,
      });

      // Generate local thumbnail
      try {
        const thumbResult = await generateImageThumbnail(file, 300);
        if (thumbResult) {
          thumbnail = {
            id: thumbId,
            documentId: docId,
            blob: thumbResult.blob,
            mimeType: thumbResult.blob.type || 'image/jpeg',
            width: thumbResult.width,
            height: thumbResult.height,
            createdAt: now,
          };
        } else {
          documentRecord.thumbnailId = null;
        }
      } catch {
        documentRecord.thumbnailId = null;
      }
    }

    try {
      await documentRepository.createDocument(documentRecord, fileRecord, pages, thumbnail);
      return documentRecord;
    } catch (err: unknown) {
      const error = err as { name?: string; message?: string };
      if (
        error.name === 'QuotaExceededError' ||
        error.message?.toLowerCase().includes('quota')
      ) {
        throw new Error(
          "Your device doesn't have enough available storage for this document. Try deleting older files to free space."
        );
      }
      throw err;
    }
  },

  /**
   * Safe maintenance utility to clean up orphaned binary blobs and thumbnails
   */
  async cleanupOrphanedData(userId: string): Promise<{
    orphanedFiles: number;
    orphanedPages: number;
    orphanedThumbnails: number;
  }> {
    if (!userId) return { orphanedFiles: 0, orphanedPages: 0, orphanedThumbnails: 0 };

    const validDocs = await db.documents.where('userId').equals(userId).toArray();
    const validDocIds = new Set(validDocs.map((d) => d.id));

    let orphanedFiles = 0;
    let orphanedPages = 0;
    let orphanedThumbnails = 0;

    await db.transaction(
      'rw',
      db.documentFiles,
      db.documentPages,
      db.thumbnails,
      async () => {
        const files = await db.documentFiles.toArray();
        for (const file of files) {
          if (!validDocIds.has(file.documentId)) {
            await db.documentFiles.delete(file.id);
            orphanedFiles++;
          }
        }

        const pages = await db.documentPages.toArray();
        for (const page of pages) {
          if (!validDocIds.has(page.documentId)) {
            await db.documentPages.delete(page.id);
            orphanedPages++;
          }
        }

        const thumbnails = await db.thumbnails.toArray();
        for (const thumb of thumbnails) {
          if (!validDocIds.has(thumb.documentId)) {
            await db.thumbnails.delete(thumb.id);
            orphanedThumbnails++;
          }
        }
      }
    );

    return { orphanedFiles, orphanedPages, orphanedThumbnails };
  },
};
