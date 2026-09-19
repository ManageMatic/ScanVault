import { useLiveQuery } from 'dexie-react-hooks';
import { useAuth } from '@/lib/auth';
import {
  documentRepository,
  type DocumentQueryOptions,
  type DocumentSortOption,
} from '../repositories/documentRepository';
import type { LocalDocument } from '../schema';

export function useDocuments(options: DocumentQueryOptions = {}) {
  const { user } = useAuth();
  const userId = user?.id || '';

  const {
    tab = 'all',
    folderId,
    search = '',
    sortBy = 'modified-desc',
    mimeFilter = 'all',
  } = options;

  const documents = useLiveQuery(
    async () => {
      if (!userId) return [];
      return documentRepository.getDocumentsByUser(userId, {
        tab,
        folderId,
        search,
        sortBy,
        mimeFilter,
      });
    },
    [userId, tab, folderId, search, sortBy, mimeFilter]
  );

  // Total counts for badge indicators
  const allCount = useLiveQuery(
    async () => {
      if (!userId) return 0;
      const docs = await documentRepository.getDocumentsByUser(userId, { tab: 'all' });
      return docs.length;
    },
    [userId]
  );

  const favoritesCount = useLiveQuery(
    async () => {
      if (!userId) return 0;
      const docs = await documentRepository.getDocumentsByUser(userId, { tab: 'favorites' });
      return docs.length;
    },
    [userId]
  );

  const trashCount = useLiveQuery(
    async () => {
      if (!userId) return 0;
      const docs = await documentRepository.getDocumentsByUser(userId, { tab: 'trash' });
      return docs.length;
    },
    [userId]
  );

  const safeDocs: LocalDocument[] = documents ?? [];

  return {
    documents: safeDocs,
    allCount: allCount ?? 0,
    favoritesCount: favoritesCount ?? 0,
    trashCount: trashCount ?? 0,
    isLoading: documents === undefined,
    // Actions
    renameDocument: (id: string, newTitle: string) =>
      documentRepository.renameDocument(id, userId, newTitle),
    toggleFavorite: (id: string) => documentRepository.toggleFavorite(id, userId),
    moveToFolder: (id: string, targetFolderId: string | null) =>
      documentRepository.moveToFolder(id, userId, targetFolderId),
    softDeleteDocument: (id: string) => documentRepository.softDeleteDocument(id, userId),
    restoreDocument: (id: string) => documentRepository.restoreDocument(id, userId),
    permanentlyDeleteDocument: (id: string) =>
      documentRepository.permanentlyDeleteDocument(id, userId),
    duplicateDocument: (id: string) => documentRepository.duplicateDocument(id, userId),
    recordDocumentOpen: (id: string) => documentRepository.recordDocumentOpen(id, userId),
  };
}

export type { DocumentSortOption, DocumentQueryOptions };
