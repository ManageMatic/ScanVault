import type { Point, QuadCorners } from './scannerTypes';

/**
 * Validates that an image blob is non-empty and decodes properly with positive dimensions.
 * Zero-blank screen guarantee: prevents corrupted or zero-byte frames from progressing.
 */
export async function validateImageBlob(blob: Blob): Promise<{ valid: boolean; width: number; height: number }> {
  if (!blob || blob.size === 0) {
    return { valid: false, width: 0, height: 0 };
  }

  try {
    if (typeof createImageBitmap === 'function') {
      const bitmap = await createImageBitmap(blob);
      const width = bitmap.width;
      const height = bitmap.height;
      bitmap.close();
      if (width > 0 && height > 0) {
        return { valid: true, width, height };
      }
    }
  } catch {
    // Fallback to Image element
  }

  return new Promise((resolve) => {
    const url = URL.createObjectURL(blob);
    const img = new Image();

    img.onload = () => {
      const width = img.naturalWidth;
      const height = img.naturalHeight;
      URL.revokeObjectURL(url);
      resolve({ valid: width > 0 && height > 0, width, height });
    };

    img.onerror = () => {
      URL.revokeObjectURL(url);
      resolve({ valid: false, width: 0, height: 0 });
    };

    img.src = url;
  });
}

/**
 * Loads a Blob into an HTMLImageElement safely.
 */
export function loadImageFromBlob(blob: Blob): Promise<HTMLImageElement> {
  return new Promise((resolve, reject) => {
    const url = URL.createObjectURL(blob);
    const img = new Image();
    img.onload = () => {
      URL.revokeObjectURL(url);
      resolve(img);
    };
    img.onerror = (err) => {
      URL.revokeObjectURL(url);
      reject(new Error(`Failed to decode image from blob: ${err}`));
    };
    img.src = url;
  });
}

/**
 * Converts normalized (0..1) corners to absolute image pixel coordinates.
 */
export function denormalizeCorners(corners: QuadCorners, imgWidth: number, imgHeight: number): QuadCorners {
  return {
    tl: { x: Math.max(0, Math.min(imgWidth, corners.tl.x * imgWidth)), y: Math.max(0, Math.min(imgHeight, corners.tl.y * imgHeight)) },
    tr: { x: Math.max(0, Math.min(imgWidth, corners.tr.x * imgWidth)), y: Math.max(0, Math.min(imgHeight, corners.tr.y * imgHeight)) },
    br: { x: Math.max(0, Math.min(imgWidth, corners.br.x * imgWidth)), y: Math.max(0, Math.min(imgHeight, corners.br.y * imgHeight)) },
    bl: { x: Math.max(0, Math.min(imgWidth, corners.bl.x * imgWidth)), y: Math.max(0, Math.min(imgHeight, corners.bl.y * imgHeight)) },
  };
}

/**
 * Distance between two points.
 */
function dist(p1: Point, p2: Point): number {
  return Math.sqrt((p1.x - p2.x) ** 2 + (p1.y - p2.y) ** 2);
}

/**
 * Solves 8-parameter homography matrix H mapping unit square / target rect to source quad.
 * H maps (x, y) in destination -> (u, v) in source.
 */
function computeProjectiveMatrix(
  srcCorners: QuadCorners,
  dstW: number,
  dstH: number
): [number, number, number, number, number, number, number, number, number] | null {
  const ptsDst: Point[] = [
    { x: 0, y: 0 },
    { x: dstW, y: 0 },
    { x: dstW, y: dstH },
    { x: 0, y: dstH },
  ];

  const ptsSrc: Point[] = [
    srcCorners.tl,
    srcCorners.tr,
    srcCorners.br,
    srcCorners.bl,
  ];

  const A: number[][] = [];
  const B: number[] = [];

  for (let i = 0; i < 4; i++) {
    const dstPt = ptsDst[i]!;
    const srcPt = ptsSrc[i]!;
    const x = dstPt.x;
    const y = dstPt.y;
    const u = srcPt.x;
    const v = srcPt.y;

    A.push([x, y, 1, 0, 0, 0, -x * u, -y * u]);
    B.push(u);

    A.push([0, 0, 0, x, y, 1, -x * v, -y * v]);
    B.push(v);
  }

  // Gaussian elimination with partial pivoting
  const n = 8;
  for (let i = 0; i < n; i++) {
    let maxRow = i;
    for (let k = i + 1; k < n; k++) {
      const rowK = A[k]!;
      const rowMax = A[maxRow]!;
      if (Math.abs(rowK[i]!) > Math.abs(rowMax[i]!)) {
        maxRow = k;
      }
    }

    const tmpRow = A[i]!;
    A[i] = A[maxRow]!;
    A[maxRow] = tmpRow;

    const tmpB = B[i]!;
    B[i] = B[maxRow]!;
    B[maxRow] = tmpB;

    const currentPivot = A[i]![i]!;
    if (Math.abs(currentPivot) < 1e-10) {
      return null; // Singular matrix
    }

    for (let k = i + 1; k < n; k++) {
      const rowK = A[k]!;
      const rowI = A[i]!;
      const c = rowK[i]! / currentPivot;
      for (let j = i; j < n; j++) {
        rowK[j] = rowK[j]! - c * rowI[j]!;
      }
      B[k] = B[k]! - c * B[i]!;
    }
  }

  // Back substitution
  const h: number[] = new Array(8).fill(0);
  for (let i = n - 1; i >= 0; i--) {
    let sum = B[i]!;
    const rowI = A[i]!;
    for (let j = i + 1; j < n; j++) {
      sum -= rowI[j]! * (h[j] || 0);
    }
    h[i] = sum / rowI[i]!;
  }

  return [
    h[0] ?? 0,
    h[1] ?? 0,
    h[2] ?? 0,
    h[3] ?? 0,
    h[4] ?? 0,
    h[5] ?? 0,
    h[6] ?? 0,
    h[7] ?? 0,
    1,
  ];
}

/**
 * Transforms a quadrilateral region of an image into a flat, upright rectangular document.
 * Includes bilinear interpolation for sharp text preservation and output validation.
 */
export async function transformPerspective(
  imageBlob: Blob,
  normalizedCorners: QuadCorners,
  quality = 0.92
): Promise<{ blob: Blob; width: number; height: number }> {
  const img = await loadImageFromBlob(imageBlob);
  const srcW = img.naturalWidth || img.width;
  const srcH = img.naturalHeight || img.height;

  // Denormalize corners to source pixel dimensions
  const corners = denormalizeCorners(normalizedCorners, srcW, srcH);

  // Calculate destination dimensions based on quad edges
  const topWidth = dist(corners.tl, corners.tr);
  const bottomWidth = dist(corners.bl, corners.br);
  const leftHeight = dist(corners.tl, corners.bl);
  const rightHeight = dist(corners.tr, corners.br);

  let dstW = Math.round(Math.max(topWidth, bottomWidth));
  let dstH = Math.round(Math.max(leftHeight, rightHeight));

  // Minimum dimension safeguard
  dstW = Math.max(64, Math.min(4000, dstW));
  dstH = Math.max(64, Math.min(4000, dstH));

  // Compute projective matrix H: dst -> src
  const H = computeProjectiveMatrix(corners, dstW, dstH);
  if (!H) {
    // If matrix singular, fallback to direct crop of bounding box
    return fallbackCrop(img, corners, quality);
  }

  // Create source canvas to extract raw pixel data
  const srcCanvas = document.createElement('canvas');
  srcCanvas.width = srcW;
  srcCanvas.height = srcH;
  const srcCtx = srcCanvas.getContext('2d', { willReadFrequently: true });
  if (!srcCtx) {
    throw new Error('Canvas 2D context unavailable for perspective warp');
  }
  srcCtx.drawImage(img, 0, 0);
  const srcImageData = srcCtx.getImageData(0, 0, srcW, srcH);
  const srcData = srcImageData.data;

  // Create destination canvas & ImageData
  const dstCanvas = document.createElement('canvas');
  dstCanvas.width = dstW;
  dstCanvas.height = dstH;
  const dstCtx = dstCanvas.getContext('2d');
  if (!dstCtx) {
    throw new Error('Canvas 2D context unavailable for destination');
  }
  const dstImageData = dstCtx.createImageData(dstW, dstH);
  const dstData = dstImageData.data;

  const [h0, h1, h2, h3, h4, h5, h6, h7, h8] = H;

  // Pixel mapping loop with bilinear interpolation
  let dstIdx = 0;
  for (let y = 0; y < dstH; y++) {
    for (let x = 0; x < dstW; x++) {
      const denom = h6 * x + h7 * y + h8;
      const u = (h0 * x + h1 * y + h2) / denom;
      const v = (h3 * x + h4 * y + h5) / denom;

      if (u >= 0 && u < srcW - 1 && v >= 0 && v < srcH - 1) {
        const u0 = Math.floor(u);
        const v0 = Math.floor(v);
        const u1 = u0 + 1;
        const v1 = v0 + 1;

        const du = u - u0;
        const dv = v - v0;
        const du1 = 1 - du;
        const dv1 = 1 - dv;

        const idx00 = (v0 * srcW + u0) * 4;
        const idx01 = (v0 * srcW + u1) * 4;
        const idx10 = (v1 * srcW + u0) * 4;
        const idx11 = (v1 * srcW + u1) * 4;

        const r00 = srcData[idx00] ?? 0;
        const r01 = srcData[idx01] ?? 0;
        const r10 = srcData[idx10] ?? 0;
        const r11 = srcData[idx11] ?? 0;

        const g00 = srcData[idx00 + 1] ?? 0;
        const g01 = srcData[idx01 + 1] ?? 0;
        const g10 = srcData[idx10 + 1] ?? 0;
        const g11 = srcData[idx11 + 1] ?? 0;

        const b00 = srcData[idx00 + 2] ?? 0;
        const b01 = srcData[idx01 + 2] ?? 0;
        const b10 = srcData[idx10 + 2] ?? 0;
        const b11 = srcData[idx11 + 2] ?? 0;

        // Bilinear sample for R, G, B, A
        dstData[dstIdx] = Math.round(
          r00 * du1 * dv1 +
          r01 * du * dv1 +
          r10 * du1 * dv +
          r11 * du * dv
        );
        dstData[dstIdx + 1] = Math.round(
          g00 * du1 * dv1 +
          g01 * du * dv1 +
          g10 * du1 * dv +
          g11 * du * dv
        );
        dstData[dstIdx + 2] = Math.round(
          b00 * du1 * dv1 +
          b01 * du * dv1 +
          b10 * du1 * dv +
          b11 * du * dv
        );
        dstData[dstIdx + 3] = 255;
      } else {
        // Out of bounds clamp
        const clampedU = Math.max(0, Math.min(srcW - 1, Math.round(u)));
        const clampedV = Math.max(0, Math.min(srcH - 1, Math.round(v)));
        const srcIdx = (clampedV * srcW + clampedU) * 4;
        dstData[dstIdx] = srcData[srcIdx] ?? 0;
        dstData[dstIdx + 1] = srcData[srcIdx + 1] ?? 0;
        dstData[dstIdx + 2] = srcData[srcIdx + 2] ?? 0;
        dstData[dstIdx + 3] = 255;
      }

      dstIdx += 4;
    }
  }

  dstCtx.putImageData(dstImageData, 0, 0);

  const resultBlob = await new Promise<Blob>((resolve, reject) => {
    dstCanvas.toBlob(
      (b) => {
        if (b && b.size > 0) resolve(b);
        else reject(new Error('Canvas export produced empty blob'));
      },
      'image/jpeg',
      quality
    );
  });

  // Zero-blank screen check
  const val = await validateImageBlob(resultBlob);
  if (!val.valid) {
    throw new Error('Perspective transformation validation failed: invalid image blob output');
  }

  return { blob: resultBlob, width: dstW, height: dstH };
}

/**
 * Fallback bounding-box crop if homography matrix is non-invertible.
 */
async function fallbackCrop(
  img: HTMLImageElement,
  corners: QuadCorners,
  quality: number
): Promise<{ blob: Blob; width: number; height: number }> {
  const minX = Math.max(0, Math.min(corners.tl.x, corners.tr.x, corners.bl.x, corners.br.x));
  const maxX = Math.min(img.naturalWidth, Math.max(corners.tl.x, corners.tr.x, corners.bl.x, corners.br.x));
  const minY = Math.max(0, Math.min(corners.tl.y, corners.tr.y, corners.bl.y, corners.br.y));
  const maxY = Math.min(img.naturalHeight, Math.max(corners.tl.y, corners.tr.y, corners.bl.y, corners.br.y));

  const width = Math.max(64, Math.round(maxX - minX));
  const height = Math.max(64, Math.round(maxY - minY));

  const canvas = document.createElement('canvas');
  canvas.width = width;
  canvas.height = height;
  const ctx = canvas.getContext('2d');
  if (!ctx) throw new Error('Cannot get canvas context for fallback crop');

  ctx.drawImage(img, minX, minY, width, height, 0, 0, width, height);

  const blob = await new Promise<Blob>((resolve, reject) => {
    canvas.toBlob((b) => (b ? resolve(b) : reject(new Error('Fallback crop failed'))), 'image/jpeg', quality);
  });

  return { blob, width, height };
}

/**
 * Rotates an image Blob by 90, 180, or 270 degrees.
 */
export async function rotatePageImage(
  imageBlob: Blob,
  degrees: number,
  quality = 0.92
): Promise<{ blob: Blob; width: number; height: number }> {
  const normalizedDegrees = ((degrees % 360) + 360) % 360;
  if (normalizedDegrees === 0) {
    const val = await validateImageBlob(imageBlob);
    return { blob: imageBlob, width: val.width, height: val.height };
  }

  const img = await loadImageFromBlob(imageBlob);
  const srcW = img.naturalWidth || img.width;
  const srcH = img.naturalHeight || img.height;

  const is90or270 = normalizedDegrees === 90 || normalizedDegrees === 270;
  const dstW = is90or270 ? srcH : srcW;
  const dstH = is90or270 ? srcW : srcH;

  const canvas = document.createElement('canvas');
  canvas.width = dstW;
  canvas.height = dstH;
  const ctx = canvas.getContext('2d');
  if (!ctx) throw new Error('Canvas 2D unavailable for rotation');

  ctx.translate(dstW / 2, dstH / 2);
  ctx.rotate((normalizedDegrees * Math.PI) / 180);
  ctx.drawImage(img, -srcW / 2, -srcH / 2);

  const rotatedBlob = await new Promise<Blob>((resolve, reject) => {
    canvas.toBlob(
      (b) => {
        if (b && b.size > 0) resolve(b);
        else reject(new Error('Canvas rotation export failed'));
      },
      'image/jpeg',
      quality
    );
  });

  const val = await validateImageBlob(rotatedBlob);
  if (!val.valid) {
    throw new Error('Rotated image validation failed');
  }

  return { blob: rotatedBlob, width: dstW, height: dstH };
}

/**
 * Generates a fast, lightweight thumbnail Blob (max 320px bounding box).
 */
export async function createPageThumbnail(
  imageBlob: Blob,
  maxDim = 320,
  quality = 0.8
): Promise<Blob> {
  const img = await loadImageFromBlob(imageBlob);
  const srcW = img.naturalWidth || img.width;
  const srcH = img.naturalHeight || img.height;

  let dstW = srcW;
  let dstH = srcH;

  if (srcW > maxDim || srcH > maxDim) {
    if (srcW > srcH) {
      dstW = maxDim;
      dstH = Math.round((srcH / srcW) * maxDim);
    } else {
      dstH = maxDim;
      dstW = Math.round((srcW / srcH) * maxDim);
    }
  }

  const canvas = document.createElement('canvas');
  canvas.width = dstW;
  canvas.height = dstH;
  const ctx = canvas.getContext('2d');
  if (!ctx) throw new Error('Canvas 2D unavailable for thumbnail');

  ctx.drawImage(img, 0, 0, dstW, dstH);

  return new Promise((resolve, reject) => {
    canvas.toBlob(
      (b) => {
        if (b && b.size > 0) resolve(b);
        else reject(new Error('Thumbnail export failed'));
      },
      'image/jpeg',
      quality
    );
  });
}
