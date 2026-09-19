/**
 * Authenticated User DTO
 */
export interface AuthUser {
  id: string;
  email: string;
  name: string | null;
  avatarUrl: string | null;
  emailVerified: string | null;
  accounts?: Array<{ provider: string; providerAccountId?: string }>;
  providers?: string[];
  createdAt?: string;
}

/**
 * User Summary DTO
 */
export interface UserSummary {
  id: string;
  email: string;
  name: string | null;
  avatarUrl: string | null;
  createdAt: string;
}

/**
 * Folder Summary DTO
 */
export interface FolderSummary {
  id: string;
  userId: string;
  name: string;
  parentId: string | null;
  createdAt: string;
  updatedAt: string;
}

/**
 * Document Summary DTO
 */
export interface DocumentSummary {
  id: string;
  userId: string;
  folderId: string | null;
  title: string;
  mimeType: string;
  size: number;
  pageCount: number;
  favorite: boolean;
  createdAt: string;
  updatedAt: string;
  deletedAt: string | null;
}

/**
 * Document Page DTO
 */
export interface DocumentPageSummary {
  id: string;
  documentId: string;
  pageNumber: number;
  width: number;
  height: number;
  createdAt: string;
}
