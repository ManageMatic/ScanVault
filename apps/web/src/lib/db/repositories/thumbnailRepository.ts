import { db } from '../database';
import type { LocalThumbnail } from '../schema';

export const thumbnailRepository = {
  async saveThumbnail(thumbnail: LocalThumbnail): Promise<string> {
    await db.thumbnails.put(thumbnail);
    return thumbnail.id;
  },

  async getThumbnailById(id: string): Promise<LocalThumbnail | undefined> {
    return db.thumbnails.get(id);
  },

  async getThumbnailByDocumentId(documentId: string): Promise<LocalThumbnail | undefined> {
    return db.thumbnails.where('documentId').equals(documentId).first();
  },

  async deleteThumbnailByDocumentId(documentId: string): Promise<number> {
    return db.thumbnails.where('documentId').equals(documentId).delete();
  },

  async deleteThumbnail(id: string): Promise<void> {
    await db.thumbnails.delete(id);
  },
};
