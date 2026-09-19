import { db } from '../database';
import type {
  LocalDocument,
  LocalDocumentFile,
  LocalDocumentPage,
  LocalThumbnail,
} from '../schema';

export type DocumentSortOption =
  | 'modified-desc'
  | 'modified-asc'
  | 'opened-desc'
  | 'name-asc'
  | 'name-desc'
  | 'size-desc'
  | 'size-asc';

export interface DocumentQueryOptions {
  tab?: 'all' | 'favorites' | 'recent' | 'trash' | 'folder';
  folderId?: string | null;
  search?: string;
  sortBy?: DocumentSortOption;
  mimeFilter?: 'all' | 'pdf' | 'images';
}

export const documentRepository = {
  /**
   * Atomic document creation coordinating metadata, binary blob, pages, and thumbnail.
   */
  async createDocument(
    document: LocalDocument,
    file: LocalDocumentFile,
    pages: LocalDocumentPage[] = [],
    thumbnail?: LocalThumbnail
  ): Promise<string> {
    return db.transaction(
      'rw',
      db.documents,
      db.documentFiles,
      db.documentPages,
      db.thumbnails,
      async () => {
        await db.documents.put(document);
        await db.documentFiles.put(file);

        if (pages.length > 0) {
          await db.documentPages.bulkPut(pages);
        }

        if (thumbnail) {
          await db.thumbnails.put(thumbnail);
        }

        return document.id;
      }
    );
  },

  async getDocumentById(id: string, userId: string): Promise<LocalDocument | undefined> {
    const doc = await db.documents.get(id);
    if (!doc || doc.userId !== userId) return undefined;
    return doc;
  },

  async getDocumentsByUser(
    userId: string,
    options: DocumentQueryOptions = {}
  ): Promise<LocalDocument[]> {
    if (!userId) return [];

    const {
      tab = 'all',
      folderId,
      search = '',
      sortBy = 'modified-desc',
      mimeFilter = 'all',
    } = options;

    const collection = db.documents.where('userId').equals(userId);

    let items = await collection.toArray();

    // 1. Filter by Tab / Trash state
    if (tab === 'trash') {
      items = items.filter((d) => d.deletedAt != null);
    } else {
      // Non-trash views MUST exclude soft-deleted items
      items = items.filter((d) => d.deletedAt == null);

      if (tab === 'favorites') {
        items = items.filter((d) => d.favorite);
      } else if (tab === 'recent') {
        items = items.filter((d) => d.lastOpenedAt != null);
      } else if (tab === 'folder') {
        if (folderId !== undefined) {
          items = items.filter((d) => d.folderId === folderId);
        }
      }
    }

    // 2. Filter by MIME type if specified
    if (mimeFilter === 'pdf') {
      items = items.filter((d) => d.mimeType === 'application/pdf');
    } else if (mimeFilter === 'images') {
      items = items.filter((d) => d.mimeType.startsWith('image/'));
    }

    // 3. Search by title
    const query = search.trim().toLowerCase();
    if (query) {
      items = items.filter((d) => d.title.toLowerCase().includes(query));
    }

    // 4. Sort
    items.sort((a, b) => {
      switch (sortBy) {
        case 'opened-desc': {
          const aTime = a.lastOpenedAt ? new Date(a.lastOpenedAt).getTime() : 0;
          const bTime = b.lastOpenedAt ? new Date(b.lastOpenedAt).getTime() : 0;
          return bTime - aTime;
        }
        case 'modified-asc':
          return new Date(a.updatedAt).getTime() - new Date(b.updatedAt).getTime();
        case 'modified-desc':
          return new Date(b.updatedAt).getTime() - new Date(a.updatedAt).getTime();
        case 'name-asc':
          return a.title.localeCompare(b.title, undefined, { sensitivity: 'base' });
        case 'name-desc':
          return b.title.localeCompare(a.title, undefined, { sensitivity: 'base' });
        case 'size-desc':
          return b.size - a.size;
        case 'size-asc':
          return a.size - b.size;
        default:
          return new Date(b.updatedAt).getTime() - new Date(a.updatedAt).getTime();
      }
    });

    return items;
  },

  async updateDocument(
    id: string,
    userId: string,
    updates: Partial<Omit<LocalDocument, 'id' | 'userId' | 'createdAt'>>
  ): Promise<boolean> {
    const doc = await this.getDocumentById(id, userId);
    if (!doc) return false;

    await db.documents.update(id, {
      ...updates,
      updatedAt: new Date(),
    });
    return true;
  },

  async renameDocument(id: string, userId: string, newTitle: string): Promise<boolean> {
    const trimmed = newTitle.trim();
    if (!trimmed) throw new Error('Document title cannot be empty');
    return this.updateDocument(id, userId, { title: trimmed });
  },

  async toggleFavorite(id: string, userId: string): Promise<boolean> {
    const doc = await this.getDocumentById(id, userId);
    if (!doc) return false;
    const newFavorite = !doc.favorite;
    await this.updateDocument(id, userId, { favorite: newFavorite });
    return newFavorite;
  },

  async moveToFolder(
    id: string,
    userId: string,
    folderId: string | null
  ): Promise<boolean> {
    if (folderId) {
      const folder = await db.folders.get(folderId);
      if (!folder || folder.userId !== userId) {
        throw new Error('Target folder does not exist');
      }
    }
    return this.updateDocument(id, userId, { folderId });
  },

  async softDeleteDocument(id: string, userId: string): Promise<boolean> {
    const doc = await this.getDocumentById(id, userId);
    if (!doc) return false;

    await db.documents.update(id, {
      deletedAt: new Date(),
      updatedAt: new Date(),
    });
    return true;
  },

  async restoreDocument(id: string, userId: string): Promise<boolean> {
    const doc = await this.getDocumentById(id, userId);
    if (!doc) return false;

    // Check if the document's original folder still exists
    let folderId = doc.folderId;
    if (folderId) {
      const folder = await db.folders.get(folderId);
      if (!folder || folder.userId !== userId) {
        folderId = null;
      }
    }

    await db.documents.update(id, {
      deletedAt: null,
      folderId,
      updatedAt: new Date(),
    });
    return true;
  },

  async permanentlyDeleteDocument(id: string, userId: string): Promise<boolean> {
    const doc = await this.getDocumentById(id, userId);
    if (!doc) return false;

    return db.transaction(
      'rw',
      db.documents,
      db.documentFiles,
      db.documentPages,
      db.thumbnails,
      db.recentItems,
      async () => {
        // Delete document file
        await db.documentFiles.where('documentId').equals(id).delete();

        // Delete document pages
        await db.documentPages.where('documentId').equals(id).delete();

        // Delete thumbnail
        await db.thumbnails.where('documentId').equals(id).delete();

        // Delete recent item references
        await db.recentItems.where('documentId').equals(id).delete();

        // Delete document record
        await db.documents.delete(id);

        return true;
      }
    );
  },

  async duplicateDocument(id: string, userId: string): Promise<LocalDocument | null> {
    const originalDoc = await this.getDocumentById(id, userId);
    if (!originalDoc) return null;

    const originalFile = await db.documentFiles.where('documentId').equals(id).first();
    const originalPages = await db.documentPages.where('documentId').equals(id).toArray();
    const originalThumb = await db.thumbnails.where('documentId').equals(id).first();

    const newDocId = crypto.randomUUID ? crypto.randomUUID() : `doc-${Date.now()}-${Math.random().toString(36).substring(2, 9)}`;
    const newFileId = crypto.randomUUID ? crypto.randomUUID() : `file-${Date.now()}-${Math.random().toString(36).substring(2, 9)}`;
    const newThumbId = originalThumb
      ? crypto.randomUUID
        ? crypto.randomUUID()
        : `thumb-${Date.now()}-${Math.random().toString(36).substring(2, 9)}`
      : null;

    const now = new Date();

    const duplicatedDoc: LocalDocument = {
      ...originalDoc,
      id: newDocId,
      title: `${originalDoc.title} (Copy)`,
      thumbnailId: newThumbId,
      createdAt: now,
      updatedAt: now,
      lastOpenedAt: null,
      deletedAt: null,
    };

    const duplicatedFile: LocalDocumentFile = {
      id: newFileId,
      documentId: newDocId,
      blob: originalFile ? originalFile.blob : new Blob([]),
      mimeType: originalDoc.mimeType,
      size: originalDoc.size,
      createdAt: now,
      updatedAt: now,
    };

    const duplicatedPages: LocalDocumentPage[] = originalPages.map((page) => ({
      ...page,
      id: crypto.randomUUID ? crypto.randomUUID() : `page-${Date.now()}-${Math.random().toString(36).substring(2, 9)}`,
      documentId: newDocId,
      createdAt: now,
      updatedAt: now,
    }));

    const duplicatedThumb: LocalThumbnail | undefined = originalThumb
      ? {
          id: newThumbId!,
          documentId: newDocId,
          blob: originalThumb.blob,
          mimeType: originalThumb.mimeType,
          width: originalThumb.width,
          height: originalThumb.height,
          createdAt: now,
        }
      : undefined;

    await this.createDocument(
      duplicatedDoc,
      duplicatedFile,
      duplicatedPages,
      duplicatedThumb
    );

    return duplicatedDoc;
  },

  async recordDocumentOpen(id: string, userId: string): Promise<void> {
    const doc = await this.getDocumentById(id, userId);
    if (!doc) return;

    const now = new Date();
    await db.documents.update(id, {
      lastOpenedAt: now,
      updatedAt: now,
    });

    const recentId = `rec-${userId}-${id}`;
    await db.recentItems.put({
      id: recentId,
      userId,
      documentId: id,
      openedAt: now,
    });
  },
};
