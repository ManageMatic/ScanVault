import { db } from '../database';
import type { LocalDocumentFile } from '../schema';

export const fileRepository = {
  async saveFile(fileData: LocalDocumentFile): Promise<string> {
    await db.documentFiles.put(fileData);
    return fileData.id;
  },

  async getFileByDocumentId(documentId: string): Promise<LocalDocumentFile | undefined> {
    return db.documentFiles.where('documentId').equals(documentId).first();
  },

  async getFileById(id: string): Promise<LocalDocumentFile | undefined> {
    return db.documentFiles.get(id);
  },

  async deleteFileByDocumentId(documentId: string): Promise<number> {
    return db.documentFiles.where('documentId').equals(documentId).delete();
  },

  async deleteFile(id: string): Promise<void> {
    await db.documentFiles.delete(id);
  },
};
