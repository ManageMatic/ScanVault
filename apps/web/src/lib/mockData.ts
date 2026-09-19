import type { MockDocument, MockFolder, PdfToolItem } from '@/types/ui';

export const INITIAL_MOCK_DOCUMENTS: MockDocument[] = [
  {
    id: 'doc-1',
    title: 'Project Proposal 2026.pdf',
    folderId: 'folder-1',
    mimeType: 'application/pdf',
    sizeBytes: 2450000,
    pageCount: 14,
    favorite: true,
    createdAt: new Date(Date.now() - 1000 * 60 * 60 * 2).toISOString(),
    updatedAt: new Date(Date.now() - 1000 * 60 * 60 * 2).toISOString(),
    tags: ['Work', 'Q3', 'Client'],
    thumbnailColor: '#008378',
    category: 'contract',
  },
  {
    id: 'doc-2',
    title: 'University Lecture Notes — Architecture.pdf',
    folderId: 'folder-2',
    mimeType: 'application/pdf',
    sizeBytes: 8120000,
    pageCount: 38,
    favorite: true,
    createdAt: new Date(Date.now() - 1000 * 60 * 60 * 24).toISOString(),
    updatedAt: new Date(Date.now() - 1000 * 60 * 60 * 24).toISOString(),
    tags: ['Study', 'Design'],
    thumbnailColor: '#2563eb',
    category: 'notes',
  },
  {
    id: 'doc-3',
    title: 'Internship Performance Report.pdf',
    folderId: 'folder-1',
    mimeType: 'application/pdf',
    sizeBytes: 1350000,
    pageCount: 5,
    favorite: false,
    createdAt: new Date(Date.now() - 1000 * 60 * 60 * 48).toISOString(),
    updatedAt: new Date(Date.now() - 1000 * 60 * 60 * 48).toISOString(),
    tags: ['Career', 'Evaluation'],
    thumbnailColor: '#7c3aed',
    category: 'contract',
  },
  {
    id: 'doc-4',
    title: 'Tax Invoice — Cloud Services Sept 2026.pdf',
    folderId: 'folder-3',
    mimeType: 'application/pdf',
    sizeBytes: 680000,
    pageCount: 2,
    favorite: false,
    createdAt: new Date(Date.now() - 1000 * 60 * 60 * 72).toISOString(),
    updatedAt: new Date(Date.now() - 1000 * 60 * 60 * 72).toISOString(),
    tags: ['Finance', 'Receipts'],
    thumbnailColor: '#059669',
    category: 'invoice',
  },
  {
    id: 'doc-5',
    title: 'Medical Health Insurance Policy.pdf',
    folderId: null,
    mimeType: 'application/pdf',
    sizeBytes: 4200000,
    pageCount: 19,
    favorite: true,
    createdAt: new Date(Date.now() - 1000 * 60 * 60 * 96).toISOString(),
    updatedAt: new Date(Date.now() - 1000 * 60 * 60 * 96).toISOString(),
    tags: ['Personal', 'Health'],
    thumbnailColor: '#e11d48',
    category: 'medical',
  },
];

export const INITIAL_MOCK_FOLDERS: MockFolder[] = [
  {
    id: 'folder-1',
    name: 'Work & Projects',
    documentCount: 2,
    color: '#008378',
    createdAt: new Date(Date.now() - 1000 * 60 * 60 * 200).toISOString(),
  },
  {
    id: 'folder-2',
    name: 'Study & Academics',
    documentCount: 1,
    color: '#2563eb',
    createdAt: new Date(Date.now() - 1000 * 60 * 60 * 180).toISOString(),
  },
  {
    id: 'folder-3',
    name: 'Invoices & Receipts',
    documentCount: 1,
    color: '#059669',
    createdAt: new Date(Date.now() - 1000 * 60 * 60 * 150).toISOString(),
  },
];

export const PDF_TOOLS: PdfToolItem[] = [
  {
    id: 'merge-pdf',
    title: 'Merge PDF',
    description: 'Combine multiple PDF files into one clean document',
    icon: 'Files',
    category: 'organize',
    badge: 'Popular',
  },
  {
    id: 'split-pdf',
    title: 'Split PDF',
    description: 'Separate pages or extract specific page ranges',
    icon: 'Scissors',
    category: 'organize',
  },
  {
    id: 'compress-pdf',
    title: 'Compress PDF',
    description: 'Reduce file size while preserving high visual quality',
    icon: 'Minimize2',
    category: 'optimize',
    badge: 'Fast',
  },
  {
    id: 'rotate-pages',
    title: 'Rotate Pages',
    description: 'Rotate specific or all document pages by 90/180/270°',
    icon: 'RotateCw',
    category: 'organize',
  },
  {
    id: 'extract-pages',
    title: 'Extract Pages',
    description: 'Save selected pages as a brand new standalone document',
    icon: 'FileSpreadsheet',
    category: 'organize',
  },
  {
    id: 'images-to-pdf',
    title: 'Images to PDF',
    description: 'Convert JPG, PNG, and camera photos into a multi-page PDF',
    icon: 'Image',
    category: 'convert',
  },
  {
    id: 'pdf-to-images',
    title: 'PDF to Images',
    description: 'Export PDF pages as crystal clear high-resolution images',
    icon: 'FileImage',
    category: 'convert',
  },
  {
    id: 'watermark-pdf',
    title: 'Watermark',
    description: 'Stamp custom text or confidential logos onto pages',
    icon: 'Stamp',
    category: 'security',
  },
];

export function formatBytes(bytes: number, decimals = 1): string {
  if (bytes === 0) return '0 B';
  const k = 1024;
  const dm = decimals < 0 ? 0 : decimals;
  const sizes = ['B', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return `${parseFloat((bytes / Math.pow(k, i)).toFixed(dm))} ${sizes[i]}`;
}
