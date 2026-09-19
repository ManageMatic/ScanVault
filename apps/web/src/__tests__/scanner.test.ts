import 'fake-indexeddb/auto';
import { describe, it, expect, beforeEach } from 'vitest';
import {
  getDefaultCorners,
  getDefaultInsetCorners,
  validateQuadrilateral,
} from '../lib/scanner/detectionService';
import {
  denormalizeCorners,
  validateImageBlob,
} from '../lib/scanner/perspectiveService';
import { db, documentRepository } from '../lib/db';
import type { QuadCorners } from '../lib/scanner/scannerTypes';

describe('ScanVault Mobile Document Scanner (Module 05)', () => {
  beforeEach(async () => {
    await db.documents.clear();
    await db.documentFiles.clear();
    await db.documentPages.clear();
    await db.thumbnails.clear();
  });

  describe('1. Quadrilateral Geometry & Edge Detection Validation', () => {
    it('generates standard 8% inset default corners', () => {
      const corners = getDefaultCorners();
      expect(corners.tl).toEqual({ x: 0.08, y: 0.08 });
      expect(corners.tr).toEqual({ x: 0.92, y: 0.08 });
      expect(corners.br).toEqual({ x: 0.92, y: 0.92 });
      expect(corners.bl).toEqual({ x: 0.08, y: 0.92 });
      expect(getDefaultInsetCorners()).toEqual(corners);
    });

    it('validates standard convex quadrilaterals correctly', () => {
      const standardCorners = getDefaultCorners();
      expect(validateQuadrilateral(standardCorners)).toBe(true);

      const trapezoid: QuadCorners = {
        tl: { x: 0.2, y: 0.1 },
        tr: { x: 0.8, y: 0.1 },
        br: { x: 0.9, y: 0.9 },
        bl: { x: 0.1, y: 0.9 },
      };
      expect(validateQuadrilateral(trapezoid)).toBe(true);
    });

    it('rejects out of bounds coordinates', () => {
      const outOfBounds: QuadCorners = {
        tl: { x: -0.1, y: 0.1 },
        tr: { x: 0.9, y: 0.1 },
        br: { x: 0.9, y: 0.9 },
        bl: { x: 0.1, y: 0.9 },
      };
      expect(validateQuadrilateral(outOfBounds)).toBe(false);
    });

    it('rejects self-intersecting or collapsed quadrilaterals (hourglass)', () => {
      const hourglass: QuadCorners = {
        tl: { x: 0.1, y: 0.1 },
        tr: { x: 0.9, y: 0.9 }, // crossed
        br: { x: 0.9, y: 0.1 },
        bl: { x: 0.1, y: 0.9 },
      };
      expect(validateQuadrilateral(hourglass)).toBe(false);

      const collapsed: QuadCorners = {
        tl: { x: 0.1, y: 0.1 },
        tr: { x: 0.11, y: 0.1 }, // too close to tl
        br: { x: 0.9, y: 0.9 },
        bl: { x: 0.1, y: 0.9 },
      };
      expect(validateQuadrilateral(collapsed)).toBe(false);
    });
  });

  describe('2. Coordinate Mapping & Transformation Math', () => {
    it('denormalizes 0..1 normalized coordinates to image pixel coordinates accurately', () => {
      const normCorners: QuadCorners = {
        tl: { x: 0.1, y: 0.2 },
        tr: { x: 0.9, y: 0.2 },
        br: { x: 0.85, y: 0.8 },
        bl: { x: 0.15, y: 0.8 },
      };

      const pixelCorners = denormalizeCorners(normCorners, 1000, 2000);
      expect(pixelCorners.tl).toEqual({ x: 100, y: 400 });
      expect(pixelCorners.tr).toEqual({ x: 900, y: 400 });
      expect(pixelCorners.br).toEqual({ x: 850, y: 1600 });
      expect(pixelCorners.bl).toEqual({ x: 150, y: 1600 });
    });

    it('clamps denormalized coordinates within image boundaries', () => {
      const overBounds: QuadCorners = {
        tl: { x: -0.5, y: 0.0 },
        tr: { x: 1.5, y: 0.0 },
        br: { x: 1.0, y: 1.5 },
        bl: { x: 0.0, y: 1.0 },
      };

      const clamped = denormalizeCorners(overBounds, 500, 500);
      expect(clamped.tl.x).toBe(0);
      expect(clamped.tr.x).toBe(500);
      expect(clamped.br.y).toBe(500);
    });
  });

  describe('3. Blob Validation & Zero-Blank Screen Protection', () => {
    it('rejects empty or zero-byte blobs', async () => {
      const emptyBlob = new Blob([], { type: 'image/jpeg' });
      const result = await validateImageBlob(emptyBlob);
      expect(result.valid).toBe(false);
      expect(result.width).toBe(0);
      expect(result.height).toBe(0);
    });
  });

  describe('4. Scanner Session Multi-Page Persistence to IndexedDB Vault', () => {
    it('saves a multi-page scan session atomically to Dexie IndexedDB vault', async () => {
      const userId = 'user-scanner-123';
      const docId = 'doc-scan-test-01';
      const fileId = 'file-scan-test-01';
      const thumbId = 'thumb-scan-test-01';

      const page1Blob = new Blob(['fake-jpg-page-1-binary-data'], { type: 'image/jpeg' });
      const page2Blob = new Blob(['fake-jpg-page-2-binary-data'], { type: 'image/jpeg' });
      const thumbBlob = new Blob(['fake-thumb-data'], { type: 'image/jpeg' });

      const totalSize = page1Blob.size + page2Blob.size;

      // 1. Create document record
      const docRecord = {
        id: docId,
        userId,
        title: 'Contract Scan May 2026',
        mimeType: 'image/jpeg',
        size: totalSize,
        pageCount: 2,
        folderId: null,
        favorite: true,
        status: 'ready' as const,
        createdAt: new Date(),
        updatedAt: new Date(),
        lastOpenedAt: new Date(),
        deletedAt: null,
        thumbnailId: thumbId,
        source: 'scanned' as const,
        version: 1,
        tags: ['Scanned'],
        thumbnailColor: '#3B82F6',
      };

      // 2. Create primary document file
      const fileRecord = {
        id: fileId,
        documentId: docId,
        blob: page1Blob,
        mimeType: 'image/jpeg',
        size: totalSize,
        createdAt: new Date(),
        updatedAt: new Date(),
      };

      // 3. Create document pages
      const pageRecords = [
        {
          id: `page_${docId}_1`,
          documentId: docId,
          pageNumber: 1,
          width: 1200,
          height: 1600,
          imageBlobId: fileId,
          thumbnailId: thumbId,
          createdAt: new Date(),
          updatedAt: new Date(),
        },
        {
          id: `page_${docId}_2`,
          documentId: docId,
          pageNumber: 2,
          width: 1200,
          height: 1600,
          imageBlobId: fileId,
          thumbnailId: thumbId,
          createdAt: new Date(),
          updatedAt: new Date(),
        },
      ];

      // 4. Create thumbnail record
      const thumbRecord = {
        id: thumbId,
        documentId: docId,
        blob: thumbBlob,
        mimeType: 'image/jpeg',
        width: 320,
        height: 426,
        createdAt: new Date(),
      };

      // Save via repository
      const savedDocId = await documentRepository.createDocument(
        docRecord,
        fileRecord,
        pageRecords,
        thumbRecord
      );

      expect(savedDocId).toBe(docId);

      // Verify records in Dexie
      const retrievedDoc = await db.documents.get(docId);
      expect(retrievedDoc).toBeDefined();
      expect(retrievedDoc?.title).toBe('Contract Scan May 2026');
      expect(retrievedDoc?.source).toBe('scanned');
      expect(retrievedDoc?.pageCount).toBe(2);

      const retrievedPages = await db.documentPages.where('documentId').equals(docId).toArray();
      expect(retrievedPages).toHaveLength(2);
      expect(retrievedPages[0]?.pageNumber).toBe(1);
      expect(retrievedPages[1]?.pageNumber).toBe(2);

      const retrievedThumb = await db.thumbnails.get(thumbId);
      expect(retrievedThumb).toBeDefined();
      expect(retrievedThumb?.documentId).toBe(docId);
    });
  });
});
