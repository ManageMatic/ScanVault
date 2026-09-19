import { useEffect, useState } from 'react';
import { useAuth } from '@/lib/auth';
import { documentRepository } from '../repositories/documentRepository';
import { fileRepository } from '../repositories/fileRepository';
import { thumbnailRepository } from '../repositories/thumbnailRepository';
import type { LocalDocument, LocalDocumentFile, LocalThumbnail } from '../schema';

export function useDocument(documentId: string | undefined) {
  const { user } = useAuth();
  const userId = user?.id || '';

  const [document, setDocument] = useState<LocalDocument | null>(null);
  const [file, setFile] = useState<LocalDocumentFile | null>(null);
  const [thumbnail, setThumbnail] = useState<LocalThumbnail | null>(null);
  const [fileUrl, setFileUrl] = useState<string | null>(null);
  const [thumbnailUrl, setThumbnailUrl] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchDocument = async () => {
    if (!documentId || !userId) {
      setDocument(null);
      setFile(null);
      setIsLoading(false);
      return;
    }

    try {
      setIsLoading(true);
      setError(null);

      const doc = await documentRepository.getDocumentById(documentId, userId);
      if (!doc) {
        setDocument(null);
        setError('Document not found');
        return;
      }
      setDocument(doc);

      // Record document open time
      await documentRepository.recordDocumentOpen(documentId, userId);

      // Load file blob
      const fileData = await fileRepository.getFileByDocumentId(documentId);
      if (fileData) {
        setFile(fileData);
        const url = URL.createObjectURL(fileData.blob);
        setFileUrl(url);
      }

      // Load thumbnail blob if exists
      if (doc.thumbnailId) {
        const thumb = await thumbnailRepository.getThumbnailById(doc.thumbnailId);
        if (thumb) {
          setThumbnail(thumb);
          const tUrl = URL.createObjectURL(thumb.blob);
          setThumbnailUrl(tUrl);
        }
      }
    } catch (err) {
      setError((err as Error).message || 'Failed to load document');
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchDocument();

    return () => {
      // Clean up object URLs on unmount or id change
      if (fileUrl) {
        URL.revokeObjectURL(fileUrl);
      }
      if (thumbnailUrl) {
        URL.revokeObjectURL(thumbnailUrl);
      }
    };
  }, [documentId, userId]);

  return {
    document,
    file,
    thumbnail,
    fileUrl,
    thumbnailUrl,
    isLoading,
    error,
    refetch: fetchDocument,
  };
}
