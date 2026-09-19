import { useLiveQuery } from 'dexie-react-hooks';
import { useAuth } from '@/lib/auth';
import {
  folderRepository,
  type FolderWithCount,
} from '../repositories/folderRepository';
import type { LocalFolder } from '../schema';

export function useFolders() {
  const { user } = useAuth();
  const userId = user?.id || '';

  const folders = useLiveQuery(
    async () => {
      if (!userId) return [];
      return folderRepository.getFoldersByUser(userId);
    },
    [userId]
  );

  const safeFolders: FolderWithCount[] = folders ?? [];

  return {
    folders: safeFolders,
    isLoading: folders === undefined,
    createFolder: async (name: string, color?: string, parentId?: string | null) => {
      if (!userId) throw new Error('Authentication required');
      const now = new Date();
      const folder: LocalFolder = {
        id: crypto.randomUUID ? crypto.randomUUID() : `folder-${Date.now()}-${Math.random().toString(36).substring(2, 9)}`,
        userId,
        name: name.trim(),
        parentId: parentId || null,
        color: color || '#4F46E5',
        createdAt: now,
        updatedAt: now,
      };
      return folderRepository.createFolder(folder);
    },
    renameFolder: (id: string, name: string) =>
      folderRepository.renameFolder(id, userId, name),
    deleteFolder: (id: string) =>
      folderRepository.deleteFolder(id, userId),
  };
}

export type { FolderWithCount };
