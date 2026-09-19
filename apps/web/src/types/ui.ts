export type ThemeMode = 'light' | 'dark' | 'system';

export type ViewMode = 'list' | 'grid';

export type DocumentTab = 'all' | 'folders' | 'favorites' | 'recent' | 'trash';

export interface MockDocument {
  id: string;
  title: string;
  folderId?: string | null;
  mimeType: string;
  sizeBytes: number;
  pageCount: number;
  favorite: boolean;
  createdAt: string;
  updatedAt: string;
  tags?: string[];
  thumbnailColor?: string;
  category?: 'invoice' | 'contract' | 'notes' | 'medical' | 'receipt' | 'id';
}

export interface MockFolder {
  id: string;
  name: string;
  documentCount: number;
  color?: string;
  createdAt: string;
}

export interface PdfToolItem {
  id: string;
  title: string;
  description: string;
  icon: string;
  category: 'organize' | 'optimize' | 'convert' | 'security';
  badge?: string;
}
