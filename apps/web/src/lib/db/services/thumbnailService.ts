/**
 * Thumbnail generation utility for imported images and scanned pages.
 * Resizes image Blob to ~300px max dimension while maintaining aspect ratio.
 */
export async function generateImageThumbnail(
  imageBlob: Blob,
  maxDimension = 300
): Promise<{ blob: Blob; width: number; height: number } | null> {
  if (typeof window === 'undefined' || typeof document === 'undefined') {
    return null;
  }

  return new Promise((resolve) => {
    try {
      const url = URL.createObjectURL(imageBlob);
      const img = new Image();

      img.onload = () => {
        URL.revokeObjectURL(url);

        let targetWidth = img.naturalWidth || img.width;
        let targetHeight = img.naturalHeight || img.height;

        if (targetWidth === 0 || targetHeight === 0) {
          resolve(null);
          return;
        }

        // Calculate scaled dimensions
        if (targetWidth > targetHeight) {
          if (targetWidth > maxDimension) {
            targetHeight = Math.round((targetHeight * maxDimension) / targetWidth);
            targetWidth = maxDimension;
          }
        } else {
          if (targetHeight > maxDimension) {
            targetWidth = Math.round((targetWidth * maxDimension) / targetHeight);
            targetHeight = maxDimension;
          }
        }

        const canvas = document.createElement('canvas');
        canvas.width = targetWidth;
        canvas.height = targetHeight;

        const ctx = canvas.getContext('2d');
        if (!ctx) {
          resolve(null);
          return;
        }

        // Use high quality image smoothing
        ctx.imageSmoothingEnabled = true;
        ctx.imageSmoothingQuality = 'high';
        ctx.drawImage(img, 0, 0, targetWidth, targetHeight);

        canvas.toBlob(
          (thumbnailBlob) => {
            if (!thumbnailBlob) {
              resolve(null);
              return;
            }
            resolve({
              blob: thumbnailBlob,
              width: targetWidth,
              height: targetHeight,
            });
          },
          'image/jpeg',
          0.85
        );
      };

      img.onerror = () => {
        URL.revokeObjectURL(url);
        resolve(null);
      };

      img.src = url;
    } catch {
      resolve(null);
    }
  });
}
