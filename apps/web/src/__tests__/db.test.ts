import { describe, it, expect } from 'vitest';
import { db, ScanVaultLocalDB } from '../lib/db';

describe('ScanVault IndexedDB Abstraction', () => {
  it('instantiates Dexie database with expected table stores', () => {
    expect(db).toBeInstanceOf(ScanVaultLocalDB);
    expect(db.name).toBe('ScanVaultLocalDB');
    expect(db.tables.map((t) => t.name)).toEqual(
      expect.arrayContaining([
        'documents',
        'pages',
        'folders',
        'ocrResults',
        'annotations',
        'signatures',
      ])
    );
  });
});
