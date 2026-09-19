import { db } from '../database';
import type { LocalFolder } from '../schema';

export interface FolderWithCount extends LocalFolder {
  documentCount: number;
}

export const folderRepository = {
  async createFolder(folder: LocalFolder): Promise<string> {
    await db.folders.put(folder);
    return folder.id;
  },

  async getFoldersByUser(userId: string): Promise<FolderWithCount[]> {
    if (!userId) return [];

    const folders = await db.folders.where('userId').equals(userId).toArray();

    // Calculate document count per folder
    const counts = await Promise.all(
      folders.map(async (folder) => {
        const count = await db.documents
          .where('userId')
          .equals(userId)
          .filter((doc) => doc.folderId === folder.id && !doc.deletedAt)
          .count();
        return {
          ...folder,
          documentCount: count,
        };
      })
    );

    return counts.sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());
  },

  async getFolderById(id: string, userId: string): Promise<LocalFolder | undefined> {
    const folder = await db.folders.get(id);
    if (!folder || folder.userId !== userId) return undefined;
    return folder;
  },

  async renameFolder(id: string, userId: string, newName: string): Promise<boolean> {
    const trimmed = newName.trim();
    if (!trimmed) throw new Error('Folder name cannot be empty');

    const folder = await this.getFolderById(id, userId);
    if (!folder) return false;

    await db.folders.update(id, {
      name: trimmed,
      updatedAt: new Date(),
    });
    return true;
  },

  async setParentFolder(
    id: string,
    userId: string,
    parentId: string | null
  ): Promise<boolean> {
    const folder = await this.getFolderById(id, userId);
    if (!folder) return false;

    if (parentId) {
      if (parentId === id) {
        throw new Error('A folder cannot be its own parent');
      }
      // Check for circular inheritance
      let currentParentId: string | null | undefined = parentId;
      while (currentParentId) {
        if (currentParentId === id) {
          throw new Error('Circular folder hierarchy is not allowed');
        }
        const parent = await this.getFolderById(currentParentId, userId);
        currentParentId = parent?.parentId;
      }
    }

    await db.folders.update(id, {
      parentId: parentId || null,
      updatedAt: new Date(),
    });
    return true;
  },

  async deleteFolder(id: string, userId: string): Promise<boolean> {
    const folder = await this.getFolderById(id, userId);
    if (!folder) return false;

    return db.transaction('rw', db.folders, db.documents, async () => {
      // 1. Move any documents in this folder to root (folderId = null)
      const docsInFolder = await db.documents
        .where('userId')
        .equals(userId)
        .filter((d) => d.folderId === id)
        .toArray();

      for (const doc of docsInFolder) {
        await db.documents.update(doc.id, {
          folderId: null,
          updatedAt: new Date(),
        });
      }

      // 2. Move subfolders to root as well
      const subfolders = await db.folders
        .where('userId')
        .equals(userId)
        .filter((f) => f.parentId === id)
        .toArray();

      for (const sub of subfolders) {
        await db.folders.update(sub.id, {
          parentId: null,
          updatedAt: new Date(),
        });
      }

      // 3. Delete the folder itself
      await db.folders.delete(id);
      return true;
    });
  },
};
