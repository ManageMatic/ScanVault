import type { QuadCorners, Point } from './scannerTypes';

/**
 * Returns clean default inset corners (8% margin)
 */
export function getDefaultCorners(): QuadCorners {
  return {
    tl: { x: 0.08, y: 0.08 },
    tr: { x: 0.92, y: 0.08 },
    br: { x: 0.92, y: 0.92 },
    bl: { x: 0.08, y: 0.92 },
  };
}

export const getDefaultInsetCorners = getDefaultCorners;

/**
 * Validates whether a quadrilateral is geometrically valid and convex
 */
export function validateQuadrilateral(corners: QuadCorners): boolean {
  const { tl, tr, br, bl } = corners;

  // 1. Check points are within unit range
  const pts = [tl, tr, br, bl];
  for (const p of pts) {
    if (p.x < 0 || p.x > 1 || p.y < 0 || p.y > 1) return false;
  }

  // 2. Check minimum distance between corners
  const dist = (p1: Point, p2: Point) =>
    Math.sqrt(Math.pow(p1.x - p2.x, 2) + Math.pow(p1.y - p2.y, 2));

  if (
    dist(tl, tr) < 0.1 ||
    dist(tr, br) < 0.1 ||
    dist(br, bl) < 0.1 ||
    dist(bl, tl) < 0.1
  ) {
    return false;
  }

  // 3. Check cross products for convexity
  const cross = (o: Point, a: Point, b: Point) =>
    (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x);

  const c1 = cross(tl, tr, br);
  const c2 = cross(tr, br, bl);
  const c3 = cross(br, bl, tl);
  const c4 = cross(bl, tl, tr);

  const allPositive = c1 > 0 && c2 > 0 && c3 > 0 && c4 > 0;
  const allNegative = c1 < 0 && c2 < 0 && c3 < 0 && c4 < 0;

  return allPositive || allNegative;
}

/**
 * Real-time client-side document boundary detection
 * Operates on downscaled canvas frame (400x300) for high performance on mobile devices.
 */
export class DocumentDetector {
  private workingCanvas: HTMLCanvasElement | null = null;
  private workingWidth = 400;
  private workingHeight = 300;

  private getCanvas(): { canvas: HTMLCanvasElement; ctx: CanvasRenderingContext2D } {
    if (!this.workingCanvas) {
      this.workingCanvas = document.createElement('canvas');
      this.workingCanvas.width = this.workingWidth;
      this.workingCanvas.height = this.workingHeight;
    }
    const ctx = this.workingCanvas.getContext('2d', { willReadFrequently: true });
    if (!ctx) throw new Error('Cannot get 2d context for edge detection');
    return { canvas: this.workingCanvas, ctx };
  }

  /**
   * Runs detection on an active HTMLVideoElement frame
   */
  detectVideoFrame(video: HTMLVideoElement): QuadCorners | null {
    if (video.readyState < 2 || video.videoWidth === 0 || video.videoHeight === 0) {
      return null;
    }

    const { ctx } = this.getCanvas();
    ctx.drawImage(video, 0, 0, this.workingWidth, this.workingHeight);

    const corners = this.analyzeFrame(ctx);
    if (corners && validateQuadrilateral(corners)) {
      return corners;
    }
    return null;
  }

  /**
   * Runs detection on a loaded HTMLImageElement
   */
  detectImageElement(img: HTMLImageElement): QuadCorners {
    const { ctx } = this.getCanvas();
    ctx.drawImage(img, 0, 0, this.workingWidth, this.workingHeight);

    const corners = this.analyzeFrame(ctx);
    if (corners && validateQuadrilateral(corners)) {
      return corners;
    }
    return getDefaultCorners();
  }

  /**
   * Analyzes pixel luminance gradients using Sobel edge response
   */
  private analyzeFrame(ctx: CanvasRenderingContext2D): QuadCorners | null {
    const w = this.workingWidth;
    const h = this.workingHeight;
    const imgData = ctx.getImageData(0, 0, w, h);
    const data = imgData.data;

    // 1. Grayscale luminance
    const gray = new Uint8Array(w * h);
    for (let i = 0, j = 0; i < data.length; i += 4, j++) {
      const r = data[i] ?? 0;
      const g = data[i + 1] ?? 0;
      const b = data[i + 2] ?? 0;
      gray[j] = Math.round(0.299 * r + 0.587 * g + 0.114 * b);
    }

    // 2. Sobel edge gradient magnitude
    const magnitude = new Uint8Array(w * h);
    const threshold = 40;
    const edgePoints: Point[] = [];

    // Skip 4px borders
    for (let y = 4; y < h - 4; y += 2) {
      for (let x = 4; x < w - 4; x += 2) {
        const p00 = gray[(y - 1) * w + (x - 1)] ?? 0;
        const p01 = gray[(y - 1) * w + x] ?? 0;
        const p02 = gray[(y - 1) * w + (x + 1)] ?? 0;
        const p10 = gray[y * w + (x - 1)] ?? 0;
        const p12 = gray[y * w + (x + 1)] ?? 0;
        const p20 = gray[(y + 1) * w + (x - 1)] ?? 0;
        const p21 = gray[(y + 1) * w + x] ?? 0;
        const p22 = gray[(y + 1) * w + (x + 1)] ?? 0;

        // Sobel X
        const gx = -1 * p00 + 1 * p02 - 2 * p10 + 2 * p12 - 1 * p20 + 1 * p22;

        // Sobel Y
        const gy = -1 * p00 - 2 * p01 - 1 * p02 + 1 * p20 + 2 * p21 + 1 * p22;

        const mag = Math.min(255, Math.abs(gx) + Math.abs(gy));
        magnitude[y * w + x] = mag;

        if (mag > threshold) {
          edgePoints.push({ x: x / w, y: y / h });
        }
      }
    }

    if (edgePoints.length < 30) {
      return null;
    }

    // 3. Cluster extreme points to determine 4 corners (TL, TR, BR, BL)
    let minTL = Infinity;
    let maxTR = -Infinity;
    let maxBR = -Infinity;
    let minBL = Infinity;

    let tl = { x: 0.1, y: 0.1 };
    let tr = { x: 0.9, y: 0.1 };
    let br = { x: 0.9, y: 0.9 };
    let bl = { x: 0.1, y: 0.9 };

    for (const p of edgePoints) {
      const sum = p.x + p.y;
      const diff = p.x - p.y;

      if (sum < minTL) {
        minTL = sum;
        tl = p;
      }
      if (diff > maxTR) {
        maxTR = diff;
        tr = p;
      }
      if (sum > maxBR) {
        maxBR = sum;
        br = p;
      }
      if (diff < minBL) {
        minBL = diff;
        bl = p;
      }
    }

    // Smooth and clamp corners slightly inside image
    const clamp = (v: number) => Math.max(0.02, Math.min(0.98, v));

    return {
      tl: { x: clamp(tl.x), y: clamp(tl.y) },
      tr: { x: clamp(tr.x), y: clamp(tr.y) },
      br: { x: clamp(br.x), y: clamp(br.y) },
      bl: { x: clamp(bl.x), y: clamp(bl.y) },
    };
  }
}

export const documentDetector = new DocumentDetector();

export function detectDocumentEdgesOnVideo(video: HTMLVideoElement): QuadCorners | null {
  return documentDetector.detectVideoFrame(video);
}

export async function detectDocumentEdgesOnImage(blob: Blob): Promise<QuadCorners> {
  return new Promise((resolve) => {
    const url = URL.createObjectURL(blob);
    const img = new Image();
    img.onload = () => {
      URL.revokeObjectURL(url);
      const corners = documentDetector.detectImageElement(img);
      resolve(corners);
    };
    img.onerror = () => {
      URL.revokeObjectURL(url);
      resolve(getDefaultCorners());
    };
    img.src = url;
  });
}
