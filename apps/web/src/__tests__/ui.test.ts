import { describe, it, expect } from 'vitest';
import { INITIAL_MOCK_DOCUMENTS, INITIAL_MOCK_FOLDERS, PDF_TOOLS, formatBytes } from '../lib/mockData';

describe('Module 02 UI & Mock Data Layer', () => {
  it('loads mock documents with valid properties', () => {
    expect(INITIAL_MOCK_DOCUMENTS.length).toBeGreaterThan(0);
    for (const doc of INITIAL_MOCK_DOCUMENTS) {
      expect(doc.id).toBeDefined();
      expect(doc.title).toContain('.pdf');
      expect(doc.pageCount).toBeGreaterThan(0);
      expect(doc.sizeBytes).toBeGreaterThan(0);
    }
  });

  it('loads mock folders and tool definitions', () => {
    expect(INITIAL_MOCK_FOLDERS.length).toBeGreaterThan(0);
    expect(PDF_TOOLS.length).toBeGreaterThanOrEqual(8);
  });

  it('formats byte sizes accurately', () => {
    expect(formatBytes(0)).toBe('0 B');
    expect(formatBytes(1024)).toBe('1 KB');
    expect(formatBytes(1048576)).toBe('1 MB');
    expect(formatBytes(2450000)).toBe('2.3 MB');
  });
});
