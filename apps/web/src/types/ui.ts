import type { LocalDocument, LocalFolder } from '@/lib/db';

export type ThemeMode = 'light' | 'dark' | 'system';

export type ViewMode = 'list' | 'grid';

export type DocumentTab = 'all' | 'folders' | 'favorites' | 'recent' | 'trash';

export type { LocalDocument, LocalFolder };

// Alias for backward compatibility if needed
export type MockDocument = LocalDocument;
export type MockFolder = LocalFolder & { documentCount?: number };

export interface PdfToolItem {
  id: string;
  title: string;
  description: string;
  icon: string;
  category: 'organize' | 'optimize' | 'convert' | 'security';
  badge?: string;
}
